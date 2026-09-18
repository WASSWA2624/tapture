import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';

import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';

/// The folded feedback draft: one line to keep typing or speaking into while
/// the operator moves through the app, and the way back to the full form.
class FeedbackDraftBar extends ConsumerStatefulWidget {
  /// Creates the bar. [bottomInset] pads for the gesture bar when nothing
  /// below the bar already does.
  const FeedbackDraftBar({super.key, this.bottomInset = true});

  /// Whether the bar keeps clear of the system gesture inset itself.
  final bool bottomInset;

  @override
  ConsumerState<FeedbackDraftBar> createState() => _FeedbackDraftBarState();
}

class _FeedbackDraftBarState extends ConsumerState<FeedbackDraftBar> {
  late final FeedbackDraftController _draft = ref.read(
    feedbackDraftProvider.notifier,
  );
  late final TextEditingController _message = TextEditingController(
    text: ref.read(feedbackDraftProvider)?.message ?? '',
  )..addListener(_keepText);

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _keepText() {
    if (ref.read(feedbackDraftProvider)?.message != _message.text) {
      _draft.setText(message: _message.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int images = ref.watch(
      feedbackDraftProvider.select((FeedbackDraft? d) => d?.shots.length ?? 0),
    );
    final AppColors colors = context.colors;
    return Material(
      color: colors.surface,
      shape: Border(
        top: BorderSide(
          color: colors.outline,
          width: Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2,
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: widget.bottomInset,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            Space.x3,
            Space.x1,
            Space.x1,
            Space.x1,
          ),
          child: ContentConstraint(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    label: Copy.feedbackMessage,
                    controller: _message,
                    hint: Copy.feedbackMessageHint,
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
                if (images > 0)
                  Semantics(
                    label: Copy.feedbackImageCount(images),
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: Space.x2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.photo_library_outlined,
                              size: Space.x5,
                              color: colors.onSurface,
                            ),
                            const SizedBox(width: Space.x1),
                            Text(
                              '$images',
                              style: AppText.label.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                AppIconButton(
                  icon: Icons.open_in_full,
                  semanticLabel: Copy.feedbackContinue,
                  tooltip: Copy.feedbackContinue,
                  outlined: false,
                  onPressed: _draft.expand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
