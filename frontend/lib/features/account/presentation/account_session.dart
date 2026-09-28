import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';

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

/// The account feature alone interprets the backend's role vocabulary.
RoleGate? roleGateFor(BackendConfig config, {String? projectId}) {
  final AccountRole? role = switch (config.role) {
    'administrator' => AccountRole.administrator,
    'project_manager' => AccountRole.projectManager,
    'reviewer' => AccountRole.reviewer,
    'field_operator' => AccountRole.fieldOperator,
    _ => null,
  };
  if (role == null) return null;
  if (projectId != null &&
      role != AccountRole.administrator &&
      !config.grants.containsKey(projectId)) {
    return null;
  }
  return RoleGate(role, contextScope: config.grants[projectId]);
}
