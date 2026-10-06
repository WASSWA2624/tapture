import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show ZLibDecoder;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';

/// A small PDF reader written for tests, independent of the rendering
/// library (it never imports `package:pdf`), so a generated report is
/// checked by code that did not write it (task 090).
///
/// It follows `startxref` to the cross-reference stream, checks that every
/// in-use offset points at its `n 0 obj` header, walks the page tree from
/// the catalogue, inflates each page's content streams and reads their text
/// back as lines, and lists every image XObject with its size. Anything it
/// cannot reconcile is named in [problems] rather than thrown, so one test
/// can report every fault.
final class PdfInspector {
  /// Reads [bytes].
  PdfInspector(this.bytes) : _text = latin1.decode(bytes) {
    _read();
  }

  /// The file as written.
  final Uint8List bytes;

  final String _text;

  /// Structural faults found, empty for a sound file.
  final List<String> problems = <String>[];

  /// Object number to byte offset, from the cross-reference stream.
  final Map<int, int> offsets = <int, int>{};

  /// `/Count` of the root page tree.
  int declaredPages = 0;

  /// Leaf page object numbers in document order.
  final List<int> pages = <int>[];

  /// Each page's text, one entry per printed line, top to bottom.
  final List<List<String>> pageLines = <List<String>>[];

  /// Every image XObject's pixel size.
  final List<({int width, int height})> images = <({int width, int height})>[];

  /// The version header, such as `%PDF-1.5`.
  String get header => _text.substring(0, _text.indexOf('\n')).trim();

  /// Whether nothing is wrong with the structure.
  bool get isSound => problems.isEmpty;

  /// Every page's lines, each page headed `--- page n ---`.
  String get transcript => <String>[
    for (int index = 0; index < pageLines.length; index++) ...<String>[
      '--- page ${index + 1} ---',
      ...pageLines[index],
    ],
  ].join('\n');

  void _read() {
    if (!_text.startsWith('%PDF-')) {
      problems.add('no %PDF- header');
      return;
    }
    final int marker = _text.lastIndexOf('startxref');
    if (marker < 0) {
      problems.add('no startxref');
      return;
    }
    final Match? start = RegExp(
      r'startxref\s+(\d+)',
    ).matchAsPrefix(_text, marker);
    if (start == null) {
      problems.add('startxref has no offset');
      return;
    }
    final int xrefOffset = int.parse(start.group(1)!);
    final String? trailer = _readXref(xrefOffset);
    if (trailer == null) {
      return;
    }
    for (final MapEntry<int, int> entry in offsets.entries) {
      if (!_text.startsWith('${entry.key} 0 obj', entry.value)) {
        problems.add('object ${entry.key} is not at offset ${entry.value}');
      }
    }
    final int? root = _ref(trailer, 'Root');
    final String? catalog = root == null ? null : _object(root);
    final int? tree = catalog == null ? null : _ref(catalog, 'Pages');
    final String? pagesNode = tree == null ? null : _object(tree);
    if (pagesNode == null) {
      problems.add('no page tree');
      return;
    }
    declaredPages = int.parse(
      RegExp(r'/Count\s+(\d+)').firstMatch(pagesNode)?.group(1) ?? '0',
    );
    _walk(tree!);
    if (declaredPages != pages.length) {
      problems.add('/Count $declaredPages but ${pages.length} page leaves');
    }
    for (final int page in pages) {
      pageLines.add(_lines(_object(page) ?? ''));
    }
    for (final int id in offsets.keys) {
      final String body = _object(id) ?? '';
      if (RegExp(r'/Subtype\s*/Image').hasMatch(body)) {
        images.add((
          width: int.parse(
            RegExp(r'/Width\s+(\d+)').firstMatch(body)?.group(1) ?? '0',
          ),
          height: int.parse(
            RegExp(r'/Height\s+(\d+)').firstMatch(body)?.group(1) ?? '0',
          ),
        ));
      }
    }
  }

  /// Fills [offsets] from the cross-reference stream at [offset] and
  /// returns its dictionary, the trailer.
  String? _readXref(int offset) {
    final Match? head = RegExp(r'(\d+) 0 obj').matchAsPrefix(_text, offset);
    if (head == null) {
      problems.add('startxref does not point at an object');
      return null;
    }
    final String dictionary = _dictionary(offset);
    if (!dictionary.contains('/XRef')) {
      problems.add('startxref does not point at a cross-reference stream');
      return null;
    }
    final List<int> widths = <int>[
      for (final String part
          in (RegExp(r'/W\s*\[([^\]]*)\]').firstMatch(dictionary)?.group(1) ??
                  '')
              .trim()
              .split(RegExp(r'\s+')))
        if (part.isNotEmpty) int.parse(part),
    ];
    final int size = int.parse(
      RegExp(r'/Size\s+(\d+)').firstMatch(dictionary)?.group(1) ?? '0',
    );
    final List<int> index = <int>[
      for (final String part
          in (RegExp(
                    r'/Index\s*\[([^\]]*)\]',
                  ).firstMatch(dictionary)?.group(1) ??
                  '0 $size')
              .trim()
              .split(RegExp(r'\s+')))
        if (part.isNotEmpty) int.parse(part),
    ];
    if (widths.length != 3) {
      problems.add('cross-reference stream has no /W');
      return null;
    }
    final List<int> data = _stream(offset);
    final int row = widths[0] + widths[1] + widths[2];
    var position = 0;
    for (int pair = 0; pair + 1 < index.length; pair += 2) {
      for (int step = 0; step < index[pair + 1]; step++) {
        if (position + row > data.length) {
          problems.add('cross-reference stream is short');
          return dictionary;
        }
        final int type = widths[0] == 0 ? 1 : _int(data, position, widths[0]);
        final int field = _int(data, position + widths[0], widths[1]);
        if (type == 1) {
          offsets[index[pair] + step] = field;
        }
        position += row;
      }
    }
    return dictionary;
  }

