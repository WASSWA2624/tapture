/// Decides which actions a role is shown. No HTTP and no database.
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
