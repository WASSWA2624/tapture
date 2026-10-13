import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fields selected for one foreground processing request.
final class ProcessingFieldSelection extends Notifier<Set<String>> {
  /// Selection belongs to the record whose scope sheet is open.
  ProcessingFieldSelection(this.recordId);

  /// Stable record identity.
  final String recordId;

  @override
  Set<String> build() => const <String>{};

  /// Toggles one eligible field without mutating the previous selection.
  void toggle(String fieldKey) {
    final Set<String> next = Set<String>.of(state);
    if (!next.add(fieldKey)) next.remove(fieldKey);
    state = next;
  }
}

/// Disposed when the scope sheet closes, including cancellation.
final processingFieldSelectionProvider = NotifierProvider.autoDispose
    .family<ProcessingFieldSelection, Set<String>, String>(
      ProcessingFieldSelection.new,
    );
