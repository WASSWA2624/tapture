import 'package:flutter_test/flutter_test.dart';

import '../../../support/fault_injection.dart';
import '../../../support/malformed_response_recovery.dart';

void main() {
  test(
    'malformed replies retain checkpoints and evidence through an explicit retry',
    () async {
      final FaultInjector faults = FaultInjector();
      addTearDown(faults.clear);
      await verifyMalformedResponseRecovery(faults);
      expect(faults.check(Dependency.response), isNull);
    },
  );
}
