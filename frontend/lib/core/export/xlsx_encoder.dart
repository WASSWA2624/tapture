import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'xlsx_book.dart';
import 'xlsx_cell.dart';
import 'xlsx_column.dart';
import 'xlsx_image.dart';
import 'xlsx_sheet.dart';

part 'xlsx_package_xml.dart';
part 'xlsx_sheet_xml.dart';

/// Turns an [XlsxBook] into the bytes of an `.xlsx` file.
///
/// Pure Dart with no platform access, so it runs on the web, on device and
/// inside the isolate runner (FE-PERF-02). The output carries a bold, frozen,
/// filterable header, typed cells, internal links and PNG pictures — the
/// subset Tapture's exports need, not a general spreadsheet library.
abstract final class XlsxEncoder {
  /// Media type a browser or share sheet is given for the result.
  static const String mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// Encodes [book]. Throws [ArgumentError] when a sheet name is invalid or
  /// repeated, which the isolate runner reports as a validation failure.
  static Uint8List encode(XlsxBook book) {
    _checkNames(book.sheets);
    final _SharedStrings strings = _SharedStrings();
    final Archive archive = Archive();
    int drawings = 0;
    int media = 0;
    final List<int> drawingOfSheet = <int>[];
    for (int index = 0; index < book.sheets.length; index++) {
      final XlsxSheet sheet = book.sheets[index];
      final bool hasImages = sheet.images.isNotEmpty;
      final int drawing = hasImages ? ++drawings : 0;
      drawingOfSheet.add(drawing);
      _addText(
        archive,
        'xl/worksheets/sheet${index + 1}.xml',
        _sheetXml(sheet, strings, selected: index == 0, drawing: drawing > 0),
      );
      if (!hasImages) {
        continue;
      }
      _addText(
        archive,
        'xl/worksheets/_rels/sheet${index + 1}.xml.rels',
        _sheetRelsXml(drawing),
      );
      final int firstMedia = media + 1;
      for (final XlsxImage image in sheet.images) {
        media++;
        archive.addFile(
          ArchiveFile.noCompress(
            'xl/media/image$media.png',
            image.png.length,
            image.png,
          ),
        );
      }
      _addText(
        archive,
        'xl/drawings/drawing$drawing.xml',
        _drawingXml(sheet.images),
      );
      _addText(
        archive,
        'xl/drawings/_rels/drawing$drawing.xml.rels',
        _drawingRelsXml(firstMedia, sheet.images.length),
      );
    }
    _addText(
      archive,
      '[Content_Types].xml',
      _contentTypesXml(book.sheets.length, drawings, hasMedia: media > 0),
    );
    _addText(archive, '_rels/.rels', _rootRelsXml);
    _addText(archive, 'docProps/core.xml', _coreXml(book));
    _addText(archive, 'docProps/app.xml', _appXml(book));
    _addText(archive, 'xl/workbook.xml', _workbookXml(book.sheets));
    _addText(
      archive,
      'xl/_rels/workbook.xml.rels',
      _workbookRelsXml(book.sheets.length),
    );
    _addText(archive, 'xl/styles.xml', _stylesXml(book.dateTimeFormat));
    _addText(archive, 'xl/sharedStrings.xml', strings.toXml());
    final List<int>? zipped = ZipEncoder().encode(
      archive,
      modified: book.createdUtc,
    );
    return Uint8List.fromList(zipped ?? const <int>[]);
  }
}

void _checkNames(List<XlsxSheet> sheets) {
  if (sheets.isEmpty) {
    throw ArgumentError.value(sheets, 'sheets', 'a workbook needs a sheet');
  }
  final Set<String> seen = <String>{};
  for (final XlsxSheet sheet in sheets) {
    if (!XlsxSheet.isValidName(sheet.name)) {
      throw ArgumentError.value(sheet.name, 'name', 'not a valid sheet name');
    }
    if (!seen.add(sheet.name.toLowerCase())) {
      throw ArgumentError.value(sheet.name, 'name', 'sheet name repeats');
    }
  }
}

void _addText(Archive archive, String name, String xml) {
  final List<int> bytes = utf8.encode(xml);
  archive.addFile(ArchiveFile(name, bytes.length, bytes));
}

/// Every distinct string, stored once and referenced by index.
final class _SharedStrings {
  final Map<String, int> _index = <String, int>{};
  final List<String> _ordered = <String>[];
  int _uses = 0;

  int indexOf(String value) {
    _uses++;
    return _index.putIfAbsent(value, () {
      _ordered.add(value);
      return _ordered.length - 1;
    });
  }

  String toXml() {
    final StringBuffer xml = StringBuffer(_xmlHead)
      ..write('<sst xmlns="$_mainNs" count="$_uses" ')
      ..write('uniqueCount="${_ordered.length}">');
    for (final String value in _ordered) {
      final bool preserve = value != value.trim() || value.contains('\n');
      xml.write(
        preserve
            ? '<si><t xml:space="preserve">${_escape(value)}</t></si>'
            : '<si><t>${_escape(value)}</t></si>',
      );
    }
    xml.write('</sst>');
    return xml.toString();
  }
}

/// XML-escapes [value], drops characters XML 1.0 cannot carry, and cuts it
/// to the longest text a cell accepts.
String _escape(String value) {
  final StringBuffer out = StringBuffer();
  int length = 0;
  for (final int rune in value.runes) {
    if (!_isXmlChar(rune)) {
      continue;
    }
    length += rune > _bmpMax ? 2 : 1;
    if (length > _maxCellText) {
      break;
    }
    switch (rune) {
      case _ampersand:
        out.write('&amp;');
      case _lessThan:
        out.write('&lt;');
      case _greaterThan:
        out.write('&gt;');
      case _quote:
        out.write('&quot;');
      default:
        out.writeCharCode(rune);
    }
  }
  return out.toString();
}

bool _isXmlChar(int rune) {
  return rune == _tab ||
      rune == _lineFeed ||
      rune == _carriageReturn ||
      (rune >= _space && rune <= _surrogateStart - 1) ||
      (rune >= _privateUseStart && rune <= _lastBmpChar) ||
      (rune > _bmpMax && rune <= _lastRune);
}

/// A spreadsheet cell holds at most this many UTF-16 code units.
const int _maxCellText = 32767;

const int _tab = 0x09;
const int _lineFeed = 0x0A;
const int _carriageReturn = 0x0D;
const int _space = 0x20;
const int _quote = 0x22;
const int _ampersand = 0x26;
const int _lessThan = 0x3C;
const int _greaterThan = 0x3E;
const int _surrogateStart = 0xD800;
const int _privateUseStart = 0xE000;
const int _lastBmpChar = 0xFFFD;
const int _bmpMax = 0xFFFF;
const int _lastRune = 0x10FFFF;
