import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/template_version.dart';

import '../../../support/factories.dart';

void main() {
  test('number is the stored template version', () {
    expect(TemplateVersion(template: aTemplate(version: 3)).number, 3);
  });
}
