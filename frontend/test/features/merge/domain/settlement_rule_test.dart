import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/domain.dart';

void main() {
  test('the rules apply in specification §47 order', () {
    expect(SettlementRule.values, <SettlementRule>[
      SettlementRule.verifiedBeatsUnverified,
      SettlementRule.scannedBeatsInferred,
      SettlementRule.valueBeatsUntouchedEmpty,
      SettlementRule.none,
    ]);
  });

  test('an earlier rule wins when two apply', () {
    // Verified but inferred here, unverified but scanned there: verification
    // is checked first, so this device's value stays.
    final MergePlan plan = MergePlanner.plan(
      incoming: <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[
          <String, Object?>{'id': 'r1', 'template_id': 't1'},
        ],
        'record_fields': <Map<String, Object?>>[
          <String, Object?>{
            'id': 'v1',
            'record_id': 'r1',
            'field_key': 'serial',
            'value_raw': 'X-1',
            'verified': 0,
            'source': 'barcode',
          },
        ],
      },
      local: <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[
          <String, Object?>{'id': 'r1', 'template_id': 't1'},
        ],
        'record_fields': <Map<String, Object?>>[
          <String, Object?>{
            'id': 'v1',
            'record_id': 'r1',
            'field_key': 'serial',
            'value_raw': 'X-l',
            'verified': 1,
            'source': 'ocr',
          },
        ],
      },
      templateMapping: const <String, String>{'t1': 't1'},
      targetProjectId: 'p1',
      incomingProjectId: 'p1',
    );
    expect(plan.settled, isEmpty);
    expect(plan.conflicts, isEmpty);
    expect(plan.counts.kept, 1);
  });
}
