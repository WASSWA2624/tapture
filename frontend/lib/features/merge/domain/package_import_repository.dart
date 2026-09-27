import 'package:tapture/core/bundle/inspected_bundle.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/quality/quality.dart';

import 'conflict_choice.dart';
import 'merge_plan.dart';
import 'package_presence.dart';

/// Brings an inspected project package onto this device (task 076, W19 and
/// W21): as a new project, or merged into one already here. Every write is
/// all or nothing (FE-STATE-07); Drift stops at the data layer.
abstract interface class PackageImportRepository {
  /// Whether the project [projectId] is here, and live.
  Future<Result<PackagePresence>> presenceOf(String projectId);

  /// What a merge into [projectId] is planned against: its rows as a package
  /// carries them, the ids of [incoming]'s rows this device holds in other
  /// projects, and the conflicts a person already settled by keeping this
  /// device's value.
  Future<Result<MergeGround>> groundFor({
    required String projectId,
    required Map<String, List<Map<String, Object?>>> incoming,
  });

  /// The templates and template fields of [projectId], by SQL table, for
  /// checking a package against it without reading the whole project.
  Future<Result<Map<String, List<Map<String, Object?>>>>> templatesOf(
    String projectId,
  );

  /// Imports [bundle] as the project it carries, keeping every id, `rev`,
  /// timestamp and device. [onProgress] reports 0–1 over the files.
  Future<Result<ImportedProject>> importAsNew(
    InspectedBundle bundle, {
    void Function(double progress)? onProgress,
  });

  /// Applies [plan] to [projectId]: the rows, the files, each conflict as
  /// [choices] settle it, and each of [duplicates] as a stored pair, with
  /// those in [skipped] resolved as not imported. [chooser] names who
  /// decided, for the audit.
  Future<Result<MergeOutcome>> merge({
    required InspectedBundle bundle,
    required String projectId,
    required MergePlan plan,
    required Map<String, ConflictChoice> choices,
    required List<PossibleDuplicate> duplicates,
    required Set<String> skipped,
    required String chooser,
    void Function(double progress)? onProgress,
  });
}

/// A merge's starting point: the target project's rows by SQL table, the
/// incoming ids held elsewhere here by table, and the settled conflicts as
/// `<conflict id>|<incoming value>`.
typedef MergeGround = ({
  Map<String, List<Map<String, Object?>>> local,
  Map<String, Set<String>> elsewhere,
  Set<String> decided,
});

/// A project imported whole: its id and how many records it holds.
typedef ImportedProject = ({String projectId, int records});

/// A merge applied: its session and the records it brought.
typedef MergeOutcome = ({String sessionId, int records});
