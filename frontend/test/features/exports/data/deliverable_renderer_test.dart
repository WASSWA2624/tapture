import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/features/exports/data/deliverable_renderer.dart';

void main() {
  final DateTime createdAt = DateTime.utc(2026, 9, 24, 8);

  test('each chosen table format is rendered from the same records', () async {
    final DeliverableRenderer renderer = DeliverableRenderer(
      files: FileReader.memory(),
    );

    final Map<String, Uint8List> outputs = _ok(
      await renderer.render(
        _request(<ExportFormat>{
          ExportFormat.xlsx,
          ExportFormat.csv,
          ExportFormat.json,
        }),
        createdAt: createdAt,
        cancel: CancellationToken(),
      ),
    );

    expect(outputs.keys.toSet(), <String>{
      'records.xlsx',
      'Asset.csv',
      'Rooms.csv',
      'records.json',
      'dictionary.json',
    });
    expect(outputs['records.xlsx']!.take(2), <int>[0x50, 0x4B]);
    // Spreadsheet apps read the byte-order mark as UTF-8.
    expect(outputs['Asset.csv']!.take(3), <int>[0xEF, 0xBB, 0xBF]);
    final String assets = utf8.decode(outputs['Asset.csv']!);
    expect(assets, contains('Number,Serial'));
    expect(assets, contains('A-1'));
    expect(utf8.decode(outputs['Rooms.csv']!), contains('B2'));
    final Map<String, Object?> json = Map<String, Object?>.from(
      jsonDecode(utf8.decode(outputs['records.json']!)) as Map,
    );
    expect(json['records'], hasLength(3));
    // One dictionary entry per template version a record was captured on.
    final List<Object?> dictionary =
        jsonDecode(utf8.decode(outputs['dictionary.json']!)) as List<Object?>;
    expect(
      <String>[
        for (final Object? entry in dictionary)
          if (entry is Map<String, Object?>)
            '${entry['templateId']}@${entry['templateVersion']}',
      ],
      <String>['t1@1', 't1@2', 't2@1'],
    );
  });

  test('a report is rendered with photos read from their sources', () async {
    final Uint8List photo = img.encodeJpg(img.Image(width: 8, height: 6));
    final DeliverableRenderer renderer = DeliverableRenderer(
      files: FileReader.memory(<String, Uint8List>{
        'projects/plant/photos/front.jpg': photo,
      }),
    );
    final List<double> progress = <double>[];

    final Map<String, Uint8List> outputs = _ok(
      await renderer.render(
        _request(const <ExportFormat>{ExportFormat.pdf}, withPhoto: true),
        createdAt: createdAt,
        cancel: CancellationToken(),
        onProgress: progress.add,
      ),
    );

    expect(outputs.keys, contains('records.pdf'));
    expect(outputs.keys, isNot(contains('records.xlsx')));
    expect(latin1.decode(outputs['records.pdf']!), startsWith('%PDF-'));
    expect(progress, isNotEmpty);
  });

  test('a report whose photo cannot be read fails', () async {
    final DeliverableRenderer renderer = DeliverableRenderer(
      files: FileReader.memory(),
    );

    final Result<Map<String, Uint8List>> rendered = await renderer.render(
      _request(const <ExportFormat>{ExportFormat.pdf}, withPhoto: true),
      createdAt: createdAt,
      cancel: CancellationToken(),
    );

    expect(
      _failure(rendered).message,
      contains('projects/plant/photos/front.jpg'),
    );
  });

  test('a cancelled render writes nothing', () async {
    final DeliverableRenderer renderer = DeliverableRenderer(
      files: FileReader.memory(),
    );

    final Result<Map<String, Uint8List>> rendered = await renderer.render(
      _request(const <ExportFormat>{ExportFormat.xlsx}),
      createdAt: createdAt,
      cancel: CancellationToken()..cancel(),
    );

    expect(_failure(rendered), isA<CancelledFailure>());
  });
}

ExportRequest _request(Set<ExportFormat> formats, {bool withPhoto = false}) {
  return ExportRequest(
    projectId: 'p1',
    formats: formats,
    scope: (
      kind: ExportScopeKind.all,
      context: null,
      from: null,
      to: null,
      filter: null,
    ),
    columns: (raw: false, refined: true, confidence: false, evidence: false),
    extras: (
      dictionary: true,
      photoIndex: true,
      photoMode: 'relative',
      delimiter: ',',
    ),
    records: <ExportRecord>[
      ExportRecord(
        id: 'r1',
        number: '1',
        templateId: 't1',
        templateName: 'Asset',
        templateVersion: '1',
        status: 'approved',
        approved: true,
        values: <ExportValue>[_value('serial', 'Serial', 'A-1')],
        photoSources: <String, String>{
          if (withPhoto) 'ph1': 'projects/plant/photos/front.jpg',
        },
        photos: <ExportPhoto>[
          if (withPhoto)
            (
              id: 'ph1',
              recordId: 'r1',
              type: 'front',
              caption: 'Front',
              storedPath: 'photos/1_front_1.jpg',
              originalName: 'front.jpg',
              sequence: 1,
            ),
        ],
      ),
      ExportRecord(
        id: 'r2',
        number: '2',
        templateId: 't1',
        templateName: 'Asset',
        templateVersion: '2',
        status: 'captured',
        values: <ExportValue>[_value('serial', 'Serial number', 'A-2')],
      ),
      ExportRecord(
        id: 'r3',
        number: '3',
        templateId: 't2',
        templateName: 'Rooms',
        templateVersion: '1',
        status: 'approved',
        approved: true,
        values: <ExportValue>[_value('room', 'Room', 'B2')],
      ),
    ],
  );
}

ExportValue _value(String key, String label, String text) {
  return (
    key: key,
    label: label,
    type: 'text',
    raw: text,
    refined: null,
    finalText: text,
    unit: null,
    code: null,
    confidence: null,
    evidence: null,
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

Failure _failure<T>(Result<T> result) {
  return switch (result) {
    Success<T>() => throw TestFailure('Expected a failure.'),
    FailureResult<T>(:final Failure failure) => failure,
  };
}
