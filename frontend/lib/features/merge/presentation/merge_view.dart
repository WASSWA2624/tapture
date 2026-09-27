import 'package:tapture/core/bundle/inspected_bundle.dart';
import 'package:tapture/features/quality/quality.dart';

import '../domain/compatibility_report.dart';
import '../domain/conflict_choice.dart';
import '../domain/field_conflict.dart';
import '../domain/merge_plan.dart';

/// What the merge preview shows and the person has chosen so far (task
/// 076, W20 to W22). Nothing here is written until [MergePlan] is applied.
final class MergeView {
  /// Creates a view.
  const MergeView({
    required this.bundle,
    required this.report,
    required this.plan,
    required this.local,
    this.choices = const <String, ConflictChoice>{},
    this.checkDuplicates = true,
    this.duplicates = const <PossibleDuplicate>[],
    this.skipped = const <String>{},
    this.applying = false,
    this.progress = 0,
  });

  /// The package being merged.
  final InspectedBundle bundle;

  /// Whether its templates fit this project's.
  final CompatibilityReport report;

  /// What the merge would do.
  final MergePlan plan;

  /// The target project's rows, for labelling records.
  final Map<String, List<Map<String, Object?>>> local;

  /// Each settled conflict's choice, by [FieldConflict.id].
  final Map<String, ConflictChoice> choices;

  /// Whether incoming records are checked for possible duplicates.
  final bool checkDuplicates;

  /// Incoming records that look like ones already here.
  final List<PossibleDuplicate> duplicates;

  /// Incoming records a person chose not to import.
  final Set<String> skipped;

  /// Whether the merge is being written.
  final bool applying;

  /// How far the write has gone, 0–1.
  final double progress;

  /// Conflicts still waiting for a choice.
  List<FieldConflict> get unsettled => <FieldConflict>[
    for (final FieldConflict conflict in plan.conflicts)
      if (!choices.containsKey(conflict.id)) conflict,
  ];

  /// A copy with the given parts replaced.
  MergeView copyWith({
    CompatibilityReport? report,
    MergePlan? plan,
    Map<String, ConflictChoice>? choices,
    bool? checkDuplicates,
    List<PossibleDuplicate>? duplicates,
    Set<String>? skipped,
    bool? applying,
    double? progress,
  }) {
    return MergeView(
      bundle: bundle,
      report: report ?? this.report,
      plan: plan ?? this.plan,
      local: local,
      choices: choices ?? this.choices,
      checkDuplicates: checkDuplicates ?? this.checkDuplicates,
      duplicates: duplicates ?? this.duplicates,
      skipped: skipped ?? this.skipped,
      applying: applying ?? this.applying,
      progress: progress ?? this.progress,
    );
  }
}
