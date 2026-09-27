import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// One candidate a person can pick, already labelled by its source.
typedef ConflictChoice = ({
  String id,
  String sourceLabel,
  String value,
  String? evidence,
});

/// The row that resolves one field's conflict (task 015).
///
/// Each candidate sits beside its source. A typed value matching none of
/// them is accepted with a reason.
final class ConflictResolutionRow extends StatelessWidget {
  /// Creates the row.
  const ConflictResolutionRow({
    required this.choices,
    this.failure,
    this.onPick,
    this.onTyped,
    super.key,
  });

  /// Candidates. Empty is the empty state.
  final List<ConflictChoice> choices;

  /// Why the candidates could not be read.
  final Failure? failure;

  /// The candidate id the person picked, with the reason.
  final void Function(String id, String reason)? onPick;

  /// A value the person typed, with the reason.
  final void Function(String value, String reason)? onTyped;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (choices.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.warning,
        headline: Copy.conflictEmptyHeadline,
        message: Copy.conflictEmptyMessage,
      );
    }
    return _Choices(choices: choices, onPick: onPick, onTyped: onTyped);
  }
}

class _Choices extends StatefulWidget {
  const _Choices({
    required this.choices,
    required this.onPick,
    required this.onTyped,
  });

  final List<ConflictChoice> choices;
  final void Function(String id, String reason)? onPick;
  final void Function(String value, String reason)? onTyped;

  @override
  State<_Choices> createState() => _ChoicesState();
}

class _ChoicesState extends State<_Choices> {
  final TextEditingController _typed = TextEditingController();
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ConflictChoice choice in widget.choices)
          AppListTile(
            key: ValueKey<String>('conflict-${choice.id}'),
            title: choice.value,
            subtitle: choice.evidence == null
                ? choice.sourceLabel
                : '${choice.sourceLabel} · ${choice.evidence}',
            onTap: () => widget.onPick?.call(choice.id, _reason.text),
          ),
        AppTextField(
          key: const ValueKey<String>('conflict-typed'),
          label: Copy.conflictTypeOwn,
          controller: _typed,
        ),
        AppTextField(
          key: const ValueKey<String>('conflict-reason'),
          label: Copy.conflictReason,
          controller: _reason,
        ),
        AppButton(
          key: const ValueKey<String>('conflict-use-typed'),
          label: Copy.conflictTypeOwn,
          onPressed: () => widget.onTyped?.call(_typed.text, _reason.text),
        ),
      ],
    );
  }
}
