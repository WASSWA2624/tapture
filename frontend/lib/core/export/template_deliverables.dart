import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/files/path_sanitizer.dart';

import 'export_output_template.dart';
import 'export_record.dart';
import 'export_request.dart';
import 'ooxml_package.dart';
import 'plain_text_writer.dart';
import 'record_document_text.dart';
import 'value_formatter.dart';
import 'word_writer.dart';
import 'xlsx_template_writer.dart';

/// Source-preserving files and explicit omissions from captured template mappings.
abstract final class TemplateDeliverables {
  /// Fills selected original templates without provider calls or current-schema reads.
  static Map<String, Uint8List> render(
    ExportRequest request,
    Map<String, Uint8List> sources,
  ) {
    final Map<String, Uint8List> outputs = <String, Uint8List>{};
    final Set<String> taken = <String>{};
    String outputName(String base, String extension) {
      var name = '$base.$extension';
      for (var copy = 2; !taken.add(name); copy++) {
        name = '$base-$copy.$extension';
      }
      return name;
    }

    final List<Map<String, Object?>> summary = <Map<String, Object?>>[];
    for (final ExportOutputTemplate template in request.outputTemplates) {
      if (!selected(request, template)) continue;
      final Uint8List? source = sources[template.key];
      if (source == null ||
          (template.sourceHash.isNotEmpty &&
              sha256.convert(source).toString() != template.sourceHash)) {
        throw OoxmlPackage.invalid();
      }
      final List<ExportRecord> records = request.records
          .where(
            (record) =>
                record.templateId == template.templateId &&
                record.templateVersion == template.templateVersion,
          )
          .toList();
      if (records.isEmpty) continue;
      final String stem = sanitiseSegment(
        'template-${template.templateId}-v${template.templateVersion}',
      );
      if (template.kind == 'xlsx') {
        outputs[outputName(stem, 'xlsx')] = XlsxTemplateWriter.fill(
          source: source,
          template: template,
          records: records,
          markedIncomplete: request.markedIncomplete,
        );
      } else {
        for (final ExportRecord record in records) {
          final String base = sanitiseSegment('$stem-${record.number}');
          final String name = outputName(base, template.kind);
          outputs[name] = template.kind == 'docx'
              ? WordWriter.fill(
                  source,
                  record,
                  markedIncomplete: request.markedIncomplete,
                )
              : PlainTextWriter.fill(
                  source,
                  record,
                  markedIncomplete: request.markedIncomplete,
                );
        }
      }
      final Set<String> filled = records
          .map((record) => record.templateRowId)
          .whereType<String>()
          .toSet();
      final Set<String> fields = template.kind == 'xlsx'
          ? template.columns.keys.toSet()
          : template.kind == 'docx'
          ? WordWriter.fields(source)
          : RecordDocumentText.placeholder
                .allMatches(PlainTextWriter.decode(source))
                .map((match) => match.group(1)!)
                .toSet();
      summary.add(<String, Object?>{
        'template': template.toJson(),
        'sourceSha256': sha256.convert(source).toString(),
        'notCapturedRowIds': <String>[
          for (final String id in template.rows.keys)
            if (!filled.contains(id)) id,
        ],
        'unmatchedRecordIds': <String>[
          if (template.rows.isNotEmpty)
            for (final ExportRecord record in records)
              if (!template.rows.containsKey(record.templateRowId)) record.id,
        ],
        'missingFieldKeys': <String, List<String>>{
          for (final ExportRecord record in records)
            record.id: _missing(record, fields),
        },
        'unpreservedFeatures': <String>[
          if (template.kind != 'txt' &&
              OoxmlPackage.open(
                source,
              ).names.any((name) => name.startsWith('_xmlsignatures/')))
            'Digital signatures require signing the filled output again.',
        ],
      });
    }
    if (summary.isNotEmpty) {
      outputs['template-output-summary.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode(summary)),
      );
    }
    return outputs;
  }

  /// Whether this output format was explicitly selected.
  static bool selected(ExportRequest request, ExportOutputTemplate template) =>
      request.formats.any((format) => format.name == template.kind) &&
      const <ExportFormat>{
        ExportFormat.xlsx,
        ExportFormat.docx,
        ExportFormat.txt,
      }.any((format) => format.name == template.kind);
}

List<String> _missing(ExportRecord record, Set<String> fields) {
  final Map<String, String> values = RecordDocumentText.values(record);
  return <String>[
    for (final String field in fields)
      if ((values[field] ?? '').trim().isEmpty) field,
  ];
}
