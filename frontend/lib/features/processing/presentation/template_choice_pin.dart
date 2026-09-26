import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the open template sheet pins its answer to the current place.
///
/// On each time the sheet opens, so by default the question is asked once
/// per room rather than once per item.
final class TemplateChoicePin extends Notifier<bool> {
  @override
  bool build() => true;

  /// Records whether to pin the answer.
  void choose(bool pin) => state = pin;
}

/// The pin checkbox on the template sheet, reset when the sheet closes.
final NotifierProvider<TemplateChoicePin, bool> templateChoicePinProvider =
    NotifierProvider.autoDispose<TemplateChoicePin, bool>(
      TemplateChoicePin.new,
    );
