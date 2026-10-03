import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/capture/presentation/capture_headroom.dart';

/// Free space on capture (task 012 step 21): nothing while space is ample,
/// a dismissible warning once per visit when it runs low, and at the stop
/// threshold a message naming the space left with Export as the way out.
/// Capture keeps working below the warning; only the stop refuses a new
/// photo, and a write already under way completes.
final class CaptureStorageGuard extends ConsumerWidget {
  /// Creates the guard for [projectId], whose exports Export opens.
  const CaptureStorageGuard({required this.projectId, super.key});

  /// The project capture files under. Empty opens every export.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final CaptureHeadroomView view = ref.watch(captureHeadroomProvider);
    final int? free = view.freeBytes;
    switch (view.level) {
      case HeadroomState.low when view.warnLow:
        return Padding(
          padding: const EdgeInsets.only(bottom: Space.x4),
          child: AppBanner(
            key: const ValueKey<String>('capture-storage-low'),
            message: free == null
                ? localCopy.settingsHeadroomLow
                : localCopy.captureStorageLow(localCopy.fileSize(free)),
            icon: AppIcons.warning,
            tone: SnackTone.warning,
            onDismiss: ref.read(captureHeadroomProvider.notifier).dismissLow,
          ),
        );
      case HeadroomState.critical:
        return Padding(
          padding: const EdgeInsets.only(bottom: Space.x4),
          child: Column(
            key: const ValueKey<String>('capture-storage-full'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppBanner(
                message: free == null
                    ? localCopy.settingsHeadroomCritical
                    : localCopy.captureStorageFull(localCopy.fileSize(free)),
                icon: AppIcons.error,
                tone: SnackTone.error,
              ),
              const SizedBox(height: Space.x2),
              AppButton(
                label: localCopy.captureStorageExport,
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: () => context.push(
                  projectId.isEmpty
                      ? RoutePaths.exports
                      : RoutePaths.projectExports(projectId),
                ),
              ),
            ],
          ),
        );
      case HeadroomState.low:
      case HeadroomState.ample:
      case null:
        return const SizedBox.shrink();
    }
  }
}
