import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Values typed on a record's edit sheets and not saved yet, by field key.
/// Auto-dispose: closing the sheet drops them (FE-STATE-09).
final recordFieldDraftProvider = NotifierProvider.autoDispose
    .family<RecordFieldDraft, Map<String, String>, String>(
      RecordFieldDraft.new,
    );

/// The unsaved text of one record's fields, so a choice or a date shows what
/// was just picked before Save writes it (FE-STATE-01).
final class RecordFieldDraft extends Notifier<Map<String, String>> {
  /// Creates the draft for [recordId].
  RecordFieldDraft(this.recordId);

  /// The record being edited.
  final String recordId;

  @override
  Map<String, String> build() => const <String, String>{};

  /// Records [text] as the value typed for [fieldKey].
  void set(String fieldKey, String text) {
    state = <String, String>{...state, fieldKey: text};
  }
}
