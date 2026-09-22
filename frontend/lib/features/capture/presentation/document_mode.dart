import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';

/// Document-mode boundary detection outcome for the shutter path.
enum DocumentBoundary {
  /// Page edge found; offer perspective correction.
  detected,

  /// No edge; capture normally.
  notDetected,

  /// Correction failed; keep the original.
  correctionFailed,
}

/// Document mode UI: reports boundary outcome without blocking the shutter.
final class DocumentMode extends StatelessWidget {
  /// Creates a document-mode banner.
  const DocumentMode({
    required this.boundary,
    this.onUseCorrected,
    this.onKeepOriginal,
    super.key,
  });

  /// Detection outcome.
  final DocumentBoundary boundary;

  /// Use the perspective-corrected derived file.
  final VoidCallback? onUseCorrected;

  /// Keep the uncorrected original.
  final VoidCallback? onKeepOriginal;

  @override
  Widget build(BuildContext context) {
    final String message = switch (boundary) {
      DocumentBoundary.detected => 'Page edge found.',
      DocumentBoundary.notDetected => Copy.captureNoPageBoundary,
      DocumentBoundary.correctionFailed => 'Correction failed. Kept original.',
    };
    return Semantics(
      label: message,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message),
              if (boundary == DocumentBoundary.detected) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    TextButton(
                      onPressed: onUseCorrected,
                      child: const Text('Use corrected'),
                    ),
                    TextButton(
                      onPressed: onKeepOriginal,
                      child: const Text(Copy.captureKeepPhoto),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
