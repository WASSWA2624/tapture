import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/features/account/domain/role_gate.dart';
import 'package:tapture/features/account/presentation/account_session.dart';

void main() {
  test('cached grants deny unrelated projects and unknown server roles', () {
    const BackendConfig reviewer = BackendConfig(
      baseUrl: 'https://org.test',
      role: 'reviewer',
      grants: <String, String?>{'assigned': 'north'},
    );
    expect(roleGateFor(reviewer, projectId: 'other'), isNull);
    final RoleGate gate = roleGateFor(reviewer, projectId: 'assigned')!;
    expect(gate.allows(RoleCapability.aiProxy), isFalse);
    expect(gate.allows(RoleCapability.review, contextId: 'north'), isTrue);
    expect(gate.allows(RoleCapability.review, contextId: 'south'), isFalse);
    expect(
      roleGateFor(const BackendConfig(baseUrl: '', role: 'new-role')),
      isNull,
    );
  });
}
