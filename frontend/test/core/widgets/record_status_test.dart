import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/record_status.dart';

void main() {
  test('the status set is the ten statuses of the records contract', () {
    expect(
      RecordStatus.values.map((RecordStatus status) => status.name),
      <String>[
        'draft',
        'captured',
        'queued',
        'processing',
        'extracted',
        'needsReview',
        'approved',
        'failed',
        'archived',
        'deleted',
      ],
    );
  });

  test('every status is stored as its name and reads back as itself', () {
    for (final RecordStatus status in RecordStatus.values) {
      expect(status.stored, status.name);
      expect(RecordStatus.fromStored(status.stored), status);
    }
  });

  test('legacy spellings fold case and underscores into one status', () {
    expect(RecordStatus.fromStored('NEEDS_REVIEW'), RecordStatus.needsReview);
    expect(RecordStatus.fromStored('needs_review'), RecordStatus.needsReview);
    expect(RecordStatus.fromStored('needsreview'), RecordStatus.needsReview);
    expect(RecordStatus.fromStored('CAPTURED'), RecordStatus.captured);
    expect(RecordStatus.fromStored('EXTRACTED'), RecordStatus.extracted);
    expect(RecordStatus.fromStored('Approved'), RecordStatus.approved);
    expect(RecordStatus.fromStored('ARCHIVED'), RecordStatus.archived);
  });

  test('a spelling that names no status reads as null', () {
    expect(RecordStatus.fromStored(''), isNull);
    expect(RecordStatus.fromStored('exported'), isNull);
    expect(RecordStatus.fromStored('needs review'), isNull);
    expect(RecordStatus.fromStored('pending'), isNull);
  });
}
