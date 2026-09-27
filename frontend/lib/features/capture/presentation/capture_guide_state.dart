import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Capture's guide on this visit: whether the "What to capture" row is open,
/// and the template whose caption panel the person closed (FBK0000157,
/// FBK0000159, D14). Auto-dispose: a new visit starts collapsed.
final captureGuideStateProvider =
    NotifierProvider.autoDispose<CaptureGuideState, CaptureGuideView>(
      CaptureGuideState.new,
    );

/// The guide row's state: [open] shows its lists; [closedFor] is the
/// template whose caption panel stays hidden until another is chosen.
typedef CaptureGuideView = ({bool open, String? closedFor});

/// Opens and closes Capture's guide.
final class CaptureGuideState extends Notifier<CaptureGuideView> {
  @override
  CaptureGuideView build() => (open: false, closedFor: null);

  /// Opens the guide row when closed, closes it when open.
  void toggle() {
    state = (open: !state.open, closedFor: state.closedFor);
  }

  /// Hides the caption panel while [templateId] stays chosen.
  void closePanelFor(String templateId) {
    state = (open: state.open, closedFor: templateId);
  }
}
