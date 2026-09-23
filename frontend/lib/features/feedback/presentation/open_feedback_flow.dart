import 'package:flutter/material.dart';

/// Opens [page] as a full screen on the requested navigator, on every form
/// factor. App entry points use the root; the always-on-top Feedback layer
/// uses its own navigator so it never disturbs the screen being documented.
Future<T?> openFeedbackFlow<T>(
  BuildContext context, {
  required Widget page,
  bool useRootNavigator = true,
}) {
  return Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  ).push<T>(MaterialPageRoute<T>(builder: (BuildContext _) => page));
}
