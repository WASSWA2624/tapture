import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';

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

  final bool _alert;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: colors.outline, width: Space.x0 / 2),
      ),
      child: Semantics(
        namesRoute: true,
        scopesRoute: true,
        label: title,
        explicitChildNodes: true,
        child: Padding(
          padding: const EdgeInsets.all(Space.x4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: AppText.title.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: Space.x3),
              Text(
                message,
                style: AppText.caption.copyWith(color: colors.onSurface),
              ),
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
                  AppButton(
                    label: confirmLabel,
                    variant: destructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    onPressed: () => _confirm(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
}

/// Confirm or cancel. Dismissing the barrier always returns false.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AppDialog.confirm(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: destructive,
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
