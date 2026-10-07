import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/features/capture/capture.dart' show photoRepositoryProvider, captureDocumentRepositoryProvider;
import 'package:tapture/features/projects/projects.dart' show projectRepositoryProvider;

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

final _deletedProjectsProvider = StreamProvider.autoDispose<List<DeletedEntity>>((Ref ref) => ref.watch(projectRepositoryProvider).watchDeleted());
final _deletedPhotosProvider = StreamProvider.autoDispose<List<DeletedEntity>>((Ref ref) => ref.watch(photoRepositoryProvider).watchDeleted());
final _deletedAttachmentsProvider = StreamProvider.autoDispose<List<DeletedEntity>>((Ref ref) => ref.watch(captureDocumentRepositoryProvider)?.watchDeleted() ?? Stream<List<DeletedEntity>>.value(const <DeletedEntity>[]));

/// Current repository projections, sorted together without duplicate children.
final deletedEntitiesProvider = Provider.autoDispose<AsyncValue<List<DeletedEntity>>>((Ref ref) {
  final AsyncValue<List<DeletedRecord>> records = ref.watch(recycleBinProvider);
  final List<AsyncValue<List<DeletedEntity>>> sources = <AsyncValue<List<DeletedEntity>>>[
    ref.watch(_deletedProjectsProvider), ref.watch(_deletedPhotosProvider), ref.watch(_deletedAttachmentsProvider),
  ];
  if (records.hasError) return AsyncError<List<DeletedEntity>>(records.error!, records.stackTrace!);
  for (final AsyncValue<List<DeletedEntity>> source in sources) {
    if (source.hasError) return AsyncError<List<DeletedEntity>>(source.error!, source.stackTrace!);
  }
  if (!records.hasValue || sources.any((AsyncValue<List<DeletedEntity>> source) => !source.hasValue)) return const AsyncLoading<List<DeletedEntity>>();
  final List<DeletedEntity> all = <DeletedEntity>[
    for (final DeletedRecord record in records.requireValue) DeletedEntity(id: record.id, kind: DeletedEntityKind.record,
      name: record.summary.name, projectId: record.summary.projectId, projectName: record.projectName, deletedAt: record.deletedAt, reason: record.reason),
    for (final AsyncValue<List<DeletedEntity>> source in sources) ...source.requireValue,
  ];
  final Set<String> deletedProjects = all.where((DeletedEntity row) => row.kind == DeletedEntityKind.project).map((DeletedEntity row) => row.id).toSet();
  all.removeWhere((DeletedEntity row) => row.kind != DeletedEntityKind.project && deletedProjects.contains(row.projectId));
  all.sort((DeletedEntity a, DeletedEntity b) {
    final int byDate = b.deletedAt.compareTo(a.deletedAt);
    return byDate != 0 ? byDate : a.key.compareTo(b.key);
  });
  return AsyncData<List<DeletedEntity>>(List<DeletedEntity>.unmodifiable(all));
});

/// What the recycle bin is doing: the records being restored and whether it
/// is being emptied. Auto-dispose: the recycle bin page is its only reader
/// (FE-STATE-09).
final recycleBinControllerProvider =
    NotifierProvider.autoDispose<RecycleBinController, RecycleBinActivity>(
      RecycleBinController.new,
    );

/// Restores records from the recycle bin and empties it (task 014 step 7,
/// D12, D13).
///
/// A restore brings one record back whole, to the status it had before it
/// was deleted. Emptying runs the retention purge with the window ignored:
/// every record in the bin goes for good with its files, except one a merge
/// still needs, and each record is purged on its own so one failure does not
/// stop the rest.
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
    if (state.restoring.contains(id)) {
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
    if (entity.kind == DeletedEntityKind.record) return restore(entity.id);
    if (state.restoring.contains(entity.key)) return FailureResult<void>(_restoring);
    _set(restoring: <String>{...state.restoring, entity.key});
    try {
      return await switch (entity.kind) {
        DeletedEntityKind.project => ref.read(projectRepositoryProvider).restore(entity.id),
        DeletedEntityKind.photo => ref.read(photoRepositoryProvider).restore(entity.id),
        DeletedEntityKind.document || DeletedEntityKind.audio => ref.read(captureDocumentRepositoryProvider)?.restore(entity.id) ?? Future<Result<void>>.value(FailureResult<void>(_unavailable)),
        DeletedEntityKind.record => restore(entity.id),
      };
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
    } finally {
      if (ref.mounted) _set(restoring: <String>{...state.restoring}..remove(entity.key));
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
