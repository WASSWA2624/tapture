import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/projects/domain/project_name_validation.dart';

void main() {
  test('a project name requires text after trimming whitespace', () {
    for (final String name in <String>['', ' ', '\t\n']) {
      expect(ProjectNameValidation.isValid(name), isFalse);
    }
    for (final String name in <String>['Project', '  Project  ', '東京', 'A/B']) {
      expect(ProjectNameValidation.isValid(name), isTrue);
    }
  });
}
