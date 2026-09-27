import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/domain/record_value.dart';
import 'package:tapture/features/records/domain/template_change_plan.dart';

void main() {
  test('keys the target declares map; the rest are kept as retired', () {
    final TemplateChangePlan plan = TemplateChangePlan.between(
      fromTemplateId: 'a',
      toTemplateId: 'b',
      liveKeys: <String>['serial', 'model', 'colour'],
      targetFieldKeys: <String>['model', 'serial', 'location'],
    );
    expect(plan.fromTemplateId, 'a');
    expect(plan.toTemplateId, 'b');
    expect(plan.mapped, <String>['model', 'serial']);
    expect(plan.retired, <String>['colour']);
    expect(plan.added, <String>['location']);
    expect(plan.restored, isEmpty);
    expect(plan.stillRetired, isEmpty);
    expect(plan.changesValues, isTrue);
  });

  test('a retired value whose key maps again is restored, not added', () {
    final TemplateChangePlan plan = TemplateChangePlan.between(
      fromTemplateId: 'b',
      toTemplateId: 'a',
      liveKeys: <String>['model', 'serial'],
      retiredKeys: <String>['colour'],
      targetFieldKeys: <String>['serial', 'model', 'colour'],
    );
    expect(plan.mapped, <String>['serial', 'model']);
    expect(plan.restored, <String>['colour']);
    expect(plan.added, isEmpty);
    expect(plan.retired, isEmpty);
  });

  test('a retired value the target does not declare either stays retired', () {
    final TemplateChangePlan plan = TemplateChangePlan.between(
      fromTemplateId: 'a',
      toTemplateId: 'c',
      liveKeys: <String>['model'],
      retiredKeys: <String>['colour'],
      targetFieldKeys: <String>['model'],
    );
    expect(plan.retired, isEmpty);
    expect(plan.stillRetired, <String>['colour']);
    expect(plan.changesValues, isFalse);
  });

  test('a record with no values maps nothing and starts every field empty', () {
    final TemplateChangePlan plan = TemplateChangePlan.between(
      fromTemplateId: 'a',
      toTemplateId: 'b',
      liveKeys: const <String>[],
      targetFieldKeys: <String>['model', 'serial'],
    );
    expect(plan.mapped, isEmpty);
    expect(plan.retired, isEmpty);
    expect(plan.added, <String>['model', 'serial']);
  });

  test('a target with no fields retires every live value', () {
    final TemplateChangePlan plan = TemplateChangePlan.between(
      fromTemplateId: 'a',
      toTemplateId: 'empty',
      liveKeys: <String>['model', 'serial'],
      targetFieldKeys: const <String>[],
    );
    expect(plan.retired, <String>['model', 'serial']);
    expect(plan.mapped, isEmpty);
    expect(plan.added, isEmpty);
  });

  test('a key listed twice is counted once', () {
    final TemplateChangePlan plan = TemplateChangePlan.between(
      fromTemplateId: 'a',
      toTemplateId: 'b',
      liveKeys: <String>['model', 'model'],
      targetFieldKeys: <String>['model', 'model', 'serial'],
    );
    expect(plan.mapped, <String>['model']);
    expect(plan.added, <String>['serial']);
  });

  test('forValues reads live and retired keys off the record values', () {
    final TemplateChangePlan plan = TemplateChangePlan.forValues(
      fromTemplateId: 'a',
      toTemplateId: 'b',
      values: const <RecordValue>[
        RecordValue(fieldKey: 'model', raw: 'Autoclave'),
        RecordValue(fieldKey: 'serial', raw: 'SN-1'),
        RecordValue(fieldKey: 'colour', raw: 'Blue', retired: true),
        RecordValue(fieldKey: 'notes', raw: 'Old', retired: true),
      ],
      targetFieldKeys: <String>['serial', 'colour', 'site'],
    );
    expect(plan.mapped, <String>['serial']);
    expect(plan.retired, <String>['model']);
    expect(plan.restored, <String>['colour']);
    expect(plan.added, <String>['site']);
    expect(plan.stillRetired, <String>['notes']);
  });

  test('plans with the same lists are equal', () {
    final TemplateChangePlan plan = TemplateChangePlan.between(
      fromTemplateId: 'a',
      toTemplateId: 'b',
      liveKeys: <String>['model'],
      targetFieldKeys: <String>['model'],
    );
    const TemplateChangePlan literal = TemplateChangePlan(
      fromTemplateId: 'a',
      toTemplateId: 'b',
      mapped: <String>['model'],
    );
    expect(plan, literal);
    expect(plan.hashCode, literal.hashCode);
    expect(plan.copyWith(), plan);
    expect(plan.copyWith(retired: <String>['x']), isNot(plan));
  });

  test('toString counts keys and never prints a value', () {
    const TemplateChangePlan plan = TemplateChangePlan(
      fromTemplateId: 'a',
      toTemplateId: 'b',
      mapped: <String>['model'],
    );
    expect(plan.toString(), contains('1 mapped'));
  });
}
