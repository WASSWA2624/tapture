import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../processing.dart';

/// Live queue snapshot. Counts come from the repository query.
final StreamProvider<QueueSnapshot> queueSnapshotProvider =
    StreamProvider<QueueSnapshot>((Ref ref) {
      return ref.watch(processingRepositoryProvider).watchQueue();
    });
