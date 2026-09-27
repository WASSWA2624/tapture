import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'review_approval.dart';
import 'review_screen.dart';

/// Opens one record for review and approves it from the store (task 016).
final class ReviewRoute extends ConsumerWidget {
  /// Creates the review of [recordId].
  const ReviewRoute({required this.recordId, super.key});

  /// Record to load. Null is the empty review.
  final String? recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? id = recordId;
    return ReviewScreen(
      recordId: id,
      onApprove: id == null
          ? null
          : () => unawaited(
              ReviewApproval.approve(
                context,
                ref,
                recordId: id,
                queue: <String>[id],
              ),
            ),
    );
  }
}
