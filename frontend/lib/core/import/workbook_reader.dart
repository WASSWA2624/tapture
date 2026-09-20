import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/xlsx_sheet.dart';
import 'package:tapture/core/files/file_validation.dart';

import 'header_detection.dart';
import 'type_inference.dart';

/// Opens an XLSX or CSV off the UI thread and reports sheets, header and
/// per-column type suggestions.
abstract final class WorkbookReader {
  /// Validates [path], then parses it on a worker isolate (FE-PERF-02).
  static Future<Result<WorkbookSnapshot>> open(
    String path, {
    void Function(double)? onProgress,
    CancellationToken? cancel,
  }) async {
    final Result<ImportKind> gate = await FileValidation().validate(
      File(path),
      allowed: const <ImportKind>{ImportKind.spreadsheet},
    );
    switch (gate) {
      case FailureResult<ImportKind>(:final Failure failure):
        return FailureResult<WorkbookSnapshot>(failure);
      case Success<ImportKind>():
        break;
    }
    final Result<Object> parsed = await runIsolate(
      _readWorkbookInIsolate,
      path,
      onProgress: onProgress,
      cancel: cancel,
    );
    return switch (parsed) {
      FailureResult<Object>(:final Failure failure) =>
        FailureResult<WorkbookSnapshot>(failure),
      Success<Object>(:final Object value) => _snapshotOf(_asStringMap(value)),
    };
  }
}

/// Sheets, dimensions, rows and editable suggestions for one workbook.
typedef WorkbookSnapshot = ({List<WorkbookSheet> sheets});

/// One sheet: used range, merged cells, existing rows, header and columns.
typedef WorkbookSheet = ({
  String name,
  int rowCount,
  int columnCount,
  String usedRange,
  List<String> mergedCells,
  List<List<String>> rows,
  HeaderGuess header,
  List<ColumnSuggestion> columns,
});

/// Isolate entry: streams [path] and returns a sendable map.
Object _readWorkbookInIsolate(String path) {
  try {
    return _read(path);
  } on _Protected {
    return const <String, Object?>{'status': _passwordStatus};
  } on Object {
    return const <String, Object?>{'status': _corruptStatus};
  }
}

Result<WorkbookSnapshot> _snapshotOf(Map<String, Object?> raw) {
  final Object? status = raw['status'];
  if (status == _passwordStatus) {
    return const FailureResult<WorkbookSnapshot>(_password);
  }
  if (status != _okStatus) {
    return const FailureResult<WorkbookSnapshot>(_corrupt);
  }
  final Object? sheetsRaw = raw['sheets'];
  if (sheetsRaw is! List) {
    return const FailureResult<WorkbookSnapshot>(_corrupt);
  }
  return Success<WorkbookSnapshot>((
    sheets: <WorkbookSheet>[
      for (final Object? item in sheetsRaw) _sheetOf(_asStringMap(item)),
    ],
  ));
}

WorkbookSheet _sheetOf(Map<String, Object?> raw) {
  final List<List<String>> rows = _stringGrid(raw['rows']);
  final List<String> labels = _stringList(raw['headers']);
  final HeaderGuess header = (
    rowNumber: raw['headerRow'] as int? ?? 1,
    labels: labels,
    isSuggestion: true,
  );
  return (
    name: raw['name'] as String? ?? '',
    rowCount: raw['rowCount'] as int? ?? rows.length,
    columnCount: raw['columnCount'] as int? ?? labels.length,
    usedRange: raw['usedRange'] as String? ?? '',
    mergedCells: _stringList(raw['mergedCells']),
    rows: rows,
    header: header,
    columns: <ColumnSuggestion>[
      for (final Object? item in _asList(raw['columns']))
        _columnOf(_asStringMap(item)),
    ],
  );
}

