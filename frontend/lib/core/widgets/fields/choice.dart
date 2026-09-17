import 'package:flutter/material.dart';

/// One option in [AppChoiceField] or [AppMultiChoiceField].
///
/// [label] is template content (FE-L10N-07): shown as given, never
/// translated, matched or normalised against UI copy.
@immutable
class Choice<T> {
  /// Creates an option. [icon] is optional; selection always carries a tick
  /// as well, so colour is never the only signal (FE-A11Y-05).
  const Choice(this.value, this.label, {this.icon});

  /// The value reported to [AppChoiceField.onChanged] and stored in
  /// [AppMultiChoiceField.value].
  final T value;

  /// User-facing option text from the template or caller.
  final String label;

  /// Optional leading glyph. Does not replace the selection tick.
  final IconData? icon;

  @override
  bool operator ==(Object other) {
    return other is Choice<T> &&
        other.value == value &&
        other.label == label &&
        other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(value, label, icon);
}
