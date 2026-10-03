import 'package:tapture/core/errors/failure.dart';

/// What the review screen shows of its own state.
final class ReviewState {
  /// Creates the state.
  const ReviewState({
    this.confidentOpen = false,
    this.busy = false,
    this.reanalysing = false,
    this.accepted = const <String>{},
    this.failure,
  });

  /// Whether the confident group is open.
  final bool confidentOpen;

  /// Whether a write is running.
  final bool busy;

  /// Whether re-analysis was asked for and its proposals are awaited or
  /// shown.
  final bool reanalysing;

  /// Proposals ticked for acceptance, by field key.
  final Set<String> accepted;

  /// Why the last write failed, until dismissed.
  final Failure? failure;

  /// Returns a copy with the given fields replaced.
  ReviewState copyWith({
    bool? confidentOpen,
    bool? busy,
    bool? reanalysing,
    Set<String>? accepted,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ReviewState(
      confidentOpen: confidentOpen ?? this.confidentOpen,
      busy: busy ?? this.busy,
      reanalysing: reanalysing ?? this.reanalysing,
      accepted: accepted ?? this.accepted,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
