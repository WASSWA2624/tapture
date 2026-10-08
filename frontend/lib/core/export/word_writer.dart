import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'export_record.dart';
import 'export_request.dart';
import 'ooxml_package.dart';
import 'record_document_text.dart';
import 'xlsx_writer.dart';

/// Editable Office Word output from the same reusable reviewed record snapshot.
abstract final class WordWriter {
  /// Writes a standard DOCX package containing selected values and photo references.
  static Uint8List write(ExportRequest request) {
    final XmlBuilder builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'w:document',
      namespaceUris: <String, String>{'w': _word},
      nest: () {
        builder.element(
          'w:body',
          nest: () {
            for (final String line in RecordDocumentText.lines(
              request,
            ).expand((line) => line.split(RegExp(r'\r?\n')))) {
              builder.element(
                'w:p',
                nest: () {
                  builder.element(
                    'w:r',
                    nest: () {
                      builder.element(
                        'w:t',
                        attributes: <String, String>{'xml:space': 'preserve'},
                        nest: line,
                      );
                    },
                  );
                },
              );
            }
          },
        );
      },
    );
    final Archive archive = Archive();
    void add(String name, String value) {
      final List<int> bytes = utf8.encode(value);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add('[Content_Types].xml', _contentTypes);
    add('_rels/.rels', _relationships);
    add('word/document.xml', builder.buildDocument().toXmlString());
    return ZipEncoder().encodeBytes(archive);
  }

  /// Explicit placeholders across Word text runs, including headers and footers.
  static Set<String> fields(Uint8List source) {
    final OoxmlPackage package = _open(source);
    final Set<String> fields = <String>{};
    for (final String name in _textParts(package)) {
      final XmlDocument document = package.xml(name);
      for (final XmlElement paragraph in document.findAllElements(
        'p',
        namespaceUri: _word,
      )) {
        final String text = paragraph
            .findAllElements('t', namespaceUri: _word)
            .map((node) => node.innerText)
            .join();
        fields.addAll(
          RecordDocumentText.placeholder
              .allMatches(text)
              .map((match) => match.group(1)!),
        );
      }
    }
    return fields;
  }

  /// Retains package parts, paragraphs and formatting while filling one record.
  static Uint8List fill(
    Uint8List source,
    ExportRecord record, {
    bool markedIncomplete = false,
  }) {
    final OoxmlPackage package = _open(source);
    final Map<String, String> values = RecordDocumentText.values(record);
    for (final String name in _textParts(package)) {
      final XmlDocument document = package.xml(name);
      var changed = false;
      for (final XmlElement paragraph in document.findAllElements(
        'p',
        namespaceUri: _word,
      )) {
        final List<XmlElement> runs = paragraph
            .findAllElements('t', namespaceUri: _word)
            .toList();
        final List<int> offsets = <int>[];
        final StringBuffer text = StringBuffer();
        for (final XmlElement run in runs) {
          offsets.add(text.length);
          text.write(run.innerText);
        }
        final List<RegExpMatch> placeholders = RecordDocumentText.placeholder
            .allMatches(text.toString())
            .toList();
        for (final RegExpMatch match in placeholders.reversed) {
          final int first = offsets.lastIndexWhere(
            (offset) => offset <= match.start,
          );
          final int last = offsets.lastIndexWhere(
            (offset) => offset < match.end,
          );
          final String prefix = runs[first].innerText.substring(
            0,
            match.start - offsets[first],
          );
          final String suffix = runs[last].innerText.substring(
            match.end - offsets[last],
          );
          final String value = values[match.group(1)] ?? '';
          _text(runs[first], '$prefix$value${first == last ? suffix : ''}');
          for (var index = first + 1; index <= last; index++) {
            _text(runs[index], index == last ? suffix : '');
          }
          changed = true;
        }
        if (placeholders.isNotEmpty) {
          for (final XmlElement run in runs) {
            _breaks(run);
          }
        }
      }
      if (name == 'word/document.xml' && markedIncomplete) {
        final XmlElement body = document.rootElement
            .findElements('body', namespaceUri: _word)
            .single;
        final XmlBuilder stamp = XmlBuilder();
        final String? prefix = body.name.prefix;
        String qualified(String name) =>
            prefix == null ? name : '$prefix:$name';
        stamp.element(
          qualified('p'),
          namespaceUris: <String?, String?>{prefix: _word},
          nest: () {
            stamp.element(
              qualified('r'),
              nest: () {
                stamp.element(qualified('t'), nest: XlsxWriter.incompleteStamp);
              },
            );
          },
        );
        final XmlElement? section = body
            .findElements('sectPr', namespaceUri: _word)
            .firstOrNull;
        body.children.insert(
          section == null
              ? body.children.length
              : body.children.indexOf(section),
          stamp.buildFragment().children.single.copy(),
        );
        changed = true;
      }
      if (changed) package.replaceXml(name, document);
    }
    return package.encode();
  }
}

OoxmlPackage _open(Uint8List source) {
  final OoxmlPackage package = OoxmlPackage.open(source);
  final XmlElement root = package.xml('word/document.xml').rootElement;
  if (root.name.local != 'document' || root.name.namespaceUri != _word) {
    throw OoxmlPackage.invalid();
  }
  return package;
}

Iterable<String> _textParts(OoxmlPackage package) => package.names.where(
  (name) =>
      name == 'word/document.xml' ||
      RegExp(r'^word/(header|footer)\d+\.xml$').hasMatch(name),
);

void _text(XmlElement node, String value) {
  node.children
    ..clear()
    ..add(XmlText(value));
  node.attributes.removeWhere(
    (attribute) =>
        attribute.name.local == 'space' &&
        (attribute.name.prefix == 'xml' || attribute.name.prefix == null),
  );
  node.attributes.add(XmlAttribute(_spaceName, 'preserve'));
}

void _breaks(XmlElement node) {
  final List<String> lines = node.innerText.split(RegExp(r'\r?\n'));
  if (lines.length < 2) return;
  final XmlElement? parent = node.parentElement;
  if (parent == null) return;
  var index = parent.children.indexOf(node);
  parent.children.remove(node);
  for (var line = 0; line < lines.length; line++) {
    if (line > 0) {
      parent.children.insert(
        index++,
        XmlElement(
          XmlName.parts(
            'br',
            prefix: node.name.prefix,
            namespaceUri: node.name.namespaceUri,
          ),
        ),
      );
    }
    parent.children.insert(
      index++,
      XmlElement(
        XmlName.parts(
          node.name.local,
          prefix: node.name.prefix,
          namespaceUri: node.name.namespaceUri,
        ),
        node.attributes.map((attribute) => attribute.copy()).toList(),
        <XmlNode>[XmlText(lines[line])],
      ),
    );
  }
}

const String _word =
    'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
const String _contentTypes =
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '</Types>';
const String _relationships =
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
    '</Relationships>';

const XmlName _spaceName = XmlName.parts(
  'space',
  prefix: 'xml',
  namespaceUri: 'http://www.w3.org/XML/1998/namespace',
);
