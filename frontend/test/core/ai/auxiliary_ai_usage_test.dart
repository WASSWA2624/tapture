import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/auxiliary_ai_usage.dart';

void main() {
  test(
    'catalogue calls accumulate per project and reset only on UTC day change',
    () {
      final DateTime day = DateTime.utc(2026, 9, 28);
      final AuxiliaryAiUsage first = AuxiliaryAiUsage(
        const AuxiliaryAiUsage('{}').reserve(day, 'p1'),
      );
      final AuxiliaryAiUsage second = AuxiliaryAiUsage(
        first.reserve(day, 'p2'),
      );
      final AuxiliaryAiUsage third = AuxiliaryAiUsage(
        second.reserve(day, 'p1'),
      );
      expect(third.count(day, projectId: 'p1'), 2);
      expect(third.count(day, projectId: 'p2'), 1);
      expect(third.count(day), 3);
      expect(third.count(day.add(const Duration(days: 1))), 0);
    },
  );
}
