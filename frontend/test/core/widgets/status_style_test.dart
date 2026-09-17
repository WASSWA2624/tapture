import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

void main() {
  test('StatusStyle.of is exhaustive over RecordStatus', () {
    const AppColors colors = AppColors.light;
    final Set<String> labels = <String>{};
    final Set<Object> icons = <Object>{};
    for (final RecordStatus status in RecordStatus.values) {
      final (Color color, IconData icon, String label) = StatusStyle.of(
        status,
        colors,
      );
      expect(label, isNotEmpty);
      expect(labels.add(label), isTrue, reason: 'duplicate label "$label"');
      expect(icons.add(icon), isTrue, reason: 'duplicate icon for $status');
      expect(color, isNot(colors.surface));
      expect(color, isNot(colors.onSurface));
    }
    expect(labels, hasLength(RecordStatus.values.length));
  });
}
