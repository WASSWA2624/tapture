import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

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

/// Breadcrumb label for the status line.
String contextStatusLabel(ContextState state) {
  if (state.isEmpty) {
    return Copy.statusNoContext;
  }
  final List<ContextLevel> ordered = List<ContextLevel>.of(state.levels)
    ..sort((ContextLevel a, ContextLevel b) => a.order.compareTo(b.order));
  final List<String> parts = <String>[
    for (final ContextLevel level in ordered)
      if ((state.values[level.fieldKey] ?? '').isNotEmpty)
        state.values[level.fieldKey]!,
    ...state.pinned.values.where((String v) => v.isNotEmpty),
  ];
  if (parts.isEmpty) {
    return Copy.statusNoContext;
  }
  return parts.join(' · ');
}

/// Clock for idle and movement checks. Tests override this.
final Provider<Clock> contextClockProvider = Provider<Clock>((Ref _) {
  return const SystemClock();
});

/// Location permission reads. Constructed with GPS from settings so a
/// request is refused while GPS is off (FE-SEC-07).
final Provider<PermissionsService> contextPermissionsProvider =
    Provider<PermissionsService>((Ref ref) {
      final SettingsStore store = ref.watch(projectSettingsStoreProvider);
      return PermissionsService(
        gpsEnabled: () => store.read(SettingKeys.gpsEnabled),
      );
    });
