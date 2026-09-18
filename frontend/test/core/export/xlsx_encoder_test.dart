import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export.dart';

void main() {
  final DateTime created = DateTime.utc(2026, 9, 18, 7, 2, 31);

  XlsxBook book({List<XlsxSheet>? sheets}) {
    return XlsxBook(
      createdUtc: created,
      subject: 'Feedback export',
      sheets:
          sheets ??
          <XlsxSheet>[
            XlsxSheet(
              name: 'Feedback',
              freezeHeader: true,
              autoFilter: true,
              columns: const <XlsxColumn>[
                XlsxColumn('Feedback ID'),
                XlsxColumn('Submitted At', width: 22),
                XlsxColumn('Feedback', width: 60, wrap: true),
                XlsxColumn('Text Scale'),
                XlsxColumn('Screenshot'),
              ],
              rows: <List<XlsxCell>>[
                <XlsxCell>[
                  const XlsxCell.text('FBK0000001'),
                  XlsxCell.dateTime(DateTime(2026, 9, 18, 10, 2, 31)),
                  const XlsxCell.text('Slow <list> & "grid"'),
                  const XlsxCell.number(1.5),
                  const XlsxCell.link(
                    'View',
                    linkSheet: 'Screenshots',
                    linkCell: 'C2',
                  ),
                ],
                <XlsxCell>[
                  const XlsxCell.text('FBK0000002'),
                  XlsxCell.empty,
                  const XlsxCell.text('Slow <list> & "grid"'),
                ],
              ],
            ),
            XlsxSheet(
              name: 'Screenshots',
              columns: const <XlsxColumn>[XlsxColumn('Feedback ID')],
              rows: const <List<XlsxCell>>[
                <XlsxCell>[XlsxCell.text('FBK0000001')],
              ],
              images: <XlsxImage>[
                XlsxImage(row: 1, column: 2, png: _png, width: 4, height: 2),
              ],
              rowHeights: const <int, double>{1: 30},
            ),
          ],
    );
  }

  Archive open(Uint8List bytes) => ZipDecoder().decodeBytes(bytes);

  String part(Archive archive, String name) {
    final ArchiveFile? file = archive.findFile(name);
    expect(file, isNotNull, reason: '$name is missing');
    return utf8.decode(file!.content as List<int>);
  }

  test('the package holds every part a spreadsheet needs', () {
    final Archive archive = open(XlsxEncoder.encode(book()));
    final Set<String> names = archive.files
        .map((ArchiveFile file) => file.name)
        .toSet();

    expect(
      names,
      containsAll(<String>[
        '[Content_Types].xml',
        '_rels/.rels',
        'docProps/core.xml',
        'docProps/app.xml',
        'xl/workbook.xml',
        'xl/_rels/workbook.xml.rels',
        'xl/styles.xml',
        'xl/sharedStrings.xml',
        'xl/worksheets/sheet1.xml',
        'xl/worksheets/sheet2.xml',
        'xl/worksheets/_rels/sheet2.xml.rels',
        'xl/drawings/drawing1.xml',
        'xl/drawings/_rels/drawing1.xml.rels',
        'xl/media/image1.png',
      ]),
    );
    expect(part(archive, 'xl/workbook.xml'), contains('name="Screenshots"'));
    expect(part(archive, 'docProps/core.xml'), contains('2026-09-18T07:02:31Z'));
  });

  test('the header is bold, frozen and filterable', () {
    final String sheet = part(
      open(XlsxEncoder.encode(book())),
      'xl/worksheets/sheet1.xml',
    );

    expect(sheet, contains('state="frozen"'));
    expect(sheet, contains('<autoFilter ref="A1:E3"/>'));
    expect(sheet, contains('<c r="A1" s="4" t="s">'));
    expect(sheet, contains('<c r="C1" s="5" t="s">'));
    expect(sheet, contains('width="60"'));
  });

  test('cells keep their types and text is stored once, escaped', () {
    final Archive archive = open(XlsxEncoder.encode(book()));
    final String sheet = part(archive, 'xl/worksheets/sheet1.xml');
    final String strings = part(archive, 'xl/sharedStrings.xml');

    // 18 September 2026 10:02:31 is serial 46283 plus the time of day.
    expect(sheet, contains('<c r="B2" s="2"><v>46283.41841435</v></c>'));
    expect(sheet, contains('<c r="D2" s="1"><v>1.5</v></c>'));
    expect(sheet, isNot(contains('r="B3"')));
    expect(strings, contains('Slow &lt;list&gt; &amp; &quot;grid&quot;'));
    expect(
      'Slow &lt;list&gt;'.allMatches(strings).length,
      1,
      reason: 'a repeated value is one shared string',
    );
  });

  test('a link cell jumps to the named sheet and cell', () {
    final String sheet = part(
      open(XlsxEncoder.encode(book())),
      'xl/worksheets/sheet1.xml',
    );

    expect(sheet, contains('<c r="E2" s="6" t="s">'));
    expect(sheet, contains('location="\'Screenshots\'!C2"'));
  });

  test('a picture is anchored at its cell at its size', () {
    final Archive archive = open(XlsxEncoder.encode(book()));
    final String drawing = part(archive, 'xl/drawings/drawing1.xml');
    final String sheet = part(archive, 'xl/worksheets/sheet2.xml');

    expect(drawing, contains('<xdr:col>2</xdr:col>'));
    expect(drawing, contains('<xdr:row>1</xdr:row>'));
    expect(drawing, contains('cx="38100" cy="19050"'));
    expect(sheet, contains('<drawing r:id="rId1"/>'));
    expect(sheet, contains('<row r="2" ht="30" customHeight="1">'));
    expect(archive.findFile('xl/media/image1.png')!.content, _png);
  });

  test('characters XML cannot carry are dropped rather than breaking it', () {
    final Archive archive = open(
      XlsxEncoder.encode(
        book(
          sheets: <XlsxSheet>[
            const XlsxSheet(
              name: 'Feedback',
              columns: <XlsxColumn>[XlsxColumn('Feedback')],
              rows: <List<XlsxCell>>[
                <XlsxCell>[XlsxCell.text('bell and tab\tkept')],
              ],
            ),
          ],
        ),
      ),
    );

    expect(
      part(archive, 'xl/sharedStrings.xml'),
      contains('<t>bell and tab\tkept</t>'),
    );
  });

  test('the same book encodes to the same bytes', () {
    expect(XlsxEncoder.encode(book()), XlsxEncoder.encode(book()));
  });

  test('an invalid or repeated sheet name is refused', () {
    expect(
      () => XlsxEncoder.encode(
        book(
          sheets: const <XlsxSheet>[
            XlsxSheet(name: 'a/b', columns: <XlsxColumn>[], rows: []),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => XlsxEncoder.encode(
        book(
          sheets: const <XlsxSheet>[
            XlsxSheet(name: 'Same', columns: <XlsxColumn>[], rows: []),
            XlsxSheet(name: 'same', columns: <XlsxColumn>[], rows: []),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('column letters run past Z the way a spreadsheet counts', () {
    expect(XlsxSheet.columnName(0), 'A');
    expect(XlsxSheet.columnName(25), 'Z');
    expect(XlsxSheet.columnName(26), 'AA');
    expect(XlsxSheet.columnName(39), 'AN');
    expect(XlsxSheet.columnName(701), 'ZZ');
    expect(XlsxSheet.columnName(702), 'AAA');
    expect(XlsxSheet.cellName(0, 0), 'A1');
  });

  test('a PNG header gives its size, and fitting never enlarges it', () {
    expect(XlsxImage.pngSize(_png), (width: 4, height: 2));
    expect(XlsxImage.pngSize(Uint8List.fromList(<int>[1, 2, 3])), isNull);
    expect(XlsxImage.fitWithin(_png, 2), (width: 2, height: 1));
    expect(XlsxImage.fitWithin(_png, 100), (width: 4, height: 2));
  });
}

/// A PNG signature and IHDR declaring a 4 by 2 image. Enough for the
/// header reader; the encoder stores the bytes as they are.
final Uint8List _png = Uint8List.fromList(<int>[
  137, 80, 78, 71, 13, 10, 26, 10, //
  0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 4, 0, 0, 0, 2, //
  8, 6, 0, 0, 0, 0, 0, 0, 0,
]);
