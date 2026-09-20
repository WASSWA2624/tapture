import 'package:tapture/core/errors/result.dart';

import '../domain/template_repository.dart';

/// Maps spreadsheet rows onto checklist rows and persists them.
final class PredefinedRowsImport {
  /// Creates the importer. Tests pass the in-memory repository or the fake.
  const PredefinedRowsImport(this.templates);

  /// Where confirmed rows are saved.
  final TemplateRepository templates;

  /// Builds checklist rows from [rows], keeping each spreadsheet line number.
  ///
  /// [headerRow] is 1-based. Data starts on the next line. [identifierColumn],
  /// [labelColumn], [aliasColumn] and [contextColumn] are spreadsheet letters.
  static List<TemplateRow> draft({
    required List<List<String>> rows,
    required int headerRow,
    required String identifierColumn,
    required String labelColumn,
    String? aliasColumn,
    String? contextColumn,
  }) {
    final int? idIndex = _columnIndex(identifierColumn);
    final int? labelIndex = _columnIndex(labelColumn);
    if (idIndex == null || labelIndex == null) {
      return const <TemplateRow>[];
    }
    final int? aliasIndex = aliasColumn == null
        ? null
        : _columnIndex(aliasColumn);
    final int? contextIndex = contextColumn == null
        ? null
        : _columnIndex(contextColumn);
    final int start = headerRow < 1 ? 0 : headerRow;
    final Set<String> taken = <String>{};
    final List<TemplateRow> imported = <TemplateRow>[];
    for (int index = start; index < rows.length; index++) {
      final List<String> cells = rows[index];
      final String label = _cell(cells, labelIndex);
      final String rawId = _cell(cells, idIndex);
      if (rawId.isEmpty && label.isEmpty) {
        continue;
      }
      final String identifier = _unique(
        rawId.isEmpty ? 'row_${index + 1}' : rawId,
        taken,
      );
      taken.add(identifier);
      final String? context = contextIndex == null
          ? null
          : _cell(cells, contextIndex);
      imported.add(
        TemplateRow(
          identifier: identifier,
          label: label.isEmpty ? identifier : label,
          outputRowNumber: index + 1,
          aliases: aliasIndex == null
              ? const <String>[]
              : _aliasesOf(_cell(cells, aliasIndex)),
          metadata: <String, Object?>{
            if (context != null && context.isNotEmpty) _contextKey: context,
          },
        ),
      );
    }
    return imported;
  }

  /// Finds a row by identifier, label or alias. Matching is case-insensitive.
  static TemplateRow? match(Iterable<TemplateRow> rows, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return null;
    }
    for (final TemplateRow row in rows) {
      if (row.identifier.toLowerCase() == needle ||
          row.label.toLowerCase() == needle) {
        return row;
      }
      for (final String alias in row.aliases) {
        if (alias.trim().toLowerCase() == needle) {
          return row;
        }
      }
    }
    return null;
  }

  /// Overlay aliases from [aliasColumn] onto [rows] by spreadsheet line.
  static List<TemplateRow> mergeAliases({
    required List<TemplateRow> rows,
    required List<List<String>> sheet,
    required String aliasColumn,
  }) {
    final int? aliasIndex = _columnIndex(aliasColumn);
    if (aliasIndex == null) {
      return rows;
    }
    return <TemplateRow>[
      for (final TemplateRow row in rows)
        row.copyWith(
          aliases:
              _aliasesAt(sheet, row.outputRowNumber, aliasIndex) ?? row.aliases,
        ),
    ];
  }

  /// Context / room / group label stored on [row], when one was imported.
  static String? contextOf(TemplateRow row) {
    for (final String key in _contextKeys) {
      final Object? value = row.metadata[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Writes [rows] onto [template], preserving spreadsheet positions.
  Future<Result<TemplateDef>> apply({
    required TemplateDef template,
    required List<TemplateRow> rows,
  }) {
    return templates.save(template.copyWith(rows: rows));
  }
}

List<String>? _aliasesAt(List<List<String>> sheet, int outputRow, int index) {
  final int rowIndex = outputRow - 1;
  if (rowIndex < 0 || rowIndex >= sheet.length) {
    return null;
  }
  final List<String> aliases = _aliasesOf(_cell(sheet[rowIndex], index));
  return aliases.isEmpty ? null : aliases;
}

List<String> _aliasesOf(String raw) {
  return <String>[
    for (final String part in raw.split(_aliasSplit))
      if (part.trim().isNotEmpty) part.trim(),
  ];
}

String _unique(String base, Set<String> taken) {
  if (!taken.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (taken.contains('${base}_$suffix')) {
    suffix += 1;
  }
  return '${base}_$suffix';
}

int? _columnIndex(String letter) {
  final String raw = letter.trim().toUpperCase();
  if (raw.isEmpty || !_letters.hasMatch(raw)) {
    return null;
  }
  var index = 0;
  for (int i = 0; i < raw.length; i++) {
    index = index * 26 + (raw.codeUnitAt(i) - 64);
  }
  return index - 1;
}

String _cell(List<String> row, int index) {
  if (index < 0 || index >= row.length) {
    return '';
  }
  return row[index].trim();
}

final RegExp _aliasSplit = RegExp(r'[,;\n]');

final RegExp _letters = RegExp(r'^[A-Z]+$');

const String _contextKey = 'context';

const List<String> _contextKeys = <String>[_contextKey, 'room', 'group'];
