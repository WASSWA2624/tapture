import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/naming/domain_names.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/record_entry.dart';
import 'package:tapture/features/records/domain/record_flag.dart';
import 'package:tapture/features/records/domain/record_photo.dart';
import 'package:tapture/features/records/domain/record_summary.dart';
import 'package:tapture/features/records/domain/record_value.dart';

void main() {
  final DateTime at = DateTime.utc(2026, 9, 17, 8);
  final RecordEntry entry = RecordEntry(
    id: 'record-1',
    projectId: 'project-1',
    templateId: 'template-1',
    status: RecordStatus.approved,
    capturedAt: at,
    capturedBy: 'device-1',
    updatedAt: at,
    number: 7,
    name: 'Autoclave',
    identifier: 'SN-1',
    values: const <RecordValue>[
      RecordValue(fieldKey: 'model', raw: 'Autoclave'),
      RecordValue(fieldKey: 'serial', raw: 'SN-1'),
      RecordValue(fieldKey: 'colour', raw: 'Blue', retired: true),
    ],
    photos: const <RecordPhoto>[
      RecordPhoto(id: 'photo-1', sha256: 'a', storagePath: 'p1'),
      RecordPhoto(id: 'photo-2', sha256: 'b', storagePath: 'p2', sortOrder: 1),
    ],
    caption: 'By the door',
    audioClips: 1,
    context: const <String, String>{'site': 'North', 'room': 'Theatre'},
    flags: const <RecordFlag>{RecordFlag.hasPhotos},
    approvedAt: at,
    approvedBy: 'Ada',
  );

  test('the type carries the canonical record name', () {
    expect(entry.runtimeType.toString(), DomainNames.recordEntry);
  });

  test('valueOf finds a value by field key, retired ones included', () {
    expect(entry.valueOf('serial')?.display, 'SN-1');
    expect(entry.valueOf('colour')?.retired, isTrue);
    expect(entry.valueOf('missing'), isNull);
  });

  test('live and retired values split the values without losing any', () {
    expect(
      entry.liveValues.map((RecordValue value) => value.fieldKey),
      <String>['model', 'serial'],
    );
    expect(entry.retiredValues.single.fieldKey, 'colour');
  });

  test('the context label is the deepest context value that is set', () {
    expect(entry.contextLabel, 'Theatre');
    expect(
      entry
          .copyWith(context: <String, String>{'site': 'North', 'room': ''})
          .contextLabel,
      'North',
    );
    expect(entry.copyWith(context: <String, String>{}).contextLabel, isEmpty);
  });

  test('isDeleted says whether the record is in the recycle bin', () {
    expect(entry.isDeleted, isFalse);
    expect(entry.copyWith(status: RecordStatus.deleted).isDeleted, isTrue);
  });

  test('toSummary keeps the list row fields and the first photo as thumb', () {
    final RecordSummary row = entry.toSummary();
    expect(row.id, 'record-1');
    expect(row.number, 7);
    expect(row.name, 'Autoclave');
    expect(row.identifier, 'SN-1');
    expect(row.contextLabel, 'Theatre');
    expect(row.status, RecordStatus.approved);
    expect(row.thumb?.id, 'photo-1');
    expect(row.photoCount, 2);
    expect(row.capturedAt, at);
    expect(row.flags, <RecordFlag>{RecordFlag.hasPhotos});
    expect(
      entry.copyWith(photos: const <RecordPhoto>[]).toSummary().thumb,
      isNull,
    );
  });

  test(
    'records with equal contents are equal, collections compared by value',
    () {
      final RecordEntry same = entry.copyWith(
        values: List<RecordValue>.of(entry.values),
        photos: List<RecordPhoto>.of(entry.photos),
        context: <String, String>{'site': 'North', 'room': 'Theatre'},
        flags: <RecordFlag>{RecordFlag.hasPhotos},
      );
      expect(same, entry);
      expect(same.hashCode, entry.hashCode);
      expect(entry.copyWith(caption: 'Elsewhere'), isNot(entry));
      expect(
        entry.copyWith(values: entry.values.reversed.toList()),
        isNot(entry),
      );
    },
  );

  test('copyWith clears the nullable fields only when asked', () {
    final RecordEntry cleared = entry
        .copyWith(templateRowId: 'row-1', exportedAt: at)
        .copyWith(
          clearTemplateRowId: true,
          clearNumber: true,
          clearApproval: true,
          clearExportedAt: true,
        );
    expect(cleared.templateRowId, isNull);
    expect(cleared.number, isNull);
    expect(cleared.approvedAt, isNull);
    expect(cleared.approvedBy, isNull);
    expect(cleared.exportedAt, isNull);
    expect(cleared.name, 'Autoclave');
    expect(entry.copyWith(), entry);
  });

  test('a new record defaults to manual processing and a capture source', () {
    final RecordEntry bare = RecordEntry(
      id: 'record-2',
      projectId: 'project-1',
      templateId: 'template-1',
      status: RecordStatus.draft,
      capturedAt: at,
      capturedBy: 'device-1',
      updatedAt: at,
    );
    expect(bare.processingMode, 'manual');
    expect(bare.source, 'capture');
    expect(bare.values, isEmpty);
    expect(bare.photos, isEmpty);
    expect(bare.context, isEmpty);
    expect(bare.number, isNull);
  });

  test('toString names the record and never its values', () {
    expect(entry.toString(), 'RecordEntry(record-1, approved)');
  });
}
