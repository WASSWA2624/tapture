import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/feedback/feedback.dart';

import '../../../support/factories.dart';

void main() {
  late FeedbackRepositoryImpl repo;

  setUp(() {
    repo = FeedbackRepositoryImpl.memory(
      clock: FixedClock(DateTime.utc(2026, 9, 18, 7, 2)),
    );
  });

  test('add is visible on watch', () async {
    _ok(
      await repo.add(
        category: FeedbackCategory.general,
        message: 'Slow list',
        context: aFeedbackEntry().context,
      ),
    );
    final List<FeedbackEntry> rows = await repo.watch().first;
    expect(rows.single.message, 'Slow list');
    expect(rows.single.reference, 'FBK0000001');
  });

  test('an empty message is a ValidationFailure', () async {
    final Result<FeedbackEntry> created = await repo.add(
      category: FeedbackCategory.general,
      message: '  ',
      context: aFeedbackEntry().context,
    );
    expect(_failure(created), isA<ValidationFailure>());
    expect(_failure(created).message, isNotEmpty);
    expect(_failure(created).recoveryAction, isNotEmpty);
  });

  test('other without a name is a ValidationFailure', () async {
    final Result<FeedbackEntry> created = await repo.add(
      category: FeedbackCategory.other,
      message: 'Something else',
      context: aFeedbackEntry().context,
    );
    expect(_failure(created), isA<ValidationFailure>());
  });

  test('watch emits after add', () async {
    final Completer<List<FeedbackEntry>> first =
        Completer<List<FeedbackEntry>>();
    final Completer<List<FeedbackEntry>> second =
        Completer<List<FeedbackEntry>>();
    final StreamSubscription<List<FeedbackEntry>> sub = repo.watch().listen((
      List<FeedbackEntry> rows,
    ) {
      if (!first.isCompleted) {
        first.complete(rows);
        return;
      }
      if (!second.isCompleted) {
        second.complete(rows);
      }
    });
    addTearDown(sub.cancel);
    expect(await first.future, isEmpty);
    _ok(
      await repo.add(
        category: FeedbackCategory.improvement,
        message: 'Make it faster',
        context: aFeedbackEntry().context,
      ),
    );
    expect((await second.future).single.message, 'Make it faster');
  });
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
