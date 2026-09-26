import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/processing/domain/job_queue.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

import '../../../support/fakes/fake_processing_repository.dart';

void main() {
  test('the queue enqueues once, claims once and completes', () async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    final JobQueue queue = JobQueue.over(repository);

    final String id = await queue.enqueue('record-1');
    expect(await queue.enqueue('record-1'), id);

    final ProcessingJob? claimed = await queue.claim(
      const Duration(minutes: 5),
    );
    expect(claimed?.id, id);
    expect(claimed?.status, JobStatus.running);
    expect(
      await queue.claim(const Duration(minutes: 5)),
      isNull,
      reason: 'a claimed job is not handed out twice',
    );

    await queue.complete(id);
    expect(repository.stored.single.status, JobStatus.completed);
  });

  test('an expired lease makes the job claimable again', () async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    final JobQueue queue = JobQueue.over(repository);
    final String id = await queue.enqueue('record-1');

    // A lease already over, as when the app was killed mid-job.
    final ProcessingJob? first = await queue.claim(Duration.zero);
    expect(first?.id, id);
    final ProcessingJob? again = await queue.claim(const Duration(minutes: 5));
    expect(again?.id, id);
  });

  test('a permanent failure stops and a storage failure is thrown', () async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    final JobQueue queue = JobQueue.over(repository);
    final String id = await queue.enqueue('record-1');
    await queue.claim(const Duration(minutes: 5));

    await queue.fail(id, 'The key was rejected.', permanent: true);
    final ProcessingJob stopped = repository.stored.single;
    expect(stopped.status, JobStatus.failed);
    expect(stopped.lastError, 'The key was rejected.');

    await expectLater(queue.complete('missing'), throwsA(isA<Failure>()));
  });
}