  void _walk(int id) {
    final String node = _object(id) ?? '';
    if (RegExp(r'/Type\s*/Pages\b').hasMatch(node)) {
      final String kids =
          RegExp(r'/Kids\s*\[([^\]]*)\]').firstMatch(node)?.group(1) ?? '';
      for (final Match kid in RegExp(r'(\d+)\s+0\s+R').allMatches(kids)) {
        _walk(int.parse(kid.group(1)!));
      }
      return;
    }
    if (RegExp(r'/Type\s*/Page\b').hasMatch(node)) {
      pages.add(id);
      return;
    }
    problems.add('page tree node $id is neither /Pages nor /Page');
  }

  /// The page's words, grouped into lines by their baseline.
  List<String> _lines(String page) {
    final List<int> contents = <int>[];
    final Match? array = RegExp(r'/Contents\s*\[([^\]]*)\]').firstMatch(page);
    final Iterable<Match> refs = array != null
        ? RegExp(r'(\d+)\s+0\s+R').allMatches(array.group(1)!)
        : RegExp(r'/Contents\s+(\d+)\s+0\s+R').allMatches(page);
    for (final Match ref in refs) {
      contents.add(int.parse(ref.group(1)!));
    }
    final List<({double x, double y, String text})> words =
        <({double x, double y, String text})>[];
    for (final int id in contents) {
      final int? at = offsets[id];
      if (at == null) {
        problems.add('page content $id has no offset');
        continue;
      }
      words.addAll(_words(latin1.decode(_stream(at))));
    }
    final Map<int, List<({double x, double y, String text})>> rows =
        <int, List<({double x, double y, String text})>>{};
    for (final ({double x, double y, String text}) word in words) {
      rows
          .putIfAbsent(
            (word.y * 10).round(),
            () => <({double x, double y, String text})>[],
          )
          .add(word);
    }
    final List<int> baselines = rows.keys.toList()
      ..sort((int a, int b) => b.compareTo(a));
    return <String>[
      for (final int baseline in baselines)
        (rows[baseline]!..sort(
              (
                ({double x, double y, String text}) a,
                ({double x, double y, String text}) b,
              ) => a.x.compareTo(b.x),
            ))
            .map((({double x, double y, String text}) word) => word.text)
            .join(' '),
    ];
  }

  /// Every string shown in [content], placed through the graphics state's
  /// translations (`q`, `Q`, `cm`) and the text position (`Td`).
  static List<({double x, double y, String text})> _words(String content) {
    final List<({double x, double y, String text})> words =
        <({double x, double y, String text})>[];
    final List<List<double>> saved = <List<double>>[];
    List<double> matrix = <double>[1, 0, 0, 1, 0, 0];
    double tx = 0;
    double ty = 0;
    final List<Object> operands = <Object>[];
    final List<String> shown = <String>[];
    var position = 0;
    while (position < content.length) {
      final String char = content[position];
      if (char.trim().isEmpty) {
        position += 1;
        continue;
      }
      if (char == '(') {
        final ({String text, int end}) string = _literal(content, position);
        shown.add(string.text);
        operands.add(string.text);
        position = string.end;
        continue;
      }
      if (char == '[' || char == ']') {
        position += 1;
        continue;
      }
      final Match token = RegExp(
        r'[^\s()\[\]]+',
      ).matchAsPrefix(content, position)!;
      final String word = token.group(0)!;
      position = token.end;
      final double? number = double.tryParse(word);
      if (number != null) {
        operands.add(number);
        continue;
      }
      switch (word) {
        case 'q':
          saved.add(matrix);
        case 'Q':
          matrix = saved.isEmpty ? matrix : saved.removeLast();
        case 'cm':
          final List<double> m = operands.whereType<double>().toList();
          if (m.length >= 6) {
            matrix = _multiply(m.sublist(m.length - 6), matrix);
          }
        case 'BT':
          tx = 0;
          ty = 0;
        case 'Td':
          final List<double> m = operands.whereType<double>().toList();
          if (m.length >= 2) {
            tx += m[m.length - 2];
            ty += m[m.length - 1];
          }
        case 'TJ' || 'Tj':
          final String text = shown.join();
          if (text.isNotEmpty) {
            words.add((
              x: matrix[0] * tx + matrix[2] * ty + matrix[4],
              y: matrix[1] * tx + matrix[3] * ty + matrix[5],
              text: text,
            ));
          }
      }
      operands.clear();
      shown.clear();
    }
    return words;
  }

