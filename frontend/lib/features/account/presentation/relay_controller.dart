import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/backend/relay_queue.dart';
import 'package:tapture/core/backend/relay_snapshot.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/projects.dart';

/// The app injects durable storage and an authenticated transport once.
final relayQueueProvider = Provider<RelayQueue?>((Ref _) => null);

/// Reuses the product's package writer; no parallel export path exists.
final relayPackageProvider =
    Provider<Future<Result<Uint8List>> Function(String projectId)?>(
      (Ref _) => null,
    );

/// Local relay state loads even without a network connection.
final relaySnapshotProvider = FutureProvider.autoDispose<RelaySnapshot?>((
  Ref ref,
) async {
  final String? projectId = ref.watch(currentProjectProvider);
  final RelayQueue? queue = ref.watch(relayQueueProvider);
  if (projectId == null || queue == null) return null;
  final Result<RelaySnapshot> result = await queue.snapshot(projectId);
  return switch (result) {
    Success<RelaySnapshot>(:final value) => value,
    FailureResult<RelaySnapshot>(:final failure) => throw failure,
  };
});

/// Keeps the control state separate from the durable outbox.
final class RelayController extends Notifier<RelayActionState> {
  @override
  RelayActionState build() => (busy: false, failure: null);

  /// Runs one relay intent and refreshes its local snapshot after persistence.
  Future<void> run(
    Future<Result<void>> Function(RelayQueue queue, String projectId) work,
  ) async {
    if (state.busy) return;
    final RelayQueue? queue = ref.read(relayQueueProvider);
    final String? id = ref.read(currentProjectProvider);
    if (queue == null || id == null) return;
    state = (busy: true, failure: null);
    try {
      final Result<void> result = await work(queue, id);
      if (!ref.mounted) return;
      ref.invalidate(relaySnapshotProvider);
      state = (
        busy: false,
        failure: result is FailureResult<void> ? result.failure : null,
      );
    } on Object catch (error) {
      if (ref.mounted) state = (busy: false, failure: Failure.from(error));
    }
  }

  /// Builds through ExportRepository, then persists only an encrypted derivative.
  Future<void> queueProject() => run((RelayQueue queue, String id) async {
    final package = ref.read(relayPackageProvider);
    if (package == null) return const FailureResult<void>(StorageFailure());
    final Result<Uint8List> result = await package(id);
    return switch (result) {
      Success<Uint8List>(:final value) => queue.enqueue(id, value),
      FailureResult<Uint8List>(:final failure) => FailureResult<void>(failure),
    };
  });
}

/// Whether a relay intent is running, and why the last one failed.
typedef RelayActionState = ({bool busy, Failure? failure});

/// Commands live only while the relay screen is open.
final relayControllerProvider =
    NotifierProvider.autoDispose<RelayController, RelayActionState>(
      RelayController.new,
    );
