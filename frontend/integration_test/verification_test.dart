import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/domain/field_variance.dart';
import 'package:tapture/features/quality/domain/variance_computation.dart';
import 'package:tapture/features/quality/domain/verification_prefill.dart';

import 'support/harness.dart';

void main() {
  test('a confirmed capture that differs from the register records a variance', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    const Map<String, String> register = <String, String>{
      'serial': 'REG-1',
      'model': 'Hoist',
    };
    final VerificationPrefill prefill = VerificationPrefill.fromRow(
      row: register,
      binding: const <String, String>{'serial': 'serial', 'model': 'model'},
    );
    expect(prefill.onRegister, isTrue);
    final Map<String, String> found = Map<String, String>.of(prefill.asFound);
    found['model'] = 'Winch';
    final List<FieldVariance> variances = VarianceComputation.compare(
      recorded: prefill.asRecorded,
      found: found,
      fieldKeys: const <String>['serial', 'model'],
    );
    final FieldVariance model = variances.singleWhere(
      (FieldVariance row) => row.fieldKey == 'model',
    );
    expect(model.status, VarianceStatus.changed);
    expect(model.recorded, 'Hoist');
    expect(model.found, 'Winch');
    expect(register['model'], 'Hoist');
    await app.capture(fields: found);
    expect(app.outboundCallCount, 0);
  });
}
