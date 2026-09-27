import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/processing/processing.dart'
    show processingRepositoryProvider;
import 'package:tapture/features/records/presentation/record_photos_editor_controller.dart';

import '../../../support/fakes/fake_processing_repository.dart';
import '../fakes/record_results.dart';

const ValidationFailure _running = ValidationFailure(
  message: 'This record is being processed now.',
  recoveryAction: 'Wait for the run to finish, then try again.',
);

void main() {
  late FakeProcessingRepository processing;
  late ProviderContainer container;

  setUp(() {
    processing = FakeProcessingRepository();
    container = ProviderContainer(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        processingRepositoryProvider.overrideWith((Ref _) => processing),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    processing.dispose();
  });

  /// Watches the controller as a record page would, recording every state.
  List<bool> watch() {
    final List<bool> seen = <bool>[];
    final ProviderSubscription<bool> subscription = container.listen<bool>(
      recordPhotosEditorControllerProvider,
      (bool? _, bool next) => seen.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    return seen;
  }

  RecordPhotosEditorController controller() {
    return container.read(recordPhotosEditorControllerProvider.notifier);
  }

  test('processing again puts the record back in the queue and reports the '
      'job, busy only while it runs', () async {
    processing.recordStatuses['r1'] = RecordStatus.needsReview;
    final List<bool> seen = watch();

    final Result<String> queued = await controller().processAgain('r1');

    expect(okOf(queued), isNotEmpty);
    expect(processing.requeued, <String>['r1']);
    expect(processing.recordStatuses['r1'], RecordStatus.queued);
    expect(seen, <bool>[false, true, false]);
  });

  test(
    'a record the queue refuses comes back as the failure, unqueued',
    () async {
      processing.requeueFailures['r1'] = _running;
      final List<bool> seen = watch();

      final Result<String> queued = await controller().processAgain('r1');

      expect(failureOf(queued), _running);
      expect(processing.requeued, isEmpty);
      expect(seen.last, isFalse);
    },
  );

  test('a deleted record cannot be queued again', () async {
    processing.recordStatuses['r1'] = RecordStatus.deleted;
    watch();

    final Result<String> queued = await controller().processAgain('r1');

    expect(failureOf(queued), isA<ValidationFailure>());
    expect(processing.recordStatuses['r1'], RecordStatus.deleted);
  });

  test('a request still reaches the queue after the page that asked has '
      'closed', () async {
    final RecordPhotosEditorController kept = controller();
    // Nothing watches the controller any more, so it is disposed.
    await container.pump();

    final Result<String> queued = await kept.processAgain('r1');

    expect(okOf(queued), isNotEmpty);
    expect(processing.requeued, <String>['r1']);
  });
}
