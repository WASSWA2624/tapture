import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../templates.dart'
    show TemplateDef, TemplateRepository, templateRepositoryProvider;

/// The saved template being edited, independent of the selected project.
final templateEditorSourceProvider = StreamProvider.autoDispose
    .family<List<TemplateDef>, String>((Ref ref, String id) async* {
      final TemplateRepository repository = ref.watch(
        templateRepositoryProvider,
      );
      final TemplateDef? initial = (await repository.byId(id)).getOrThrow();
      if (initial == null) {
        yield const <TemplateDef>[];
        return;
      }
      final String? owner = initial.projectId;
      yield* (owner == null
              ? repository.watchLibrary()
              : repository.watchByProject(owner))
          .map(
            (List<TemplateDef> rows) => <TemplateDef>[
              for (final TemplateDef row in rows)
                if (row.id == id) row,
            ],
          );
    }, retry: (int _, Object _) => null);

/// Saved library copies. Shipped assets are provided by their loader.
final templateLibraryProvider = StreamProvider<List<TemplateDef>>(
  (Ref ref) => ref.watch(templateRepositoryProvider).watchLibrary(),
  retry: (int _, Object _) => null,
);
