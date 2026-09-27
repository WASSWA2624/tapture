import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/account/domain/role_gate.dart';

void main() {
  const Map<AccountRole, Set<RoleCapability>> server = <AccountRole, Set<RoleCapability>>{
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

  test('the device matrix matches the server for every role and capability', () {
    for (final AccountRole role in AccountRole.values) {
      final RoleGate gate = RoleGate(role);
      for (final RoleCapability capability in RoleCapability.values) {
        expect(
          gate.allows(capability),
          server[role]!.contains(capability),
          reason: '$role $capability',
        );
      }
    }
  });

  test('a context scope hides review of another context', () {
    const RoleGate gate = RoleGate(
      AccountRole.reviewer,
      contextScope: 'north',
    );
    expect(gate.allows(RoleCapability.review, contextId: 'north'), isTrue);
    expect(gate.allows(RoleCapability.review, contextId: 'south'), isFalse);
  });
}
