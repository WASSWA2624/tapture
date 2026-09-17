import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

void main() {
  test('holds value, label and icon without rewriting the label', () {
    const Choice<String> choice = Choice<String>(
      'kPa',
      'kPa',
      icon: Icons.speed,
    );
    expect(choice.value, 'kPa');
    expect(choice.label, 'kPa');
    expect(choice.icon, Icons.speed);
    expect(choice, const Choice<String>('kPa', 'kPa', icon: Icons.speed));
  });
}
