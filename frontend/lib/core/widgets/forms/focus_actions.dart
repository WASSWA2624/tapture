import 'package:flutter/widgets.dart';

/// Keyboard and focus helpers for forms (FE-A11Y-06).
extension FocusActions on BuildContext {
  /// Hides the software keyboard without moving focus to another field.
  void dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Moves focus to the next control in visual / traversal order.
  void focusNext() {
    FocusScope.of(this).nextFocus();
  }
}
