import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Values typed on a record's edit page or one-value sheet and not saved
/// yet, by field key, for the record id it is created with. Auto-dispose:
/// leaving the page or closing the sheet drops them (FE-STATE-09).
final recordFieldDraftProvider = NotifierProvider.autoDispose
    .family<RecordFieldDraft, Map<String, String>, String>(
      RecordFieldDraft.new,
    );

/// The unsaved text of one record's fields, so a choice or a date shows what
/// was just picked before Save writes it (FE-STATE-01). A failed save leaves
/// it as it is, so nothing typed is lost (FE-SIMP-09).
final class RecordFieldDraft extends Notifier<Map<String, String>> {
  /// Creates the draft for [recordId].
  RecordFieldDraft(this.recordId);

  /// The record being edited.
  final String recordId;

  @override
  Map<String, String> build() => const <String, String>{};

  /// Records [text] as the value typed for [fieldKey].
  void set(String fieldKey, String text) {
    if (state[fieldKey] == text) {
      return;
    }
    state = Map<String, String>.unmodifiable(<String, String>{
      ...state,
      fieldKey: text,
    });
  }

  /// Forgets what was typed for [fieldKeys], once it is saved.
  void forget(Iterable<String> fieldKeys) {
    final Set<String> keys = fieldKeys.toSet();
    if (!state.keys.any(keys.contains)) {
      return;
    }
    state = Map<String, String>.unmodifiable(<String, String>{
      for (final MapEntry<String, String> typed in state.entries)
        if (!keys.contains(typed.key)) typed.key: typed.value,
    });
  }

  /// Forgets everything typed.
  void clear() {
    if (state.isEmpty) {
      return;
    }
    state = const <String, String>{};
  }
}
