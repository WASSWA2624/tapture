import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/templates.dart'
    show TemplateDef, templateRepositoryProvider;

import '../domain/record_history_event.dart';
import '../records.dart' show recordRepositoryProvider;

// Providers of the record history page (task 014 step 6).

/// Record [id]'s history from the local audit table, oldest first, and
/// again after every change written to it. Auto-dispose: only an open
/// history page reads it (FE-STATE-09). A failure surfaces at once so the
/// page can offer a retry.
final recordHistoryProvider = StreamProvider.autoDispose
    .family<List<RecordHistoryEvent>, String>((Ref ref, String id) {
      return ref.watch(recordRepositoryProvider).watchHistory(id);
    }, retry: (int _, Object _) => null);

/// Template [id] as a record's history names things from it: the labels of
/// its fields and its own name. Null when the template is not on this device
/// or cannot be read, and the history then shows field keys instead: a label
/// never hides a line of the history. Auto-dispose: read by the open history
/// page only (FE-STATE-09).
final recordHistoryTemplateProvider = FutureProvider.autoDispose
    .family<TemplateDef?, String>((Ref ref, String id) async {
      final Result<TemplateDef?> loaded = await ref
          .watch(templateRepositoryProvider)
          .byId(id);
      return switch (loaded) {
        Success<TemplateDef?>(:final TemplateDef? value) => value,
        FailureResult<TemplateDef?>() => null,
      };
    }, retry: (int _, Object _) => null);
