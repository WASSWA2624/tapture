import 'package:tapture/core/backend/backend_config.dart';

/// Decides which actions a role is shown. No HTTP and no database.
///
/// This is the device's one copy of the server's role matrix
/// (`backend/src/domain/permissions.ts`); `role_matrix_test.dart` reads that
/// file so the two cannot drift apart.
final class RoleGate {
  /// Creates a gate for [role]. [contextScope] limits review to one context.
  const RoleGate(this.role, {this.contextScope});

  /// The signed-in role.
  final AccountRole role;

  /// Optional context the grant is limited to.
  final String? contextScope;

  static const Map<AccountRole, Set<RoleCapability>> _allowed =
      <AccountRole, Set<RoleCapability>>{
        AccountRole.administrator: <RoleCapability>{
          RoleCapability.capture,
          RoleCapability.review,
          RoleCapability.export,
          RoleCapability.relay,
          RoleCapability.aiProxy,
          RoleCapability.adminAction,
          RoleCapability.manageUsers,
          RoleCapability.manageProject,
          RoleCapability.manageMembers,
        },
        AccountRole.projectManager: <RoleCapability>{
          RoleCapability.capture,
          RoleCapability.review,
          RoleCapability.export,
          RoleCapability.relay,
          RoleCapability.aiProxy,
          RoleCapability.manageProject,
          RoleCapability.manageMembers,
        },
        AccountRole.reviewer: <RoleCapability>{
          RoleCapability.capture,
          RoleCapability.review,
          RoleCapability.export,
        },
        AccountRole.fieldOperator: <RoleCapability>{
          RoleCapability.capture,
          RoleCapability.export,
          RoleCapability.aiProxy,
        },
      };

  /// Whether the role may be offered [capability].
  bool allows(RoleCapability capability, {String? contextId}) {
    if (!_allowed[role]!.contains(capability)) return false;
    if (contextScope != null &&
        contextId != null &&
        contextId != contextScope) {
      return false;
    }
    return true;
  }
}

/// The gate for the role cached in [config], or null when the server's role
/// is unknown. With [projectId], also null when the cached grant does not
/// include that project and the role is not an administrator's.
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

/// Whether the AI proxy may be offered for [projectId] from the cached
/// [config]: the role includes it and the cached grant covers the project,
/// which an administrator's role always does. The server bills and
/// authorises every call per project, so an empty id is never offered.
bool mayUseProxy(BackendConfig config, String projectId) {
  if (projectId.isEmpty) {
    return false;
  }
  return roleGateFor(
        config,
        projectId: projectId,
      )?.allows(RoleCapability.aiProxy) ==
      true;
}

/// A role the server understands. This file is the only copy on the device.
enum AccountRole {
  /// Manages the organisation.
  administrator,

  /// Manages one project, including relay.
  projectManager,

  /// Reviews and exports.
  reviewer,

  /// Captures in the field.
  fieldOperator,
}

/// An action a role may be offered. Hidden actions are not on screen.
enum RoleCapability {
  /// Capture a record.
  capture,

  /// Review a record.
  review,

  /// Export on the device.
  export,

  /// Use the change relay.
  relay,

  /// Call the analysis proxy.
  aiProxy,

  /// Administer the organisation.
  adminAction,

  /// List or change accounts.
  manageUsers,

  /// Register a project.
  manageProject,

  /// Change membership.
  manageMembers,
}