ColumnSuggestion _columnOf(Map<String, Object?> raw) {
  return (
    header: raw['header'] as String? ?? '',
    typeName: raw['typeName'] as String? ?? 'text',
    unit: raw['unit'] as String?,
    options: _stringList(raw['options']),
    isSuggestion: true,
  );
}

Map<String, Object?> _read(String path) {
  final File file = File(path);
  IsolateRunner.reportProgress(0);
  final Uint8List bytes = _streamBytes(file);
  IsolateRunner.reportProgress(0.2);
  if (_isOle(bytes)) {
    throw const _Protected();
  }
  if (path.toLowerCase().endsWith('.csv')) {
    return <String, Object?>{
      'status': _okStatus,
      'sheets': <Map<String, Object?>>[_csvSheet(path, bytes)],
    };
  }
  return _xlsx(bytes);
}

Uint8List _streamBytes(File file) {
  final int length = file.lengthSync();
  final RandomAccessFile handle = file.openSync();
  final BytesBuilder builder = BytesBuilder(copy: false);
  final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes);
  var read = 0;
  try {
    while (true) {
      final int n = handle.readIntoSync(buffer);
      if (n == 0) {
        break;
      }
      builder.add(n == buffer.length ? buffer : buffer.sublist(0, n));
      read += n;
      if (length > 0) {
        IsolateRunner.reportProgress(0.2 * read / length);
      }
    }
  } finally {
    handle.closeSync();
  }
  return builder.takeBytes();
}

Map<String, Object?> _xlsx(Uint8List bytes) {
  final Archive archive = ZipDecoder().decodeBytes(bytes);
  if (_isEncrypted(archive)) {
    throw const _Protected();
  }
  final String? workbookXml = _part(archive, 'xl/workbook.xml');
  if (workbookXml == null) {
    throw const _Corrupt();
  }
  final List<({String name, String id})> listed = _sheetList(workbookXml);
  final Map<String, String> rels = _rels(
    _part(archive, 'xl/_rels/workbook.xml.rels') ?? '',
  );
  final List<String> shared = _sharedStrings(
    _part(archive, 'xl/sharedStrings.xml') ?? '',
  );
  final List<Map<String, Object?>> sheets = <Map<String, Object?>>[];
  for (int index = 0; index < listed.length; index++) {
    final String target = rels[listed[index].id] ?? '';
    final String? xml = _part(archive, _sheetPath(target));
    if (xml == null) {
      throw const _Corrupt();
    }
    sheets.add(_sheetMap(listed[index].name, xml, shared));
    IsolateRunner.reportProgress(0.2 + 0.8 * (index + 1) / listed.length);
  }
  if (sheets.isEmpty) {
    throw const _Corrupt();
  }
  return <String, Object?>{'status': _okStatus, 'sheets': sheets};
}

Map<String, Object?> _sheetMap(String name, String xml, List<String> shared) {
  final ({
    List<List<String>> rows,
    int rowCount,
    int columnCount,
    String usedRange,
    List<String> mergedCells,
  })
  parsed = _grid(xml, shared);
  return _describedSheet(
    name: name,
    rows: parsed.rows,
    rowCount: parsed.rowCount,
    columnCount: parsed.columnCount,
    usedRange: parsed.usedRange,
    mergedCells: parsed.mergedCells,
  );
}

Map<String, Object?> _csvSheet(String path, Uint8List bytes) {
  String text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('\uFEFF')) {
    text = text.substring(1);
  }
  final List<String> lines = _csvLines(text);
  final String delimiter = _delimiterOf(lines);
  final List<List<String>> rows = <List<String>>[
    for (final String line in lines) _csvRow(line, delimiter),
  ];
  final int width = rows.fold<int>(
    0,
    (int max, List<String> row) => row.length > max ? row.length : max,
  );
  final String stem = _stem(path);
  return _describedSheet(
    name: stem.isEmpty ? 'Sheet1' : stem,
    rows: rows,
    rowCount: rows.length,
    columnCount: width,
    usedRange: _usedRange(rows.length, width),
    mergedCells: const <String>[],
  );
}

