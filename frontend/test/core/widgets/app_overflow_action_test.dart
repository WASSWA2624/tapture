import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';

void main() {
  test('AppOverflowAction carries a label, tap and optional icon', () {
    bool tapped = false;
    final AppOverflowAction action = AppOverflowAction(
      key: const ValueKey<String>('overflow-save'),
      icon: Icons.save_outlined,
      label: Copy.save,
      onTap: () => tapped = true,
    );

    expect(action.label, Copy.save);
    expect(action.icon, Icons.save_outlined);
    expect(action.key, const ValueKey<String>('overflow-save'));
    action.onTap();
    expect(tapped, isTrue);
  });
}
