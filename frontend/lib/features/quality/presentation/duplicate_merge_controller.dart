import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/duplicate_choice.dart';
import '../domain/duplicate_resolution.dart';

/// The merge a person is deciding for one pair (task 015), keyed by pair.
final duplicateMergeControllerProvider = NotifierProvider.autoDispose
    .family<DuplicateMergeController, DuplicateMergeDraft, String>(
      DuplicateMergeController.new,
    );

/// Holds each field's pick and whether photos move, until the merge runs.
/// A field is never picked on the person's behalf.
final class DuplicateMergeController extends Notifier<DuplicateMergeDraft> {
  /// Creates the draft merge of pair [pairId].
  DuplicateMergeController(this.pairId);

  /// The pair being merged.
  final String pairId;

  @override
  DuplicateMergeDraft build() {
    return (picks: const <String, MergePick>{}, carryPhotos: false);
  }

  /// Picks [pick] for [fieldKey], or clears it when [pick] is null.
  void pick(String fieldKey, MergePick? pick) {
    final Map<String, MergePick> picks = <String, MergePick>{...state.picks};
    if (pick == null) {
      picks.remove(fieldKey);
    } else {
      picks[fieldKey] = pick;
    }
    state = (
      picks: Map<String, MergePick>.unmodifiable(picks),
      carryPhotos: state.carryPhotos,
    );
  }

  /// Sets whether the newer record's photos move onto the survivor.
  void carryPhotos({required bool carry}) {
    state = (picks: state.picks, carryPhotos: carry);
  }

  /// The merge as it stands, ready to apply.
  DuplicateResolution resolution() {
    return DuplicateResolution(
      DuplicateChoice.mergeFields,
      picks: state.picks,
      carryPhotos: state.carryPhotos,
    );
  }
}

/// A merge being decided: each field's pick and whether photos move.
typedef DuplicateMergeDraft = ({
  Map<String, MergePick> picks,
  bool carryPhotos,
});
