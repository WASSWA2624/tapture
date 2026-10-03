import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/features/capture/domain/document_correction.dart';

/// Document mode's word on the last shot. It never blocks the shutter: a
/// found page offers the straightened copy beside the kept original, and a
/// missing or failed one says the photo was kept as it is.
final class DocumentMode extends StatelessWidget {
  /// Creates the notice for [boundary].
  const DocumentMode({
    required this.boundary,
    required this.onUseCorrected,
    required this.onKeepOriginal,
    super.key,
  });

  /// Detection outcome.
  final DocumentBoundary boundary;

  /// Stores the perspective-corrected derived file.
  final VoidCallback onUseCorrected;

  /// Keeps only the uncorrected original; also dismisses the notice.
  final VoidCallback onKeepOriginal;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return switch (boundary) {
      DocumentBoundary.detected => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppBanner(
            message: localCopy.capturePageBoundaryFound,
            icon: AppIcons.photoDocument,
            tone: SnackTone.info,
          ),
          Padding(
            padding: const EdgeInsets.all(Space.x2),
            child: ResponsivePair(
              stacksOnCompact: false,
              start: AppButton(
                label: localCopy.captureKeepPhoto,
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: onKeepOriginal,
              ),
              end: AppButton(
                label: localCopy.captureUseCorrected,
                expand: true,
                onPressed: onUseCorrected,
              ),
            ),
          ),
        ],
      ),
      DocumentBoundary.notDetected => AppBanner(
        message: localCopy.captureNoPageBoundary,
        icon: AppIcons.info,
        tone: SnackTone.info,
        onDismiss: onKeepOriginal,
      ),
      DocumentBoundary.correctionFailed => AppBanner(
        message: localCopy.captureCorrectionFailed,
        icon: AppIcons.warning,
        tone: SnackTone.warning,
        onDismiss: onKeepOriginal,
      ),
    };
  }
}
