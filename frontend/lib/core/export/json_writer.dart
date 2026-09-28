import 'dart:convert';

import 'export_record.dart';
import 'export_request.dart';
import 'value_formatter.dart';

/// Full-fidelity JSON, one record at a time (task 018).
final class JsonWriter {
  /// Writes [request] by appending one record at a time.
  static String write(ExportRequest request) {
    const ExportValueFormatter formatter = ExportValueFormatter(<String>{});
    final StringBuffer buffer = StringBuffer('{"records":[');
    for (var index = 0; index < request.records.length; index++) {
      if (index > 0) {
        buffer.write(',');
      }
      buffer.write(_record(request, formatter, request.records[index]));
    }
    buffer.write('],"markedIncomplete":');
    buffer.write(request.markedIncomplete ? 'true' : 'false');
    buffer.write('}');
    return buffer.toString();
  }

  static String _record(
    ExportRequest request,
    ExportValueFormatter formatter,
    ExportRecord record,
  ) {
    final Map<String, Object?> body = <String, Object?>{
      'id': record.id,
      'number': record.number,
      'templateId': record.templateId,
      'templateVersion': record.templateVersion,
      'status': record.status,
      'contextPath': record.contextPath,
      'operator': record.operatorName,
      'photos': record.toJson()['photos'],
      'definitions': record.definitions,
      'provenance': record.provenance,
      'values': <Map<String, Object?>>[
        for (final ExportValue value in record.values)
          <String, Object?>{
            'key': value.key,
            'raw': formatter.format(value.raw, value.type, ExportFormat.json),
            'refined': formatter.format(
              value.refined,
              value.type,
              ExportFormat.json,
            ),
            'final': formatter.format(
              value.finalText,
              value.type,
              ExportFormat.json,
            ),
            'confidence': value.confidence,
            'evidence': value.evidence,
          },
      ],
    };
    return jsonEncode(body);
  }
}
