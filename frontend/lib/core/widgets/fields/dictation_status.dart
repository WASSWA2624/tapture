import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';

import 'dictation_phase.dart';

/// The line under a field while it takes dictation: what the microphone is
/// doing, then the words heard so far. Announced as it changes
/// (FE-A11Y-07); an icon and text carry the state, never colour alone.
class DictationStatus extends StatelessWidget {
  /// Creates the line for a listen at [phase] that has heard [heard] so
  /// far. Render it only while a listen is active.
  const DictationStatus({super.key, required this.phase, this.heard = ''});

  /// Where the listen is.
  final DictationPhase phase;

  /// Words heard so far, not yet in the field.
  final String heard;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String heard = this.heard.trim();
    final String line = switch (phase) {
      DictationPhase.idle => '',
      DictationPhase.starting => Copy.dictationStarting,
      DictationPhase.listening =>
        heard.isEmpty ? Copy.dictationListening : heard,
      DictationPhase.finishing =>
        heard.isEmpty ? Copy.dictationFinishing : heard,
    };
    return Semantics(
      liveRegion: true,
      container: true,
      label: line,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.graphic_eq, size: Space.x4, color: colors.primary),
            const SizedBox(width: Space.x1),
            Flexible(
              child: Text(
                line,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(color: colors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
