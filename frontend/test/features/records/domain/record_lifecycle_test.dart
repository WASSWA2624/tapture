import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/record_lifecycle.dart';

import '../fakes/record_results.dart';

// The D4 table, written out by hand so the test does not read the
// implementation's own table back. Short names keep each row on one line.
const RecordStatus _draft = RecordStatus.draft;
const RecordStatus _captured = RecordStatus.captured;
const RecordStatus _queued = RecordStatus.queued;
const RecordStatus _processing = RecordStatus.processing;
const RecordStatus _extracted = RecordStatus.extracted;
const RecordStatus _needsReview = RecordStatus.needsReview;
const RecordStatus _approved = RecordStatus.approved;
const RecordStatus _failed = RecordStatus.failed;
const RecordStatus _archived = RecordStatus.archived;
const RecordStatus _deleted = RecordStatus.deleted;

const Map<RecordStatus, Set<RecordStatus>>
_legal = <RecordStatus, Set<RecordStatus>>{
  _draft: <RecordStatus>{_captured, _queued, _needsReview, _archived, _deleted},
  _captured: <RecordStatus>{
    _queued,
    _processing,
    _extracted,
    _needsReview,
    _failed,
    _archived,
    _deleted,
  },
  _queued: <RecordStatus>{_processing, _captured, _failed, _archived, _deleted},
  _processing: <RecordStatus>{_extracted, _needsReview, _failed, _queued},
  _extracted: <RecordStatus>{
    _needsReview,
    _approved,
    _queued,
    _archived,
    _deleted,
  },
  _needsReview: <RecordStatus>{_approved, _queued, _archived, _deleted},
  _approved: <RecordStatus>{_needsReview, _queued, _archived, _deleted},
  _failed: <RecordStatus>{_queued, _needsReview, _archived, _deleted},
  _archived: <RecordStatus>{
    _draft,
    _captured,
    _queued,
    _extracted,
    _needsReview,
    _approved,
    _failed,
    _deleted,
  },
  _deleted: <RecordStatus>{
    _draft,
    _captured,
    _queued,
    _extracted,
    _needsReview,
    _approved,
    _failed,
    _archived,
  },
};

void main() {
  test('the table names every status as a source', () {
    expect(_legal.keys.toSet(), RecordStatus.values.toSet());
  });

  group('every one of the 100 status pairs', () {
    for (final RecordStatus from in RecordStatus.values) {
      for (final RecordStatus to in RecordStatus.values) {
        final bool legal = _legal[from]!.contains(to);
        test(
          '${from.name} to ${to.name} is ${legal ? 'legal' : 'illegal'}',
          () {
            expect(RecordLifecycle.allows(from, to), legal);
            final Result<void> checked = RecordLifecycle.check(from, to);
            if (legal) {
              expect(checked, isA<Success<void>>());
            } else {
              final Failure failure = failureOf(checked);
              expect(failure, isA<ValidationFailure>());
              expect(failure.message, isNotEmpty);
              expect(failure.recoveryAction, isNotEmpty);
            }
          },
        );
      }
    }
  });

  test('targetsFrom lists exactly the legal targets of each status', () {
    for (final RecordStatus from in RecordStatus.values) {
      expect(
        RecordLifecycle.targetsFrom(from),
        _legal[from],
        reason: from.name,
      );
    }
  });

  test('a move to the same status is refused as already there', () {
    for (final RecordStatus status in RecordStatus.values) {
      final Failure failure = failureOf(RecordLifecycle.check(status, status));
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('already'));
      expect(RecordLifecycle.targetsFrom(status), isNot(contains(status)));
    }
  });

  test('the manual path reaches approved without a processing state', () {
    const List<RecordStatus> path = <RecordStatus>[
      _draft,
      _needsReview,
      _approved,
    ];
    for (int step = 1; step < path.length; step++) {
      expect(
        RecordLifecycle.check(path[step - 1], path[step]),
        isA<Success<void>>(),
      );
    }
    expect(
      path,
      isNot(
        anyOf(contains(_queued), contains(_processing), contains(_extracted)),
      ),
    );
  });

  test('approving a draft directly fails and says to review it first', () {
    final Failure failure = failureOf(RecordLifecycle.check(_draft, _approved));
    expect(failure, isA<ValidationFailure>());
    expect(failure.recoveryAction, contains('review'));
  });

  test('leaving the bin for anywhere but a restore target is refused', () {
    final Failure failure = failureOf(
      RecordLifecycle.check(_deleted, _processing),
    );
    expect(failure.recoveryAction, contains('Restore'));
  });

  test('isRestore is true only for moves out of archived or deleted', () {
    expect(RecordLifecycle.isRestore(_deleted, _approved), isTrue);
    expect(RecordLifecycle.isRestore(_deleted, _archived), isTrue);
    expect(RecordLifecycle.isRestore(_archived, _needsReview), isTrue);
    expect(RecordLifecycle.isRestore(_archived, _deleted), isFalse);
    expect(RecordLifecycle.isRestore(_deleted, _processing), isFalse);
    expect(RecordLifecycle.isRestore(_approved, _needsReview), isFalse);
  });

  test('restoreTarget keeps a legal previous status and else asks review', () {
    expect(RecordLifecycle.restoreTarget(_deleted, _approved), _approved);
    expect(RecordLifecycle.restoreTarget(_deleted, _archived), _archived);
    expect(RecordLifecycle.restoreTarget(_archived, _captured), _captured);
    expect(RecordLifecycle.restoreTarget(_deleted, null), _needsReview);
    expect(RecordLifecycle.restoreTarget(_deleted, _processing), _needsReview);
    expect(RecordLifecycle.restoreTarget(_deleted, _deleted), _needsReview);
  });

  test(
    'an edit sends approved back to review and leaves others as they are',
    () {
      for (final RecordStatus status in RecordStatus.values) {
        expect(
          RecordLifecycle.afterEdit(status),
          status == _approved ? _needsReview : status,
        );
      }
    },
  );

  test('only a deleted record refuses an edit', () {
    for (final RecordStatus status in RecordStatus.values) {
      final Result<void> editable = RecordLifecycle.checkEditable(status);
      if (status == _deleted) {
        expect(failureOf(editable), isA<ValidationFailure>());
        expect(failureOf(editable).recoveryAction, contains('Restore'));
      } else {
        expect(editable, isA<Success<void>>());
      }
    }
  });
}
