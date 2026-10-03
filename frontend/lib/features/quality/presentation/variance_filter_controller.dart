import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/field_variance.dart';

/// The status the variance view of one project is filtered by (task 015).
final varianceFilterControllerProvider = NotifierProvider.autoDispose
    .family<VarianceFilterController, VarianceStatus?, String>(
      VarianceFilterController.new,
    );

/// Holds the variance filter; null shows every status.
final class VarianceFilterController extends Notifier<VarianceStatus?> {
  /// Creates the filter of [projectId]'s variance view.
  VarianceFilterController(this.projectId);

  /// The project filtered.
  final String projectId;

  @override
  VarianceStatus? build() => null;

  /// Filters by [status], or clears the filter when it is already [status].
  void toggle(VarianceStatus status) {
    state = state == status ? null : status;
  }
}