Map<String, Object?> _describedSheet({
  required String name,
  required List<List<String>> rows,
  required int rowCount,
  required int columnCount,
  required String usedRange,
  required List<String> mergedCells,
}) {
  final HeaderGuess header = HeaderDetection.choose(rows);
  final List<List<String>> below = rows.length > header.rowNumber
      ? rows.sublist(header.rowNumber)
      : const <List<String>>[];
  final int take = below.length < AppConstants.workbook.sampleRows
      ? below.length
      : AppConstants.workbook.sampleRows;
  final List<ColumnSuggestion> columns = TypeInference.suggest(
    headers: header.labels,
    sampleRows: below.take(take).toList(),
  );
  return <String, Object?>{
    'name': name,
    'rowCount': rowCount,
    'columnCount': columnCount,
    'usedRange': usedRange,
    'mergedCells': mergedCells,
    'rows': rows,
    'headerRow': header.rowNumber,
    'headers': header.labels,
    'columns': <Map<String, Object?>>[
      for (final ColumnSuggestion column in columns)
        <String, Object?>{
          'header': column.header,
          'typeName': column.typeName,
          'unit': column.unit,
          'options': column.options,
          'isSuggestion': true,
        },
    ],
  };
}

({
  List<List<String>> rows,
  int rowCount,
  int columnCount,
  String usedRange,
  List<String> mergedCells,
})
_grid(String xml, List<String> shared) {
  final Map<(int, int), String> cells = <(int, int), String>{};
  var maxRow = 0;
  var maxCol = 0;
  for (final Match match in _cellTag.allMatches(xml)) {
    final String attrs = match.group(1) ?? '';
    final String body = match.group(2) ?? '';
    final String? ref = _attr(attrs, 'r');
    if (ref == null) {
      continue;
    }
    final ({int row, int column}) at = _a1(ref);
    if (at.row > maxRow) {
      maxRow = at.row;
    }
    if (at.column > maxCol) {
      maxCol = at.column;
    }
    cells[(at.row, at.column)] = _cellText(attrs, body, shared);
  }
  final String? dimension = _first(_dimensionRef, xml);
  var rowCount = maxRow;
  var columnCount = maxCol;
  if (dimension != null) {
    final List<String> parts = dimension.split(':');
    final ({int row, int column}) last = _a1(parts.last);
    if (last.row > rowCount) {
      rowCount = last.row;
    }
    if (last.column > columnCount) {
      columnCount = last.column;
    }
  }
  final List<List<String>> rows = <List<String>>[
    for (int row = 1; row <= rowCount; row++)
      <String>[
        for (int column = 1; column <= columnCount; column++)
          cells[(row, column)] ?? '',
      ],
  ];
  return (
    rows: rows,
    rowCount: rowCount,
    columnCount: columnCount,
    usedRange: dimension ?? _usedRange(rowCount, columnCount),
    mergedCells: <String>[
      for (final Match match in _mergeRef.allMatches(xml))
        if (match.group(1) != null) match.group(1)!,
    ],
  );
}

String _cellText(String attrs, String body, List<String> shared) {
  final String type = _attr(attrs, 't') ?? '';
  if (type == 's') {
    final int? index = int.tryParse(_inner(body, 'v') ?? '');
    if (index == null || index < 0 || index >= shared.length) {
      return '';
    }
    return shared[index];
  }
  if (type == 'b') {
    return _inner(body, 'v') == '1' ? 'true' : 'false';
  }
  if (type == 'inlineStr' || type == 'str') {
    return _unescape(_inner(body, 't') ?? _inner(body, 'v') ?? '');
  }
  final String raw = _inner(body, 'v') ?? '';
  if (raw.isEmpty) {
    return '';
  }
  if (_attr(attrs, 's') == '2') {
    return _fromSerial(raw);
  }
  return raw;
}

