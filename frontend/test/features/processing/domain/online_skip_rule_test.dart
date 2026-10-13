import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/confidence.dart';
import 'package:tapture/features/processing/domain/online_skip_rule.dart';

void main() {
  test('a known asset filled locally and confidently skips online', () {
    final String? reason = OnlineSkipRule.reason(const <SkipField>[
      (requiredField: true, value: 'SN458923', band: ConfidenceBand.high),
      (requiredField: true, value: 'Pump', band: ConfidenceBand.high),
      (requiredField: false, value: '13 L', band: ConfidenceBand.high),
    ]);
    expect(reason, isNotNull);
  });

  test('an empty required field still needs the online stage', () {
    expect(
      OnlineSkipRule.reason(const <SkipField>[
        (requiredField: true, value: 'SN458923', band: ConfidenceBand.high),
        (requiredField: true, value: '  ', band: ConfidenceBand.high),
      ]),
      isNull,
    );
  });

  test('a required value short of high confidence still needs online', () {
    expect(
      OnlineSkipRule.reason(const <SkipField>[
        (requiredField: true, value: 'SN458923', band: ConfidenceBand.medium),
      ]),
      isNull,
    );
    expect(
      OnlineSkipRule.reason(const <SkipField>[
        (requiredField: true, value: 'SN458923', band: null),
      ]),
      isNull,
    );
  });

  test(
    'optional fields are extraction targets even without required fields',
    () {
      expect(
        OnlineSkipRule.reason(const <SkipField>[
          (requiredField: false, value: null, band: null),
        ]),
        isNull,
      );
    },
  );

  test('an incomplete optional field still needs online extraction', () {
    expect(
      OnlineSkipRule.reason(const <SkipField>[
        (requiredField: true, value: 'SN458923', band: ConfidenceBand.high),
        (requiredField: false, value: null, band: null),
      ]),
      isNull,
    );
    expect(OnlineSkipRule.reason(const <SkipField>[]), isNotNull);
  });
}
