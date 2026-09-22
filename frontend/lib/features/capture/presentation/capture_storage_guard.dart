import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// Storage headroom UI for capture — warn dismissible, stop offers export.
final class CaptureStorageGuardBanner extends StatefulWidget {
  /// Creates a banner driven by [guard].
  const CaptureStorageGuardBanner({
    required this.level,
    required this.freeBytesLabel,
    this.onDismiss,
    this.onExport,
    this.allowWrites = true,
    super.key,
  });

  /// Current headroom.
  final HeadroomState level;

  /// Named free space.
  final String freeBytesLabel;

  /// Dismiss low warning once per session.
  final VoidCallback? onDismiss;

  /// Export shortcut at critical.
  final VoidCallback? onExport;

  /// False at critical — refuse new writes only.
  final bool allowWrites;

  @override
  State<CaptureStorageGuardBanner> createState() =>
      _CaptureStorageGuardBannerState();
}

class _CaptureStorageGuardBannerState extends State<CaptureStorageGuardBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.level == HeadroomState.ample) {
      return const SizedBox.shrink();
    }
    if (widget.level == HeadroomState.low && _dismissed) {
      return const SizedBox.shrink();
    }
    if (widget.level == HeadroomState.low) {
      return MaterialBanner(
        content: Text('${Copy.settingsHeadroomLow} ${widget.freeBytesLabel}'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              setState(() => _dismissed = true);
              widget.onDismiss?.call();
            },
            child: const Text(Copy.captureStorageDismiss),
          ),
        ],
      );
    }
    return MaterialBanner(
      content: Text(
        '${Copy.settingsHeadroomCritical} ${widget.freeBytesLabel}',
      ),
      actions: <Widget>[
        AppButton(label: Copy.captureStorageExport, onPressed: widget.onExport),
      ],
    );
  }
}
