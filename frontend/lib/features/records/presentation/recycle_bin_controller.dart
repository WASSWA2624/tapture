import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/features/capture/capture.dart'
    show photoRepositoryProvider, captureDocumentRepositoryProvider;
import 'package:tapture/features/projects/projects.dart'
    show projectRepositoryProvider;

import '../domain/deleted_record.dart';
import '../domain/purge_job.dart';
import '../domain/purge_report.dart';
import '../domain/record_repository.dart';
import '../records.dart' show recordRepositoryProvider;
import 'record_providers.dart';

/// Every record in the recycle bin, across projects, newest deletion first,
/// kept current. Records removed with their project are not listed.
/// Auto-dispose: only the open recycle bin reads it (FE-STATE-09).
final recycleBinProvider = StreamProvider.autoDispose<List<DeletedRecord>>((
  Ref ref,
) {
  return ref.watch(recordRepositoryProvider).watchBin();
}, retry: (int _, Object _) => null);

final _deletedProjectsProvider =
    StreamProvider.autoDispose<List<DeletedEntity>>(
      (Ref ref) => ref.watch(projectRepositoryProvider).watchDeleted(),
    );
final _deletedPhotosProvider = StreamProvider.autoDispose<List<DeletedEntity>>(
  (Ref ref) => ref.watch(photoRepositoryProvider).watchDeleted(),
);
final _deletedAttachmentsProvider =
    StreamProvider.autoDispose<List<DeletedEntity>>(
      (Ref ref) =>
          ref.watch(captureDocumentRepositoryProvider)?.watchDeleted() ??
          Stream<List<DeletedEntity>>.value(const <DeletedEntity>[]),
    );

/// Current repository projections, sorted together without duplicate children.
final deletedEntitiesProvider =
    Provider.autoDispose<AsyncValue<List<DeletedEntity>>>((Ref ref) {
      final AsyncValue<List<DeletedRecord>> records = ref.watch(
        recycleBinProvider,
      );
      final List<AsyncValue<List<DeletedEntity>>> sources =
          <AsyncValue<List<DeletedEntity>>>[
            ref.watch(_deletedProjectsProvider),
            ref.watch(_deletedPhotosProvider),
            ref.watch(_deletedAttachmentsProvider),
          ];
      if (records.hasError) {
        return AsyncError<List<DeletedEntity>>(
          records.error!,
          records.stackTrace!,
        );
      }
      for (final AsyncValue<List<DeletedEntity>> source in sources) {
        if (source.hasError) {
          return AsyncError<List<DeletedEntity>>(
            source.error!,
            source.stackTrace!,
          );
        }
      }
      if (!records.hasValue ||
          sources.any(
            (AsyncValue<List<DeletedEntity>> source) => !source.hasValue,
          )) {
        return const AsyncLoading<List<DeletedEntity>>();
      }
      final List<DeletedEntity> all = <DeletedEntity>[
        for (final DeletedRecord record in records.requireValue)
          DeletedEntity(
            id: record.id,
            kind: DeletedEntityKind.record,
            name: record.summary.name,
            projectId: record.summary.projectId,
            projectName: record.projectName,
            deletedAt: record.deletedAt,
            deletionId: record.deletionId,
            reason: record.reason,
          ),
        for (final AsyncValue<List<DeletedEntity>> source in sources)
          ...source.requireValue,
      ];
      final Set<String> deletedProjects = all
          .where((DeletedEntity row) => row.kind == DeletedEntityKind.project)
          .map((DeletedEntity row) => row.id)
          .toSet();
      all.removeWhere(
        (DeletedEntity row) =>
            row.kind != DeletedEntityKind.project &&
            deletedProjects.contains(row.projectId),
      );
      all.sort((DeletedEntity a, DeletedEntity b) {
        final int byDate = b.deletedAt.compareTo(a.deletedAt);
        return byDate != 0 ? byDate : a.key.compareTo(b.key);
      });
      return AsyncData<List<DeletedEntity>>(
        List<DeletedEntity>.unmodifiable(all),
      );
    });

/// What the recycle bin is doing: the records being restored and whether it
/// is being emptied. Auto-dispose: the recycle bin page is its only reader
/// (FE-STATE-09).
final recycleBinControllerProvider =
    NotifierProvider.autoDispose<RecycleBinController, RecycleBinActivity>(
      RecycleBinController.new,
    );

/// Restores and permanently removes a captured set of managed deleted items.
/// Each durable operation reports independently so a failure does not stop the
/// remaining selection. The legacy retention action retains its merge policy.
final class RecycleBinController extends Notifier<RecycleBinActivity> {
  /// Creates the controller.
  RecycleBinController();

  /// Nothing restoring and nothing emptying.
  static const RecycleBinActivity idle = (
    restoring: <String>{},
    emptying: false,
  );

  @override
  RecycleBinActivity build() => idle;

  /// Reopens every repository watch after a failed read.
  void refresh() {
    ref.invalidate(recycleBinProvider);
    ref.invalidate(_deletedProjectsProvider);
    ref.invalidate(_deletedPhotosProvider);
    ref.invalidate(_deletedAttachmentsProvider);
  }

  /// Whether record [id] is being restored now.
  bool isRestoring(String id) => state.restoring.contains(id);

  /// Brings record [id] back from the recycle bin, to the status it had
  /// before it was deleted, and says why when it cannot.
  Future<Result<void>> restore(String id) async {
    if (state.emptying || state.restoring.contains(id)) {
      return FailureResult<void>(_restoring);
    }
    final RecordRepository records = ref.read(recordRepositoryProvider);
    _set(restoring: <String>{...state.restoring, id});
    try {
      return await records.restore(id);
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
    } finally {
      if (ref.mounted) {
        _set(restoring: <String>{...state.restoring}..remove(id));
      }
    }
  }

