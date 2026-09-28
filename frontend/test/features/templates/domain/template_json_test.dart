import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/domain/template_json.dart';

import '../../../support/factories.dart';

void main() {
  test(
    'the shared codec creates a new template without copying migration history',
    () {
      final TemplateDef source = aTemplate().copyWith(
        detection: const <String, Object?>{
          '_tapture_versions': <String, Object?>{'1': <String, Object?>{}},
          'kind': 'asset',
        },
      );
      final Result<TemplateDef> result = TemplateJson.decode(
        TemplateJson.encode(source),
        projectId: 'another-project',
      );
      expect(result, isA<Success<TemplateDef>>());
      final TemplateDef decoded = (result as Success<TemplateDef>).value;
      expect(decoded.id, isEmpty);
      expect(decoded.version, 1);
      expect(decoded.projectId, 'another-project');
      expect(decoded.fields, source.fields);
      expect(decoded.detection, <String, Object?>{'kind': 'asset'});
    },
  );
}