String _fromSerial(String raw) {
  final double? serial = double.tryParse(raw);
  if (serial == null) {
    return raw;
  }
  final DateTime epoch = DateTime.utc(1899, 12, 30);
  final DateTime at = DateTime.fromMillisecondsSinceEpoch(
    epoch.millisecondsSinceEpoch +
        (serial * Duration.millisecondsPerDay).round(),
    isUtc: true,
  );
  final String date =
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';
  if (at.hour == 0 && at.minute == 0 && at.second == 0) {
    return date;
  }
  return '$date '
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}:'
      '${at.second.toString().padLeft(2, '0')}';
}

List<({String name, String id})> _sheetList(String xml) {
  return <({String name, String id})>[
    for (final Match match in _sheetTag.allMatches(xml))
      (name: _unescape(match.group(1) ?? ''), id: match.group(2) ?? ''),
  ];
}

Map<String, String> _rels(String xml) {
  return <String, String>{
    for (final Match match in _relTag.allMatches(xml))
      match.group(1) ?? '': match.group(2) ?? '',
  };
}

List<String> _sharedStrings(String xml) {
  final List<String> values = <String>[];
  for (final Match item in _sharedItem.allMatches(xml)) {
    final StringBuffer text = StringBuffer();
    for (final Match piece in _sharedText.allMatches(item.group(0) ?? '')) {
      text.write(_unescape(piece.group(1) ?? ''));
    }
    values.add(text.toString());
  }
  return values;
}

List<String> _csvLines(String text) {
  final List<String> lines = <String>[];
  final StringBuffer current = StringBuffer();
  var inQuotes = false;
  for (int index = 0; index < text.length; index++) {
    final String ch = text[index];
    if (ch == '"') {
      inQuotes = !inQuotes;
      current.write(ch);
      continue;
    }
    if (!inQuotes && (ch == '\n' || ch == '\r')) {
      if (ch == '\r' && index + 1 < text.length && text[index + 1] == '\n') {
        index++;
      }
      lines.add(current.toString());
      current.clear();
      continue;
    }
    current.write(ch);
  }
  if (current.isNotEmpty) {
    lines.add(current.toString());
  }
  return lines;
}

String _delimiterOf(List<String> lines) {
  for (final String line in lines) {
    if (line.trim().isEmpty) {
      continue;
    }
    final int commas = ','.allMatches(line).length;
    final int semis = ';'.allMatches(line).length;
    return semis > commas ? ';' : ',';
  }
  return ',';
}

