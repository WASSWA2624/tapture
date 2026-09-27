import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/bundle/bundle_zip_job.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';

void main() {
  test(
    'a well-formed package is accepted, from bytes and from a file',
    () async {
      final Uint8List bytes = _craft();
      final InspectedBundle fromBytes = _ok(
        await BundleReader.inspect(PickedBytes(bytes, 'site.zip')),
      );
      expect(fromBytes.manifest.projectId, 'p1');
      expect(fromBytes.rowsOf('projects').single['name'], 'Pumps');
      expect(fromBytes.rowsOf('records'), hasLength(1));

      final Directory folder = Directory.systemTemp.createTempSync('tp-read-');
      addTearDown(() => folder.deleteSync(recursive: true));
      final File file = File('${folder.path}/site.zip')
        ..writeAsBytesSync(bytes);
      final InspectedBundle fromFile = _ok(
        await BundleReader.inspect(PickedFile(file, 'site.zip', bytes.length)),
      );
      addTearDown(fromFile.close);
      expect(fromFile.manifest.bundleId, 'bundle-1');
      expect(
        (await fromFile.readEntry('photos/a.jpg') as Success<Uint8List>).value,
        _photo,
      );
    },
  );

  final Map<String, ({Uint8List bytes, BundleRejection reason})> refused =
      <String, ({Uint8List bytes, BundleRejection reason})>{
        'a flipped byte': (
          bytes: _craft(tamper: 'photos/a.jpg'),
          reason: BundleRejection.checksumMismatch,
        ),
        'an entry the manifest does not list': (
          bytes: _craft(
            unlisted: <String, List<int>>{
              'extra.txt': <int>[1],
            },
          ),
          reason: BundleRejection.checksumMismatch,
        ),
        'a path that leaves the package': (
          bytes: _craft(
            unlisted: <String, List<int>>{
              '../evil.txt': <int>[1],
            },
          ),
          reason: BundleRejection.unsafePath,
        ),
        'a newer format version': (
          bytes: _craft(formatVersion: BundleFormat.version + 1),
          reason: BundleRejection.unknownFormatVersion,
        ),
        'no manifest': (
          bytes: _craft(withManifest: false),
          reason: BundleRejection.notAPackage,
        ),
        'a listed entry that is missing': (
          bytes: _craft(drop: 'photos/a.jpg'),
          reason: BundleRejection.missingEntry,
        ),
        'a required table entry that is missing': (
          bytes: _craft(drop: 'media.json'),
          reason: BundleRejection.missingEntry,
        ),
        'a table row without an id': (
          bytes: _craft(
            records: <Map<String, Object?>>[
              <String, Object?>{'project_id': 'p1', 'template_id': 't1'},
            ],
          ),
          reason: BundleRejection.unreadable,
        ),
        'a PNG renamed to .zip': (
          bytes: Uint8List.fromList(<int>[
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
            ...List<int>.filled(64, 0),
          ]),
          reason: BundleRejection.notAPackage,
        ),
      };
  for (final MapEntry<String, ({Uint8List bytes, BundleRejection reason})> case_
      in refused.entries) {
    test('${case_.key} is refused, naming the check', () async {
      final Result<InspectedBundle> result = await BundleReader.inspect(
        PickedBytes(case_.value.bytes, 'site.zip'),
      );

      final Failure failure =
          (result as FailureResult<InspectedBundle>).failure;
      expect(failure, isA<CorruptionFailure>());
      expect(
        failure.message,
        BundleReader.rejectionMessage(case_.value.reason),
      );
      expect(failure.recoveryAction, isNotEmpty);
    });
  }

  test('a package above the ceiling is refused before it is read', () async {
    final Uint8List bytes = _craft();
    final Result<InspectedBundle> result = await BundleReader.inspect(
      PickedBytes(bytes, 'site.zip'),
      maxBytes: bytes.length - 1,
    );

    expect(
      (result as FailureResult<InspectedBundle>).failure.message,
      BundleReader.rejectionMessage(BundleRejection.tooLarge),
    );
  });

  test('every refusal has its own message', () {
    final Set<String> messages = <String>{
      for (final BundleRejection reason in BundleRejection.values)
        BundleReader.rejectionMessage(reason),
    };
    expect(messages, hasLength(BundleRejection.values.length));
  });
}

final Uint8List _photo = Uint8List.fromList(
  List<int>.generate(600, (int i) => (i * 13) % 256),
);

/// A small package built entry by entry, so a test can break one check.
Uint8List _craft({
  int formatVersion = BundleFormat.version,
  String? tamper,
  String? drop,
  bool withManifest = true,
  Map<String, List<int>> unlisted = const <String, List<int>>{},
  List<Map<String, Object?>>? records,
}) {
  List<int> json(Map<String, Object?> value) => utf8.encode(jsonEncode(value));
  final Map<String, List<int>> entries = <String, List<int>>{
    for (final String entry in BundleFormat.tableEntries.keys)
      entry: json(const <String, Object?>{}),
    'project.json': json(<String, Object?>{
      'projects': <Map<String, Object?>>[
        <String, Object?>{'id': 'p1', 'name': 'Pumps', 'folder_name': 'pumps'},
      ],
    }),
    'records.json': json(<String, Object?>{
      'records':
          records ??
          <Map<String, Object?>>[
            <String, Object?>{
              'id': 'r1',
              'project_id': 'p1',
              'template_id': 't1',
            },
          ],
    }),
    'photos/a.jpg': _photo,
  };
  final List<BundleEntry> written = <BundleEntry>[
    for (final MapEntry<String, List<int>> entry in entries.entries)
      BundleEntry(
        path: entry.key,
        byteLength: entry.value.length,
        sha256: crypto.sha256.convert(entry.value).toString(),
      ),
  ];
  final ({List<int> manifest, List<int> checksums}) last = finishBundle(
    BundleManifest(
      formatVersion: formatVersion,
      appVersion: '1.0.0',
      schemaVersion: 20,
      bundleId: 'bundle-1',
      projectId: 'p1',
      projectName: 'Pumps',
      folderName: 'pumps',
      exportedAt: DateTime.utc(2026, 9, 27),
      sourceDeviceId: 'device-a',
      counts: const <String, int>{},
      lineage: const <({String device, DateTime at})>[],
      templates: const <BundleTemplateSummary>[],
      entries: const <BundleEntry>[],
    ),
    written,
    missingFiles: const <String>[],
  );
  final Archive archive = Archive();
  void add(String name, List<int> bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  for (final MapEntry<String, List<int>> entry in entries.entries) {
    if (entry.key == drop) {
      continue;
    }
    final List<int> bytes = List<int>.of(entry.value);
    if (entry.key == tamper) {
      bytes[10] = bytes[10] ^ 0xFF;
    }
    add(entry.key, bytes);
  }
  unlisted.forEach(add);
  add(BundleFormat.checksums, last.checksums);
  if (withManifest) {
    add(BundleFormat.manifest, last.manifest);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

InspectedBundle _ok(Result<InspectedBundle> result) {
  return switch (result) {
    Success<InspectedBundle>(:final InspectedBundle value) => value,
    FailureResult<InspectedBundle>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
