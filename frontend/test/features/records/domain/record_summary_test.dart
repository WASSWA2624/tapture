import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/record_flag.dart';
import 'package:tapture/features/records/domain/record_photo.dart';
import 'package:tapture/features/records/domain/record_summary.dart';

void main() {
  final DateTime at = DateTime.utc(2026, 9, 17, 8);
  final RecordSummary row = RecordSummary(
    id: 'record-1',
    projectId: 'project-1',
    templateId: 'template-1',
    status: RecordStatus.approved,
    capturedAt: at,
    number: 124,
    name: 'Autoclave',
    identifier: 'SN458923',
    contextLabel: 'Theatre',
    thumb: const RecordPhoto(id: 'photo-1', sha256: 'abc', storagePath: 'p'),
    photoCount: 2,
    flags: const <RecordFlag>{RecordFlag.hasPhotos},
  );

  test('a row carries number, name, identifier, context and status', () {
    expect(row.number, 124);
    expect(row.name, 'Autoclave');
    expect(row.identifier, 'SN458923');
    expect(row.contextLabel, 'Theatre');
    expect(row.status, RecordStatus.approved);
    expect(row.has(RecordFlag.hasPhotos), isTrue);
    expect(row.has(RecordFlag.hasDuplicate), isFalse);
  });

  test('a bare row has no number, name, thumbnail or flags', () {
    final RecordSummary bare = RecordSummary(
      id: 'record-2',
      projectId: 'project-1',
      templateId: 'template-1',
      status: RecordStatus.draft,
      capturedAt: at,
    );
    expect(bare.number, isNull);
    expect(bare.name, isEmpty);
    expect(bare.thumb, isNull);
    expect(bare.photoCount, 0);
    expect(bare.flags, isEmpty);
  });

  test('rows with the same fields are equal, flags in any order', () {
    final RecordSummary same = row.copyWith(
      flags: <RecordFlag>{RecordFlag.hasPhotos},
    );
    expect(row, same);
    expect(row.hashCode, same.hashCode);
    final RecordSummary twoFlags = row.copyWith(
      flags: <RecordFlag>{RecordFlag.hasConflict, RecordFlag.hasPhotos},
    );
    expect(
      twoFlags,
      row.copyWith(
        flags: <RecordFlag>{RecordFlag.hasPhotos, RecordFlag.hasConflict},
      ),
    );
    expect(twoFlags, isNot(row));
  });

  test('copyWith replaces and clears only what it is given', () {
    expect(row.copyWith(), row);
    expect(row.copyWith(status: RecordStatus.needsReview).name, 'Autoclave');
    final RecordSummary cleared = row.copyWith(
      clearNumber: true,
      clearThumb: true,
    );
    expect(cleared.number, isNull);
    expect(cleared.thumb, isNull);
    expect(cleared.photoCount, 2);
  });

  test('toString names the record and its status, never its name', () {
    expect(row.toString(), 'RecordSummary(record-1, approved)');
  });
}
