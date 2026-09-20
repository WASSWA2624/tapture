import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export.dart';
import 'package:tapture/core/import/import.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('tapture-workbook-');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  test('a twenty-sheet workbook opens on a worker isolate', () async {
    final File file = _write(
      temp,
      'twenty.xlsx',
      XlsxEncoder.encode(
        XlsxBook(
          createdUtc: _created,
          sheets: <XlsxSheet>[
            for (int index = 1; index <= 20; index++)
              XlsxSheet(
                name: 'S${index.toString().padLeft(2, '0')}',
                columns: const <XlsxColumn>[
                  XlsxColumn('Asset tag'),
                  XlsxColumn('Count'),
                ],
                rows: const <List<XlsxCell>>[
                  <XlsxCell>[XlsxCell.text('EQ-001'), XlsxCell.number(1)],
                ],
              ),
          ],
        ),
      ),
    );

    final WorkbookSnapshot book = _ok(await WorkbookReader.open(file.path));
    expect(book.sheets, hasLength(20));
    expect(book.sheets.first.name, 'S01');
    expect(book.sheets.last.name, 'S20');
    expect(book.sheets.first.header.isSuggestion, isTrue);
    expect(
      book.sheets.first.columns.every(
        (ColumnSuggestion column) => column.isSuggestion,
      ),
      isTrue,
    );
    expect(debugLiveIsolates, 0);
  });

  test('a title block above the header still maps correctly', () async {
    final File file = _write(
      temp,
      'title.xlsx',
      _withMerge(
        XlsxEncoder.encode(
          XlsxBook(
            createdUtc: _created,
            sheets: <XlsxSheet>[
              const XlsxSheet(
                name: 'Register',
                columns: <XlsxColumn>[
                  XlsxColumn('Equipment Register'),
                  XlsxColumn(''),
                  XlsxColumn(''),
                ],
                rows: <List<XlsxCell>>[
                  <XlsxCell>[XlsxCell.empty, XlsxCell.empty, XlsxCell.empty],
                  <XlsxCell>[
                    XlsxCell.text('Asset tag'),
                    XlsxCell.text('Serial'),
                    XlsxCell.text('Status'),
                  ],
                  <XlsxCell>[
                    XlsxCell.text('A-1'),
                    XlsxCell.number(100),
                    XlsxCell.text('Active'),
                  ],
                ],
              ),
            ],
          ),
        ),
        'A1:C1',
      ),
    );

    final WorkbookSnapshot book = _ok(await WorkbookReader.open(file.path));
    final WorkbookSheet sheet = book.sheets.single;
    expect(sheet.name, 'Register');
    expect(sheet.header.rowNumber, 3);
    expect(sheet.header.labels, <String>['Asset tag', 'Serial', 'Status']);
    expect(sheet.header.isSuggestion, isTrue);
    expect(sheet.mergedCells, contains('A1:C1'));
    expect(sheet.usedRange, isNotEmpty);
    expect(
      sheet.columns.every((ColumnSuggestion column) => column.isSuggestion),
      isTrue,
    );
  });

  test('a csv with a title block still maps the header', () async {
    final File file = File('${temp.path}/register.csv');
    file.writeAsStringSync(
      'Equipment Register\n\nAsset tag,Serial,Status\nA-1,100,Active\n',
    );
    final WorkbookSnapshot book = _ok(await WorkbookReader.open(file.path));
    expect(book.sheets, hasLength(1));
    expect(book.sheets.single.header.rowNumber, 3);
    expect(book.sheets.single.header.labels, <String>[
      'Asset tag',
      'Serial',
      'Status',
    ]);
    expect(book.sheets.single.header.isSuggestion, isTrue);
  });

  test('a password-protected workbook is refused by name', () async {
    final File file = _write(temp, 'locked.xlsx', _passwordProtected());
    final Result<WorkbookSnapshot> result = await WorkbookReader.open(
      file.path,
    );
    expect(
      result,
      isA<FailureResult<WorkbookSnapshot>>().having(
        (FailureResult<WorkbookSnapshot> failure) => failure.failure.message,
        'message',
        Copy.workbookPassword,
      ),
    );
  });

  test('a corrupt workbook is refused by name', () async {
    final File file = _write(
      temp,
      'broken.xlsx',
      _corruptWorkbook(
        XlsxEncoder.encode(
          XlsxBook(
            createdUtc: _created,
            sheets: const <XlsxSheet>[
              XlsxSheet(
                name: 'Register',
                columns: <XlsxColumn>[XlsxColumn('Asset tag')],
                rows: <List<XlsxCell>>[
                  <XlsxCell>[XlsxCell.text('EQ-001')],
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final Result<WorkbookSnapshot> result = await WorkbookReader.open(
      file.path,
    );
    expect(
      result,
      isA<FailureResult<WorkbookSnapshot>>().having(
        (FailureResult<WorkbookSnapshot> failure) => failure.failure.message,
        'message',
        Copy.workbookCorrupt,
      ),
    );
  });
}

File _write(Directory dir, String name, List<int> bytes) {
  final File file = File('${dir.path}/$name');
  file.writeAsBytesSync(bytes);
  return file;
}

Uint8List _passwordProtected() {
  final Archive archive = Archive()
    ..addFile(ArchiveFile('EncryptionInfo', 4, <int>[1, 2, 3, 4]))
    ..addFile(ArchiveFile('EncryptedPackage', 4, <int>[5, 6, 7, 8]));
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

Uint8List _corruptWorkbook(Uint8List bytes) {
  final Archive archive = ZipDecoder().decodeBytes(bytes);
  final Archive next = Archive();
  for (final ArchiveFile file in archive.files) {
    final String name = file.name.replaceAll(r'\', '/');
    if (name == 'xl/workbook.xml') {
      final List<int> broken = utf8.encode('<<<');
      next.addFile(ArchiveFile(file.name, broken.length, broken));
    } else {
      next.addFile(file);
    }
  }
  return Uint8List.fromList(ZipEncoder().encode(next)!);
}

Uint8List _withMerge(Uint8List bytes, String ref) {
  final Archive archive = ZipDecoder().decodeBytes(bytes);
  final Archive next = Archive();
  for (final ArchiveFile file in archive.files) {
    final String name = file.name.replaceAll(r'\', '/');
    if (name != 'xl/worksheets/sheet1.xml') {
      next.addFile(file);
      continue;
    }
    final Object? raw = file.content;
    final String xml = raw is List<int> ? utf8.decode(raw) : '';
    final String patched = xml.replaceFirst(
      '</worksheet>',
      '<mergeCells count="1"><mergeCell ref="$ref"/></mergeCells></worksheet>',
    );
    final List<int> out = utf8.encode(patched);
    next.addFile(ArchiveFile(file.name, out.length, out));
  }
  return Uint8List.fromList(ZipEncoder().encode(next)!);
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

final DateTime _created = DateTime.utc(2026, 9, 20, 8);
