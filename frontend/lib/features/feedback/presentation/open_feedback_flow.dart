import 'package:flutter/material.dart';
import 'package:tapture/core/widgets/feedback/app_panel_dialog.dart';
import 'package:tapture/core/widgets/responsive/form_factor.dart';

/// Opens [panel] in a dialog on a desktop with room, or [page] as a screen
/// on a phone or tablet.
Future<T?> openFeedbackFlow<T>(
  BuildContext context, {
  required String title,
  required Widget page,
  required Widget panel,
}) {
  if (context.prefersDialogs) {
    return showAppPanelDialog<T>(
      context,
      title: title,
      barrierDismissible: false,
      builder: (BuildContext _) => panel,
    );
  }
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(MaterialPageRoute<T>(builder: (BuildContext _) => page));
}
