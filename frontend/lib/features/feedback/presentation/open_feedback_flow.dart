import 'package:flutter/material.dart';

/// Opens [page] as a full screen on the root navigator, on every form factor.
Future<T?> openFeedbackFlow<T>(BuildContext context, {required Widget page}) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(MaterialPageRoute<T>(builder: (BuildContext _) => page));
}
