import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';

import '../../../support/factories.dart';

void main() {
  test('copyWith replaces fields and leaves identity put when omitted', () {
    final TemplateDef original = aTemplate(name: 'Alpha');
    final TemplateDef edited = original.copyWith(
      name: 'Alpha v2',
      fields: const <FieldDef>[
        FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
      ],
      identityFieldKeys: const <String>['serial'],
    );
    expect(edited.id, original.id);
    expect(edited.templateKey, original.templateKey);
    expect(edited.name, 'Alpha v2');
    expect(edited.fields.single.fieldKey, 'serial');
    expect(edited.identityFieldKeys, <String>['serial']);
    expect(edited.version, original.version);
    expect(edited.projectId, original.projectId);
  });

  test('two templates with the same attributes are equal', () {
    expect(aTemplate(), aTemplate());
    expect(aTemplate().hashCode, aTemplate().hashCode);
    expect(aTemplate(name: 'Other'), isNot(aTemplate()));
  });
}
