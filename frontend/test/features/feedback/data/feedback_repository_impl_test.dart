import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/feedback/data/feedback_repository_impl.dart';
import 'package:tapture/features/feedback/domain/feedback_category.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/domain/removed_feedback.dart';

import '../../../support/factories.dart';

void main() {
  test('a screenshot is stored and numbering is never reused', () async {
    final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
      clock: FixedClock(DateTime.utc(2026, 9, 18, 7, 2)),
    );
    final FeedbackEntry first = _ok(
      await repo.add(
        category: FeedbackCategory.general,
        message: 'One',
        context: aFeedbackEntry().context,
        screenshot: aFeedbackPng,
      ),
    );
    expect(first.hasScreenshot, isTrue);
    expect(first.number, 1);
    expect(_ok(await repo.screenshot(first.id)), aFeedbackPng);

    _ok(await repo.remove(<String>{first.id}));
    final FeedbackEntry second = _ok(
      await repo.add(
        category: FeedbackCategory.suggestion,
        message: 'Two',
        context: aFeedbackEntry().context,
      ),
    );
    expect(second.number, 2);
    expect(second.reference, 'FBK0000002');
  });

  test('restore puts a deleted entry and its screenshot back', () async {
    final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
      clock: FixedClock(DateTime.utc(2026, 9, 18, 7, 2)),
    );
    final FeedbackEntry saved = _ok(
      await repo.add(
        category: FeedbackCategory.general,
        message: 'Keep me',
        context: aFeedbackEntry().context,
        screenshot: aFeedbackPng,
      ),
    );
    final List<RemovedFeedback> removed = _ok(
      await repo.remove(<String>{saved.id}),
    );
    expect(await repo.watch().first, isEmpty);

    _ok(await repo.restore(removed));
    final List<FeedbackEntry> rows = await repo.watch().first;
    expect(rows.single.message, 'Keep me');
    expect(_ok(await repo.screenshot(saved.id)), aFeedbackPng);
  });

  test(
    'a damaged row is skipped and a failed write is a StorageFailure',
    () async {
      final Map<String, Uint8List> backing = <String, Uint8List>{
        'index.json': Uint8List.fromList(
          utf8.encode(
            jsonEncode(<String, Object?>{
              'next_number': 3,
              'entries': <Object?>[
                aFeedbackEntry(id: 'fb-ok', number: 2).toJson(),
                <String, Object?>{'id': ''},
              ],
            }),
          ),
        ),
      };
      final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
        clock: FixedClock(DateTime.utc(2026, 9, 18, 7, 2)),
        backing: backing,
      );
      final List<FeedbackEntry> rows = await repo.watch().first;
      expect(rows.single.id, 'fb-ok');

      final FeedbackRepositoryImpl failing = FeedbackRepositoryImpl.memory(
        clock: FixedClock(DateTime.utc(2026, 9, 18, 7, 2)),
        failWrites: true,
      );
      final Result<FeedbackEntry> written = await failing.add(
        category: FeedbackCategory.general,
        message: 'Nope',
        context: aFeedbackEntry().context,
      );
      expect(_failure(written), isA<StorageFailure>());
    },
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
    FailureResult<T>(:final Failure failure) => failure,
    Success<T>() => throw TestFailure('expected a failure'),
  };
}
