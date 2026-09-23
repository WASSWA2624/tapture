import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

/// Catalogue confirm and alert. Features call [showAppConfirm] and
/// [showAppAlert] rather than constructing [AlertDialog] (FE-CONS-05).
class AppDialog extends StatelessWidget {
  /// Creates a confirm dialog. [confirmLabel] is required so a destructive
  /// action cannot ship an unnamed button.
  const AppDialog.confirm({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
    this.onConfirm,
    this.onCancel,
    this.extra,
    this.confirmEnabled = true,
    this.alternativeLabel,
    this.onAlternative,
  }) : _alert = false;

  /// Creates an alert with a single way out.
  const AppDialog.alert({
    super.key,
    required this.title,
    required this.message,
    this.onConfirm,
  }) : confirmLabel = Copy.ok,
       destructive = false,
       onCancel = null,
       extra = null,
       confirmEnabled = true,
       alternativeLabel = null,
       onAlternative = null,
       _alert = true;

  /// Heading; also the semantic name of the route (FE-A11Y-02).
  final String title;

  /// Body copy. Wraps at 200 percent text scale (FE-A11Y-03).
  final String message;

  /// Confirm or OK label.
  final String confirmLabel;

  /// When true, the confirm control uses the destructive variant.
  final bool destructive;

  /// Confirm action. Null pops `true` (or nothing on an alert).
  final VoidCallback? onConfirm;

  /// Cancel action. Null pops `false`. Hidden on an alert.
  final VoidCallback? onCancel;

  /// Optional control under the message, such as a typed-name field.
  final Widget? extra;

  /// When false, the confirm control is disabled.
  final bool confirmEnabled;

  /// Optional third action in the same dialog, such as "Export first".
  final String? alternativeLabel;

  /// Runs when [alternativeLabel] is pressed. Null pops `false`.
  final VoidCallback? onAlternative;

  final bool _alert;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.all(Space.x6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: colors.outline, width: Space.x0 / 2),
      ),
      child: Semantics(
        namesRoute: true,
        scopesRoute: true,
        label: title,
        explicitChildNodes: true,
        child: ConstrainedBox(
          key: const ValueKey<String>('app-dialog-surface'),
          constraints: const BoxConstraints(maxWidth: Sizes.dialogMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(Space.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _title(colors),
                const SizedBox(height: Space.x3),
                Text(
                  message,
                  style: AppText.body.copyWith(color: colors.onSurface),
                ),
                if (extra != null) ...<Widget>[
                  const SizedBox(height: Space.x3),
                  extra!,
                ],
                const SizedBox(height: Space.x4),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: Space.x2,
                  runSpacing: Space.x2,
                  children: <Widget>[
                    if (!_alert)
                      AppButton(
                        label: Copy.cancel,
                        variant: AppButtonVariant.text,
                        onPressed: () => _cancel(context),
                      ),
                    if (alternativeLabel != null)
                      AppButton(
                        label: alternativeLabel!,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _alternative(context),
                      ),
                    AppButton(
                      label: confirmLabel,
                      variant: destructive
                          ? AppButtonVariant.destructive
                          : AppButtonVariant.primary,
                      onPressed: confirmEnabled
                          ? () => _confirm(context)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(AppColors colors) {
    final Text heading = Text(
      title,
      style: AppText.title.copyWith(color: colors.onSurface),
    );
    if (!destructive) {
      return heading;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: Icon(
            Icons.warning_amber_outlined,
            color: colors.danger,
            size: Space.x6,
          ),
        ),
        const SizedBox(width: Space.x3),
        Expanded(child: heading),
      ],
    );
  }

  void _confirm(BuildContext context) {
    final VoidCallback? onConfirm = this.onConfirm;
    if (onConfirm != null) {
      onConfirm();
      return;
    }
    Navigator.of(context).pop(_alert ? null : true);
  }

  void _cancel(BuildContext context) {
    final VoidCallback? onCancel = this.onCancel;
    if (onCancel != null) {
      onCancel();
      return;
    }
    Navigator.of(context).pop(false);
  }

  void _alternative(BuildContext context) {
    final VoidCallback? onAlternative = this.onAlternative;
    if (onAlternative != null) {
      onAlternative();
      return;
    }
    Navigator.of(context).pop(false);
  }
}

/// Confirm or cancel. Dismissing the barrier always returns false.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  String? typedValue,
  String? typedLabel,
  String? alternativeLabel,
  VoidCallback? onAlternative,
  bool useRootNavigator = true,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      if (typedValue != null && typedValue.isNotEmpty) {
        return _TypedConfirm(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          destructive: destructive,
          typedValue: typedValue,
          typedLabel: typedLabel ?? title,
          alternativeLabel: alternativeLabel,
          onAlternative: onAlternative,
        );
      }
      return AppDialog.confirm(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: destructive,
        alternativeLabel: alternativeLabel,
        onAlternative: onAlternative == null
            ? null
            : () {
                onAlternative();
                Navigator.of(dialogContext).pop(false);
              },
      );
    },
  );
  return result ?? false;
}

/// Alert with a single OK action. Barrier dismiss also closes it.
Future<void> showAppAlert(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AppDialog.alert(title: title, message: message);
    },
  );
}

class _TypedConfirm extends StatefulWidget {
  const _TypedConfirm({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.destructive,
    required this.typedValue,
    required this.typedLabel,
    this.alternativeLabel,
    this.onAlternative,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;
  final String typedValue;
  final String typedLabel;
  final String? alternativeLabel;
  final VoidCallback? onAlternative;

  @override
  State<_TypedConfirm> createState() => _TypedConfirmState();
}

class _TypedConfirmState extends State<_TypedConfirm> {
  late final TextEditingController _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  bool get _matches => _typed.text.trim() == widget.typedValue.trim();

  @override
  Widget build(BuildContext context) {
    return AppDialog.confirm(
      title: widget.title,
      message: widget.message,
      confirmLabel: widget.confirmLabel,
      destructive: widget.destructive,
      confirmEnabled: _matches,
      extra: AppTextField(
        label: widget.typedLabel,
        controller: _typed,
        requiredness: FieldRequiredness.required,
        dictation: false,
        onChanged: (String _) => setState(() {}),
      ),
      alternativeLabel: widget.alternativeLabel,
      onAlternative: widget.onAlternative == null
          ? null
          : () {
              widget.onAlternative!();
              Navigator.of(context).pop(false);
            },
    );
  }
}
