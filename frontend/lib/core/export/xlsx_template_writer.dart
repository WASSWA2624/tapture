import 'dart:typed_data';

import 'package:xml/xml.dart';

import 'export_output_template.dart';
import 'export_record.dart';
import 'ooxml_package.dart';
import 'record_document_text.dart';
import 'xlsx_writer.dart';

/// Updates confirmed original workbook cells while retaining its Office package.
abstract final class XlsxTemplateWriter {
  /// Only mapped cells change. Formula targets and duplicate matches are refused.
  static Uint8List fill({
    required Uint8List source,
    required ExportOutputTemplate template,
    required List<ExportRecord> records,
    bool markedIncomplete = false,
  }) {
    final OoxmlPackage package = OoxmlPackage.open(source);
    final XmlDocument workbook = package.xml('xl/workbook.xml');
    final XmlElement? sheet = workbook
        .findAllElements('sheet', namespace: '*')
        .where((node) => node.getAttribute('name') == template.sheetName)
        .firstOrNull;
    if (sheet == null || template.headerRow < 1 || template.columns.isEmpty) {
      throw OoxmlPackage.invalid();
    }
    final String? id = sheet.getAttribute('id', namespace: _relationships);
    final XmlDocument relationships = package.xml('xl/_rels/workbook.xml.rels');
    final XmlElement? link = relationships
        .findAllElements('Relationship', namespace: '*')
        .where((node) => node.getAttribute('Id') == id)
        .firstOrNull;
    final String? target = link?.getAttribute('Target');
    if (target == null || link?.getAttribute('TargetMode') == 'External') {
      throw OoxmlPackage.invalid();
    }
    final String path = Uri.parse(
      'xl/workbook.xml',
    ).resolve(target).path.replaceFirst(RegExp(r'^/'), '');
    final XmlDocument document = package.xml(path);
    final XmlElement root = document.rootElement;
    final XmlElement? grid = root
        .findElements('sheetData', namespace: root.name.namespaceUri)
        .firstOrNull;
    if (root.name.local != 'worksheet' || grid == null) {
      throw OoxmlPackage.invalid();
    }
    final Map<int, XmlElement> rows = <int, XmlElement>{
      for (final XmlElement row in grid.childElements)
        if (int.tryParse(row.getAttribute('r') ?? '') case final int number)
          number: row,
    };
    final Set<int> assigned = <int>{};
    for (var index = 0; index < records.length; index++) {
      final ExportRecord record = records[index];
      final int? number = template.rows.isEmpty
          ? template.headerRow + index + 1
          : template.rows[record.templateRowId];
      // Unmatched items are described by the accompanying output summary.
      // No tentative group is forced into somebody else's checklist row.
      if (number == null) continue;
      if (number <= template.headerRow ||
          number > _maxRow ||
          !assigned.add(number)) {
        throw OoxmlPackage.invalid();
      }
      final XmlElement row = rows.putIfAbsent(number, () {
        final XmlElement added = XmlElement(
          XmlName('row', root.name.prefix),
          <XmlAttribute>[XmlAttribute(XmlName('r'), '$number')],
        );
        final XmlElement? next = grid.childElements
            .where(
              (node) =>
                  (int.tryParse(node.getAttribute('r') ?? '') ?? 0) > number,
            )
            .firstOrNull;
        grid.children.insert(
          next == null ? grid.children.length : grid.children.indexOf(next),
          added,
        );
        return added;
      });
      final Map<String, String> values = RecordDocumentText.values(record);
      final Map<String, Object?> typed = RecordDocumentText.typedValues(record);
      for (final MapEntry<String, String> field in template.columns.entries) {
        final String column = field.value.toUpperCase();
        if (!_column.hasMatch(column) || _columnNumber(column) > _maxColumn) {
          throw OoxmlPackage.invalid();
        }
        final String reference = '$column$number';
        XmlElement? cell = row.childElements
            .where(
              (node) =>
                  node.name.local == 'c' && node.getAttribute('r') == reference,
            )
            .firstOrNull;
        if (cell == null) {
          cell = XmlElement(XmlName('c', root.name.prefix), <XmlAttribute>[
            XmlAttribute(XmlName('r'), reference),
          ]);
          final XmlElement? next = row.childElements
              .where(
                (node) =>
                    _columnNumber(
                      (node.getAttribute('r') ?? '').replaceAll(
                        RegExp(r'\d'),
                        '',
                      ),
                    ) >
                    _columnNumber(column),
              )
              .firstOrNull;
          row.children.insert(
            next == null ? row.children.length : row.children.indexOf(next),
            cell,
          );
        }
        if (cell.childElements.any((node) => node.name.local == 'f')) {
          throw OoxmlPackage.invalid();
        }
        final Object? value = typed[field.key];
        cell.setAttribute('t', value is num ? 'n' : 'inlineStr');
        cell.children.removeWhere(
          (node) =>
              node is XmlElement &&
              const <String>{'v', 'is'}.contains(node.name.local),
        );
        cell.children.insert(
          0,
          value is num
              ? XmlElement(
                  XmlName('v', root.name.prefix),
                  const <XmlAttribute>[],
                  <XmlNode>[XmlText(value.toString())],
                )
              : XmlElement(
                  XmlName('is', root.name.prefix),
                  const <XmlAttribute>[],
                  <XmlNode>[
                    XmlElement(
                      XmlName('t', root.name.prefix),
                      <XmlAttribute>[
                        XmlAttribute(XmlName('space', 'xml'), 'preserve'),
                      ],
                      <XmlNode>[XmlText(values[field.key] ?? '')],
                    ),
                  ],
                ),
        );
      }
    }
    if (markedIncomplete) {
      final int number =
          rows.keys.fold(
            template.headerRow,
            (max, value) => value > max ? value : max,
          ) +
          1;
      if (number > _maxRow) throw OoxmlPackage.invalid();
      grid.children.add(
        XmlElement(
          XmlName('row', root.name.prefix),
          <XmlAttribute>[XmlAttribute(XmlName('r'), '$number')],
          <XmlNode>[
            XmlElement(
              XmlName('c', root.name.prefix),
              <XmlAttribute>[
                XmlAttribute(XmlName('r'), 'A$number'),
                XmlAttribute(XmlName('t'), 'inlineStr'),
              ],
              <XmlNode>[
                XmlElement(
                  XmlName('is', root.name.prefix),
                  const <XmlAttribute>[],
                  <XmlNode>[
                    XmlElement(
                      XmlName('t', root.name.prefix),
                      const <XmlAttribute>[],
                      <XmlNode>[XmlText(XlsxWriter.incompleteStamp)],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      assigned.add(number);
    }
    // A stale dimension must not hide appended records in spreadsheet readers.
    final XmlElement? dimension = root
        .findElements('dimension', namespace: root.name.namespaceUri)
        .firstOrNull;
    if (dimension != null && assigned.isNotEmpty) {
      final String original = dimension.getAttribute('ref') ?? 'A1';
      final String end = original.split(':').last;
      final int bottom = int.tryParse(end.replaceAll(RegExp(r'\D'), '')) ?? 1;
      final int right = _columnNumber(end.replaceAll(RegExp(r'\d'), ''));
      final int maxRow = assigned.fold(
        bottom,
        (max, value) => value > max ? value : max,
      );
      final int maxColumn = template.columns.values.fold(
        right,
        (max, value) => _columnNumber(value.toUpperCase()) > max
            ? _columnNumber(value.toUpperCase())
            : max,
      );
      dimension.setAttribute(
        'ref',
        '${original.split(':').first}:${_columnName(maxColumn)}$maxRow',
      );
    }
    package.replaceXml(path, document);
    return package.encode();
  }
}

int _columnNumber(String letters) =>
    letters.codeUnits.fold(0, (value, rune) => value * 26 + rune - 64);

String _columnName(int number) {
  var value = number;
  var result = '';
  while (value > 0) {
    value--;
    result = '${String.fromCharCode(65 + value % 26)}$result';
    value ~/= 26;
  }
  return result;
}

const int _maxRow = 1048576;
const int _maxColumn = 16384;
const String _relationships =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
final RegExp _column = RegExp(r'^[A-Z]{1,3}$');