List<String> _csvRow(String line, String delimiter) {
  final List<String> cells = <String>[];
  final StringBuffer current = StringBuffer();
  var inQuotes = false;
  for (int index = 0; index < line.length; index++) {
    final String ch = line[index];
    if (ch == '"') {
      if (inQuotes && index + 1 < line.length && line[index + 1] == '"') {
        current.write('"');
        index++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }
    if (!inQuotes && ch == delimiter) {
      cells.add(current.toString());
      current.clear();
      continue;
    }
    current.write(ch);
  }
  cells.add(current.toString());
  return cells;
}

bool _isEncrypted(Archive archive) {
  for (final ArchiveFile file in archive.files) {
    final String name = file.name.replaceAll(r'\', '/').toLowerCase();
    if (name.endsWith('encryptioninfo') || name.endsWith('encryptedpackage')) {
      return true;
    }
  }
  return false;
}

bool _isOle(Uint8List bytes) {
  if (bytes.length < _oleMagic.length) {
    return false;
  }
  for (int index = 0; index < _oleMagic.length; index++) {
    if (bytes[index] != _oleMagic[index]) {
      return false;
    }
  }
  return true;
}

String? _part(Archive archive, String path) {
  final String wanted = path.replaceAll(r'\', '/').toLowerCase();
  for (final ArchiveFile file in archive.files) {
    if (file.name.replaceAll(r'\', '/').toLowerCase() == wanted) {
      final Object? raw = file.content;
      if (raw is List<int>) {
        return utf8.decode(raw, allowMalformed: true);
      }
    }
  }
  return null;
}

String _sheetPath(String target) {
  String path = target.replaceAll(r'\', '/');
  if (path.startsWith('/')) {
    path = path.substring(1);
  }
  if (path.startsWith('xl/')) {
    return path;
  }
  return 'xl/$path';
}

String _usedRange(int rows, int columns) {
  if (rows < 1 || columns < 1) {
    return 'A1';
  }
  return 'A1:${XlsxSheet.columnName(columns - 1)}$rows';
}

({int row, int column}) _a1(String ref) {
  var column = 0;
  var index = 0;
  while (index < ref.length) {
    final int code = ref.codeUnitAt(index);
    if (code < 65 || code > 90) {
      break;
    }
    column = column * 26 + (code - 64);
    index++;
  }
  return (row: int.tryParse(ref.substring(index)) ?? 0, column: column);
}

String? _attr(String attrs, String name) {
  return _first(RegExp('$name="([^"]*)"'), attrs);
}

String? _inner(String xml, String tag) {
  return _first(RegExp('<$tag[^>]*>([^<]*)</$tag>'), xml);
}

String? _first(RegExp pattern, String source) {
  return pattern.firstMatch(source)?.group(1);
}

String _unescape(String value) {
  return value
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}

String _stem(String path) {
  final String name = path.replaceAll(r'\', '/').split('/').last;
  final int dot = name.lastIndexOf('.');
  return dot <= 0 ? name : name.substring(0, dot);
}

List<String> _stringList(Object? raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return <String>[
    for (final Object? item in raw)
      if (item is String) item,
  ];
}

List<List<String>> _stringGrid(Object? raw) {
  if (raw is! List) {
    return const <List<String>>[];
  }
  return <List<String>>[
    for (final Object? row in raw)
      if (row is List)
        <String>[for (final Object? cell in row) cell is String ? cell : ''],
  ];
}

Map<String, Object?> _asStringMap(Object? raw) {
  if (raw is Map<String, Object?>) {
    return raw;
  }
  if (raw is! Map) {
    return const <String, Object?>{};
  }
  return <String, Object?>{
    for (final MapEntry<dynamic, dynamic> entry in raw.entries)
      if (entry.key is String) entry.key as String: entry.value as Object?,
  };
}

List<Object?> _asList(Object? raw) {
  if (raw is List) {
    return raw;
  }
  return const <Object?>[];
}

const List<int> _oleMagic = <int>[
  0xD0,
  0xCF,
  0x11,
  0xE0,
  0xA1,
  0xB1,
  0x1A,
  0xE1,
];

const String _okStatus = 'ok';
const String _passwordStatus = 'password';
const String _corruptStatus = 'corrupt';

final RegExp _sheetTag = RegExp('name="([^"]*)"[^>]*r:id="([^"]*)"');
final RegExp _relTag = RegExp('Id="([^"]*)"[^>]*Target="([^"]*)"');
final RegExp _sharedItem = RegExp(r'<si>[\s\S]*?</si>');
final RegExp _sharedText = RegExp(r'<t[^>]*>([^<]*)</t>');
final RegExp _dimensionRef = RegExp(r'<dimension[^>]*ref="([^"]*)"');
final RegExp _mergeRef = RegExp(r'<mergeCell[^>]*ref="([^"]*)"');
final RegExp _cellTag = RegExp(r'<c\b([^>]*)>([\s\S]*?)</c>');

const ValidationFailure _password = ValidationFailure(
  message: Copy.workbookPassword,
  recoveryAction: Copy.workbookPasswordRecovery,
);

const CorruptionFailure _corrupt = CorruptionFailure(
  message: Copy.workbookCorrupt,
  recoveryAction: Copy.workbookCorruptRecovery,
);

final class _Protected implements Exception {
  const _Protected();
}

final class _Corrupt implements Exception {
  const _Corrupt();
}
