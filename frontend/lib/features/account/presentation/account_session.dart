import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/offline_authority.dart';
import '../domain/role_gate.dart';

/// Bootstrap owns the session; tests can inject one without platform access.
final Provider<BackendSession?> backendSessionProvider =
    Provider<BackendSession?>((Ref _) => null);

/// Cached enrolment updates never wait for an online request.
final StreamProvider<BackendConfig> backendConfigProvider =
    StreamProvider<BackendConfig>((Ref ref) async* {
      final BackendSession? session = ref.watch(backendSessionProvider);
      if (session == null) {
        yield const BackendConfig(baseUrl: '');
        return;
      }
      yield session.config;
      yield* session.changes;
    });

/// What this device may do now, from [session]'s saved grant and its clock.
/// With [projectId], server-bound capabilities also need that project in the
/// cached grant (an administrator's role covers every project).
OfflineAuthority authorityFor(BackendSession? session, {String? projectId}) {
  if (session == null) {
    return const OfflineAuthority(state: AuthorityState.neverSignedIn);
  }
  return OfflineAuthority(
    state: session.authority,
    role: roleGateFor(session.config, projectId: projectId),
    grantsExpireAt: session.config.grantValidUntil,
  );
}

/// The open project's authority. Derived again whenever the session changes
/// and whenever a screen that reads it opens, so the clock is read then; it
/// never waits on the network.
final offlineAuthorityProvider = Provider.autoDispose<OfflineAuthority>((
  Ref ref,
) {
  ref.watch(backendConfigProvider);
  return authorityFor(
    ref.watch(backendSessionProvider),
    projectId: ref.watch(currentProjectProvider),
  );
});
