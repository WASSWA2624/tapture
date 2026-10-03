import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/templates.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_state.dart';

/// Live context for [projectId].
final projectContextProvider = StreamProvider.autoDispose
    .family<ContextState, String>((Ref ref, String projectId) {
      return ref.watch(contextRepositoryProvider).watch(projectId);
    }, retry: (int _, Object _) => null);

/// Context for the open project, or empty when none.
final openProjectContextProvider = Provider<AsyncValue<ContextState>>((
  Ref ref,
) {
  final String? id = ref.watch(currentProjectProvider);
  if (id == null || id.isEmpty) {
    return const AsyncValue<ContextState>.data(ContextState());
  }
  return ref.watch(projectContextProvider(id));
});

/// Live presets for [projectId], most recently used first.
final contextPresetsProvider = StreamProvider.autoDispose
    .family<List<ContextPreset>, String>((Ref ref, String projectId) {
      return ref.watch(contextRepositoryProvider).watchPresets(projectId);
    }, retry: (int _, Object _) => null);

/// The project's templates: the field keys levels bind to, the stickable
/// fields pins come from, and the names pinned chips show.
final contextTemplatesProvider = StreamProvider.autoDispose
    .family<List<TemplateDef>, String>((Ref ref, String projectId) {
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);

/// The stickable fields of [templates] that are not levels, each once, in
/// template order: what can be pinned beside the hierarchy (spec §20.3).
List<FieldDef> pinnableFields(List<TemplateDef> templates, ContextState state) {
  final Set<String> levelKeys = <String>{
    for (final ContextLevel level in state.levels) level.fieldKey,
  };
  final Set<String> seen = <String>{};
  return <FieldDef>[
    for (final TemplateDef template in templates)
      for (final FieldDef field in template.fields)
        if (field.stickable &&
            !levelKeys.contains(field.fieldKey) &&
            seen.add(field.fieldKey))
          field,
  ];
}

/// The name of pinned [fieldKey]: its template label, or the key itself.
String pinnedFieldLabel(List<TemplateDef> templates, String fieldKey) {
  for (final TemplateDef template in templates) {
    for (final FieldDef field in template.fields) {
      if (field.fieldKey == fieldKey && field.label.isNotEmpty) {
        return field.label;
      }
    }
  }
  return fieldKey;
}

/// A level's name: its label, or its field key when it has none.
String contextLevelName(ContextLevel level) {
  return level.label.isEmpty ? level.fieldKey : level.label;
}

/// Levels from the root down.
List<ContextLevel> orderedLevels(ContextState state) {
  return List<ContextLevel>.of(state.levels)
    ..sort((ContextLevel a, ContextLevel b) => a.order.compareTo(b.order));
}

/// Breadcrumb label for the status line.
String contextStatusLabel(ContextState state, {LocalizedCopy? localizedCopy}) {
  if (state.isEmpty) {
    return (localizedCopy ?? Copy.english).statusNoContext;
  }
  final List<String> parts = <String>[
    for (final ContextLevel level in orderedLevels(state))
      if ((state.values[level.fieldKey] ?? '').isNotEmpty)
        state.values[level.fieldKey]!,
    ...state.pinned.values.where((String v) => v.isNotEmpty),
  ];
  if (parts.isEmpty) {
    return (localizedCopy ?? Copy.english).statusNoContext;
  }
  return (localizedCopy ?? Copy.english).contextBreadcrumb(parts);
}

/// Clock for idle and movement checks. Tests override this.
final Provider<Clock> contextClockProvider = Provider<Clock>((Ref _) {
  return const SystemClock();
});

/// Location permission reads. GPS is the open project's own setting when it
/// has one, else the device default, as capture reads it, so a request is
/// refused while GPS is off (FE-SEC-07).
final Provider<PermissionsService> contextPermissionsProvider =
    Provider<PermissionsService>((Ref ref) {
      final SettingsStore store = ref.watch(projectSettingsStoreProvider);
      final bool? projectGps = ref
          .watch(currentProjectDetailsProvider)
          ?.settings
          .gpsEnabled;
      return PermissionsService(
        gpsEnabled: () => projectGps ?? store.read(SettingKeys.gpsEnabled),
      );
    });
