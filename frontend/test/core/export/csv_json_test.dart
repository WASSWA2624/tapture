import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/csv_writer.dart';
import 'package:tapture/core/export/export_dictionary.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/json_writer.dart';
import 'package:tapture/core/export/value_formatter.dart';

void main() {
  const ExportRequest request = ExportRequest(
    projectId: 'p1',
    formats: <ExportFormat>{ExportFormat.csv, ExportFormat.json},
    scope: (
      kind: ExportScopeKind.all,
      context: null,
      from: null,
      to: null,
      filter: null,
    ),
    columns: (raw: true, refined: true, confidence: false, evidence: false),
    extras: (
      dictionary: true,
      photoIndex: true,
      photoMode: 'filename',
      delimiter: ',',
    ),
    records: <ExportRecord>[
      ExportRecord(
        id: 'r1',
        number: '00734',
        templateId: 't1',
        templateName: 'Asset',
        status: 'approved',
        values: <ExportValue>[
          (
            key: 'note',
            label: 'Note',
            type: 'text',
            raw: 'line 1\n"quoted"',
            refined: 'tidy',
            finalText: 'tidy',
            unit: null,
            code: null,
            confidence: null,
            evidence: null,
          ),
        ],
      ),
    ],
  );

  test('csv quotes delimiters and newlines and keeps the number', () {
    final String csv = CsvWriter.write(request).values.single;
    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('00734'));
    expect(csv, contains('"line 1\n""quoted"""'));
  });

  test(
    'json carries raw, refined and final and the dictionary names the field',
    () {
      final Map<String, Object?> json = Map<String, Object?>.from(
        jsonDecode(JsonWriter.write(request)) as Map<Object?, Object?>,
      );
      final String encoded = jsonEncode(json);
      expect(encoded, contains('00734'));
      expect(encoded, contains('tidy'));
      final List<DictionaryField> dictionary = ExportDictionary.describe(
        request.records,
      );
      expect(dictionary.single.key, 'note');
      expect(dictionary.single.label, 'Note');
    },
  );
}