  /// The literal string starting at [start], with its escapes resolved.
  static ({String text, int end}) _literal(String content, int start) {
    final StringBuffer out = StringBuffer();
    var depth = 0;
    var position = start;
    while (position < content.length) {
      final String char = content[position];
      if (char == r'\') {
        final String next = content[position + 1];
        final Match? octal = RegExp(
          '[0-7]{1,3}',
        ).matchAsPrefix(content, position + 1);
        if (octal != null) {
          out.writeCharCode(int.parse(octal.group(0)!, radix: 8));
          position = octal.end;
          continue;
        }
        out.write(switch (next) {
          'n' => '\n',
          'r' => '\r',
          't' => '\t',
          'b' => '\b',
          'f' => '\f',
          _ => next,
        });
        position += 2;
        continue;
      }
      if (char == '(') {
        depth += 1;
        if (depth > 1) {
          out.write(char);
        }
      } else if (char == ')') {
        depth -= 1;
        if (depth == 0) {
          return (text: out.toString(), end: position + 1);
        }
        out.write(char);
      } else {
        out.write(char);
      }
      position += 1;
    }
    return (text: out.toString(), end: position);
  }

  static List<double> _multiply(List<double> a, List<double> b) {
    return <double>[
      a[0] * b[0] + a[1] * b[2],
      a[0] * b[1] + a[1] * b[3],
      a[2] * b[0] + a[3] * b[2],
      a[2] * b[1] + a[3] * b[3],
      a[4] * b[0] + a[5] * b[2] + b[4],
      a[4] * b[1] + a[5] * b[3] + b[5],
    ];
  }

  /// The body of object [id], from its header to `endobj` or `stream`.
  String? _object(int id) {
    final int? at = offsets[id];
    if (at == null) {
      problems.add('object $id is not in the cross-reference stream');
      return null;
    }
    return _dictionary(at);
  }

  String _dictionary(int offset) {
    final int end =
        <int>[_text.indexOf('endobj', offset), _text.indexOf('stream', offset)]
            .where((int at) => at >= 0)
            .fold(_text.length, (int a, int b) => a < b ? a : b);
    return _text.substring(offset, end);
  }

  /// The decoded stream of the object at [offset].
  List<int> _stream(int offset) {
    final String dictionary = _dictionary(offset);
    final int keyword = _text.indexOf('stream', offset);
    final int length = int.parse(
      RegExp(r'/Length\s+(\d+)').firstMatch(dictionary)?.group(1) ?? '0',
    );
    var start = keyword + 'stream'.length;
    if (_text.startsWith('\r\n', start)) {
      start += 2;
    } else if (_text.startsWith('\n', start)) {
      start += 1;
    }
    final Uint8List raw = Uint8List.sublistView(bytes, start, start + length);
    if (!dictionary.contains('/FlateDecode')) {
      return raw;
    }
    try {
      return const ZLibDecoder().decodeBytes(raw);
    } on Object {
      problems.add('stream at $offset does not inflate');
      return const <int>[];
    }
  }

  static int? _ref(String dictionary, String key) {
    final Match? match = RegExp(
      '/$key\\s+(\\d+)\\s+0\\s+R',
    ).firstMatch(dictionary);
    return match == null ? null : int.parse(match.group(1)!);
  }

  static int _int(List<int> data, int start, int width) {
    var value = 0;
    for (int index = 0; index < width; index++) {
      value = (value << 8) | data[start + index];
    }
    return value;
  }
}

/// Compares [pdf]'s text, read back by [PdfInspector] page by page, with
/// the text golden at [path] (relative to the package root). Run the tests
/// with `--update-goldens` to rewrite the golden after a deliberate change.
void expectPdfTextGolden(Uint8List pdf, String path) {
  final PdfInspector inspector = PdfInspector(pdf);
  expect(inspector.problems, isEmpty, reason: 'structure of $path');
  final File golden = File(path);
  final String actual = '${inspector.transcript}\n';
  if (autoUpdateGoldenFiles) {
    golden
      ..createSync(recursive: true)
      ..writeAsStringSync(actual);
    return;
  }
  expect(
    golden.existsSync(),
    isTrue,
    reason: '$path is missing; run with --update-goldens to create it',
  );
  expect(actual, golden.readAsStringSync().replaceAll('\r\n', '\n'));
}

/// Renders [document] through [engine] and returns the finished file.
Future<Uint8List> renderPdf(
  PdfEngine engine,
  PdfDocument document, {
  Map<String, Uint8List> images = const <String, Uint8List>{},
  Uint8List? font,
}) async {
  Uint8List? output;
  await for (final double _ in engine.render(
    document: document,
    token: CancellationToken(),
    emit: (Uint8List bytes) => output = bytes,
    discard: () => fail('the render was discarded'),
    images: images,
    font: font,
  )) {}
  return output!;
}
