import 'processing_job.dart';

/// A failed job with its record's display name and per-project number.
typedef QueueFailure = ({ProcessingJob job, String name, int? number});
