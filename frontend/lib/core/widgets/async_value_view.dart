import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

/// Chooses loading, empty, error or data for an [AsyncValue] (FE-CONS-04).
///
/// Feature screens hand the provider value to this widget and write no
/// state switch, spinner or error copy of their own.
class AsyncValueView<T> extends StatelessWidget {
  /// Creates the four-state view. [isEmpty] is the emptiness test on
  /// loaded data; [empty] builds that panel.
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.empty,
    this.isEmpty,
    this.onRetry,
    this.loadingShape = SkeletonShape.list,
    this.loadingCount = 3,
  });

  /// Async provider snapshot to render.
  final AsyncValue<T> value;

  /// Built when [value] has data that is not empty.
  final Widget Function(T data) data;

  /// Built when [isEmpty] is true of the loaded value.
  final Widget Function()? empty;

  /// Emptiness test on loaded data. Null means loaded data is never empty.
  final bool Function(T data)? isEmpty;

  /// Passed to [AppErrorState] when [value] is an error.
  final VoidCallback? onRetry;

  /// Skeleton that occupies the same space as [data] while loading.
  final SkeletonShape loadingShape;

  /// How many skeleton units to paint.
  final int loadingCount;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (T loaded) {
        if (isEmpty?.call(loaded) ?? false) {
          return empty?.call() ??
              const AppEmptyState(
                icon: Icons.inbox_outlined,
                headline: Copy.emptyHeadline,
                message: Copy.emptyMessage,
              );
        }
        return data(loaded);
      },
      error: (Object error, StackTrace _) {
        return AppErrorState(failure: Failure.from(error), onRetry: onRetry);
      },
      loading: () {
        return AppSkeleton(shape: loadingShape, count: loadingCount);
      },
    );
  }
}