  /// Routes a restoration intent to the repository that owns the entity.
  Future<Result<void>> restoreEntity(DeletedEntity entity) async {
    if (state.emptying) {
      return FailureResult<void>(_emptying);
    }
    if (entity.kind == DeletedEntityKind.record) {
      return restore(entity.id);
    }
    if (state.restoring.contains(entity.key)) {
      return FailureResult<void>(_restoring);
    }
    _set(restoring: <String>{...state.restoring, entity.key});
    try {
      return await switch (entity.kind) {
        DeletedEntityKind.project =>
          ref.read(projectRepositoryProvider).restore(entity.id),
        DeletedEntityKind.photo =>
          ref.read(photoRepositoryProvider).restore(entity.id),
        DeletedEntityKind.document || DeletedEntityKind.audio =>
          ref.read(captureDocumentRepositoryProvider)?.restore(entity.id) ??
              Future<Result<void>>.value(FailureResult<void>(_unavailable)),
        DeletedEntityKind.record => restore(entity.id),
      };
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
    } finally {
      if (ref.mounted) {
        _set(restoring: <String>{...state.restoring}..remove(entity.key));
      }
    }
  }

  /// Applies one captured, deduplicated selection without stopping at a failure.
  /// Keeping the provider alive lets an in-flight operation finish off-screen.
  Future<RecycleBinResult> apply(
    List<DeletedEntity> entities, {
    required bool permanently,
  }) async {
    final Map<String, DeletedEntity> snapshot = <String, DeletedEntity>{
      for (final DeletedEntity entity in entities) entity.key: entity,
    };
    if (state.emptying || state.restoring.isNotEmpty) {
      return (
        succeeded: 0,
        failed: <String, Failure>{
          for (final String key in snapshot.keys) key: _emptying,
        },
      );
    }
    final link = ref.keepAlive();
    final RecyclePurge? purge = ref.read(recyclePurgeProvider);
    final records = ref.read(recordRepositoryProvider);
    final projects = ref.read(projectRepositoryProvider);
    final photos = ref.read(photoRepositoryProvider);
    final documents = ref.read(captureDocumentRepositoryProvider);
    _set(emptying: true);
    int succeeded = 0;
    final Map<String, Failure> failed = <String, Failure>{};
    try {
      for (final DeletedEntity entity in snapshot.values) {
        final Result<void> result;
        try {
          result = permanently
              ? await (purge?.call(entity) ??
                    Future<Result<void>>.value(
                      FailureResult<void>(_unavailable),
                    ))
              : await switch (entity.kind) {
                  DeletedEntityKind.project => projects.restore(entity.id),
                  DeletedEntityKind.record => records.restore(entity.id),
                  DeletedEntityKind.photo => photos.restore(entity.id),
                  DeletedEntityKind.document || DeletedEntityKind.audio =>
                    documents?.restore(entity.id) ??
                        Future<Result<void>>.value(
                          FailureResult<void>(_unavailable),
                        ),
                };
        } on Object catch (error) {
          failed[entity.key] = Failure.from(error);
          continue;
        }
        switch (result) {
          case Success<void>():
            succeeded++;
          case FailureResult<void>(:final failure):
            failed[entity.key] = failure;
        }
      }
      return (
        succeeded: succeeded,
        failed: Map<String, Failure>.unmodifiable(failed),
      );
    } finally {
      if (ref.mounted) {
        _set(emptying: false);
      }
      link.close();
    }
  }

  /// Removes every record in the recycle bin for good, with its files and
  /// cached thumbnails, now rather than when its days run out. A record a
  /// merge still needs is kept, and a record that fails stays for the next
  /// try; the report counts both.
  Future<Result<PurgeReport>> emptyNow() async {
    final PurgeJob? job = ref.read(recordPurgeJobProvider);
    if (job == null) {
      return FailureResult<PurgeReport>(_unavailable);
    }
    if (state.emptying) {
      return FailureResult<PurgeReport>(_emptying);
    }
    _set(emptying: true);
    try {
      return await job.run(ignoreWindow: true);
    } on Object catch (error) {
      return FailureResult<PurgeReport>(Failure.from(error));
    } finally {
      if (ref.mounted) {
        _set(emptying: false);
      }
    }
  }

  void _set({Set<String>? restoring, bool? emptying}) {
    state = (
      restoring: Set<String>.unmodifiable(restoring ?? state.restoring),
      emptying: emptying ?? state.emptying,
    );
  }
}

/// The explicit permanent-deletion adapter; previews cannot purge real data.
typedef RecyclePurge = Future<Result<void>> Function(DeletedEntity entity);
final Provider<RecyclePurge?> recyclePurgeProvider = Provider<RecyclePurge?>(
  (Ref _) => null,
);

/// Counts successes while retaining actionable failures by stable entity key.
typedef RecycleBinResult = ({int succeeded, Map<String, Failure> failed});

/// What the recycle bin is doing: the ids of the records being restored,
/// and whether it is being emptied.
typedef RecycleBinActivity = ({Set<String> restoring, bool emptying});

final ValidationFailure _restoring = ValidationFailure(
  message: Copy.recycleBinRestoring,
  recoveryAction: Copy.recycleBinRestoringAction,
);

final ValidationFailure _unavailable = ValidationFailure(
  message: Copy.recycleBinEmptyUnavailable,
  recoveryAction: Copy.recycleBinEmptyUnavailableAction,
);

final ValidationFailure _emptying = ValidationFailure(
  message: Copy.recycleBinEmptying,
  recoveryAction: Copy.recycleBinEmptyingAction,
);
