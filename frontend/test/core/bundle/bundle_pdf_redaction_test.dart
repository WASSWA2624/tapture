import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/bundle/bundle_payload_scanner.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/ids/ids.dart';
import 'package:tapture/core/time/clock.dart';

import '../../support/bundle_fixture.dart';

void main() {
  final BundleRedaction redaction = BundleRedaction.parse(
    File('tool/secret_patterns.yaml').readAsStringSync(),
  );
  final Uint8List pdf = File(
    'test/fixtures/bundle/pdf_dictionary_names.pdf',
  ).readAsBytesSync();
  final String blob = List<String>.filled(48, 'A').join();
  final String base64 = '$blob/$blob';
  final String names = List<String>.filled(12, '/DictionaryName').join();
  final List<String> credentials = <String>[
    'sk-${List<String>.filled(24, 'x').join()}',
    'Bearer ${List<String>.filled(24, 'x').join()}',
    '-----BEGIN PRIVATE KEY-----',
    'postgres://operator:password@localhost',
  ];

  void scan(List<int> bytes, {int chunkSize = 7}) {
    final BundlePayloadScanner scanner = redaction.payloadScanner();
    for (int offset = 0; offset < bytes.length; offset += chunkSize) {
      scanner.add(
        bytes.sublist(offset, (offset + chunkSize).clamp(offset, bytes.length)),
      );
    }
    scanner.finish();
  }

  List<String> locations(String value) => <String>[
    '%PDF-1.7\n<</Value($value)>>',
    '%PDF-1.7\n<</Value(outer \\( ($value) \\) tail)>>',
    '%PDF-1.7\n<<% $value\n/Value 1>>',
    '%PDF-1.7\n<</Length ${value.length}>>stream\n$value\nendstream\n',
    '%PDF-1.7\n<</Length ${value.length}>>stream\r\n$value\r\nendstream\n',
  ];

  test(
    'the smoke PDF proves the strict byte false positive and preserves token boundaries across chunks',
    () {
      expect(pdf, hasLength(21860));
      expect(
        () => redaction.assertCleanBytes(pdf),
        throwsA(isA<ValidationFailure>()),
      );
      for (final int chunkSize in <int>[1, 7, 64, 65536]) {
        scan(pdf, chunkSize: chunkSize);
      }
      redaction.assertCleanPayload(pdf);
    },
  );

  test('base64-shaped dictionary names remain strict outside a PDF', () {
    expect(
      () => scan(latin1.encode('<<$names>>')),
      throwsA(isA<ValidationFailure>()),
    );
    scan(latin1.encode('%PDF-1.7\n<<$names>>'));
    scan(latin1.encode('%PDF-1.7\n<<$names<</Nested 1>>$names>>'));
  });

  test(
    'PDF strings comments and direct-length streams retain long base64 checks',
    () {
      for (final String location in locations(base64)) {
        for (final int chunkSize in <int>[1, 7, 65536]) {
          expect(
            () => scan(latin1.encode(location), chunkSize: chunkSize),
            throwsA(isA<ValidationFailure>()),
          );
        }
      }
      expect(
        () => scan(
          latin1.encode(
            '%PDF-1.7\n<</Value<${List<String>.filled(90, 'A').join()}>>>',
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => scan(
          latin1.encode(
            '%PDF-1.7\n<</${List<String>.filled(90, 'A').join()} 1>>',
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );

  test('every explicit credential pattern still checks original PDF bytes', () {
    for (final String credential in credentials) {
      for (final String location in <String>[
        ...locations(credential),
        '%PDF-1.7\n<</Value/$credential>>',
      ]) {
        expect(
          () => scan(latin1.encode(location), chunkSize: 1),
          throwsA(isA<ValidationFailure>()),
        );
      }
    }
  });

  test(
    'uncertain stream lengths and malformed endings retain strict byte checks',
    () {
      for (final String length in <String>[
        '',
        '/Length 2 0 R',
        '/Length -1',
        '/Length(one)',
      ]) {
        expect(
          () => scan(
            latin1.encode(
              '%PDF-1.7\n<<$length>>stream\n<<$names>>\nendstream\n',
            ),
          ),
          throwsA(isA<ValidationFailure>()),
        );
      }
      expect(
        () => scan(
          latin1.encode(
            '%PDF-1.7\n<</Length 1>>stream\nx incorrect <<$names>>',
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      // A marker inside stream data must not re-enable PDF syntax early.
      final String content = 'endstream\n<<$names>>';
      expect(
        () => scan(
          latin1.encode(
            '%PDF-1.7\n<</Length ${content.length}>>stream\n$content\nendstream\n',
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );

  test(
    'small non-PDF payloads and fragmented headers retain the canonical scan',
    () {
      for (int size = 0; size < 5; size++) {
        scan(List<int>.filled(size, 65), chunkSize: 1);
      }
      expect(
        () => scan(latin1.encode(base64), chunkSize: 1),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );

  for (final bool browser in <bool>[false, true]) {
    for (final bool nested in <bool>[false, true]) {
      test(
        '${browser ? 'browser' : 'native'} project package preserves the real PDF ${nested ? 'inside a nested archive' : 'attachment'} byte for byte',
        () async {
          final BundleFixture fixture = await seedProjectForBundle(records: 1);
          addTearDown(() async {
            await fixture.db.close();
            fixture.root.parent.deleteSync(recursive: true);
          });
          final String path = nested
              ? 'documents/attached.zip'
              : 'documents/attached.pdf';
          final Uint8List original = nested ? _archivePdf(pdf) : pdf;
          final File source = await _attach(fixture, path, original);
          final BundleOutput output =
              (await _writer(fixture, browser: browser).write(
                projectId: fixture.projectId,
                cancel: CancellationToken(),
              )).getOrThrow();
          final PickedDocument picked = output is InMemoryBundle
              ? PickedBytes(output.bytes, 'project.zip')
              : PickedFile(
                  File(
                    '${fixture.root.path}/${(output as StoredBundle).relativePath}',
                  ),
                  'project.zip',
                  output.byteLength,
                );
          final InspectedBundle opened = (await BundleReader.inspect(
            picked,
          )).getOrThrow();
          try {
            final Uint8List restored = (await opened.readEntry(
              path,
            )).getOrThrow();
            expect(restored, original);
            expect(sha256.convert(restored), sha256.convert(original));
            if (nested) {
              expect(
                ZipDecoder()
                    .decodeBytes(restored)
                    .findFile('original.pdf')!
                    .content,
                pdf,
              );
            }
            expect(
              opened.rowsOf('attachments').single['sha256'],
              sha256.convert(original).toString(),
            );
            expect(source.readAsBytesSync(), original);
            expect(opened.rowsOf('records'), hasLength(1));
          } finally {
            await opened.close();
          }
        },
      );
    }

    test(
      '${browser ? 'browser' : 'native'} project package refuses credentials in the PDF and leaves its original file intact',
      () async {
        final BundleFixture fixture = await seedProjectForBundle(records: 1);
        addTearDown(() async {
          await fixture.db.close();
          fixture.root.parent.deleteSync(recursive: true);
        });
        const String path = 'documents/attached.pdf';
        for (final String value in <String>[credentials.first, base64]) {
          final Uint8List original = Uint8List.fromList(<int>[
            ...pdf,
            ...latin1.encode('\n% $value\n'),
          ]);
          final File source = await _attach(fixture, path, original);
          final Result<BundleOutput> result = await _writer(
            fixture,
            browser: browser,
          ).write(projectId: fixture.projectId, cancel: CancellationToken());
          expect(
            (result as FailureResult<BundleOutput>).failure,
            isA<ValidationFailure>(),
          );
          expect(source.readAsBytesSync(), original);
          final Directory exports = Directory(
            '${fixture.root.path}/projects/${fixture.folderName}/exports',
          );
          expect(
            exports.existsSync()
                ? exports.listSync(recursive: true).whereType<File>()
                : <File>[],
            isEmpty,
          );
        }
      },
    );
  }
}

Uint8List _archivePdf(Uint8List pdf) => Uint8List.fromList(
  ZipEncoder().encode(
    Archive()..addFile(ArchiveFile('original.pdf', pdf.length, pdf)),
  )!,
);

Future<File> _attach(
  BundleFixture fixture,
  String path,
  Uint8List bytes,
) async {
  final File source =
      File('${fixture.root.path}/projects/${fixture.folderName}/$path')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
  await fixture.db.customStatement('DELETE FROM attachments');
  await insertRow(fixture.db, 'attachments', <String, Object?>{
    'id': 'document-fixture',
    'project_id': fixture.projectId,
    'relative_path': path,
    'mime_type': path.endsWith('.pdf') ? 'application/pdf' : 'application/zip',
    'file_size': bytes.length,
    'sha256': sha256.convert(bytes).toString(),
    'kind': 'document',
    'page_count': path.endsWith('.pdf') ? 13 : null,
  });
  return source;
}

BundleWriter _writer(BundleFixture fixture, {required bool browser}) {
  final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 7));
  return BundleWriter(
    db: fixture.db,
    storageRoot: fixture.storageRoot,
    files: FileReader(storageRoot: fixture.storageRoot),
    clock: clock,
    ids: UuidV7Service.sequence(clock),
    deviceId: 'fixture',
    device: () async => const DeviceDescriptor.fake(),
    inBrowser: browser,
  );
}
