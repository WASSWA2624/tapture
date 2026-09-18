import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';

import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';

/// Compact composer shown while a feedback draft is kept across screens.
class FeedbackDraftBar extends ConsumerStatefulWidget {
  /// Creates the bar.
  const FeedbackDraftBar({super.key});

  @override
  ConsumerState<FeedbackDraftBar> createState() => _FeedbackDraftBarState();
}

class _FeedbackDraftBarState extends ConsumerState<FeedbackDraftBar> {
  late final TextEditingController _message;

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(
      text: ref.read(feedbackDraftProvider)?.message ?? '',
    );
    _message.addListener(_persist);
  }

  @override
  void dispose() {
    _message.removeListener(_persist);
    _message.dispose();
    super.dispose();
  }

  void _persist() {
    ref.read(feedbackDraftProvider.notifier).setText(message: _message.text);
  }

  @override
  Widget build(BuildContext context) {
    final FeedbackDraft? draft = ref.watch(feedbackDraftProvider);
    final AppColors colors = context.colors;
    final int shots = draft?.shots.length ?? 0;
    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.outline,
              width: Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.x3,
              Space.x1,
              Space.x2,
              Space.x1,
            ),
            child: ContentConstraint(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: Theme.of(context)
                            .inputDecorationTheme
                            .copyWith(
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                            ),
                      ),
                      child: Semantics(
                        label: Copy.feedbackDraftBarHint,
                        child: AppTextField(
                          label: Copy.feedbackMessage,
                          controller: _message,
                          hint: Copy.feedbackMessageHint,
                          minLines: 1,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.open_in_full,
                    semanticLabel: Copy.feedbackContinue,
                    tooltip: Copy.feedbackContinue,
                    outlined: false,
                    onPressed: () {
                      _persist();
                      ref.read(feedbackDraftProvider.notifier).expand();
                    },
                  ),
                  if (shots > 0)
                    ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: Space.x1,
                        ),
                        child: Text('$shots'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
