import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/merge_templates.dart';

void main() {
  test('a record keeps the version it was captured under', () {
    expect(
      MergeTemplates.resolve(
        localVersion: 1,
        incomingVersion: 1,
        capturedVersion: 1,
        keepBoth: false,
      ).action,
      TemplateAction.same,
    );
    final TemplateMerge chosen = MergeTemplates.resolve(
      localVersion: 1,
      incomingVersion: 2,
      capturedVersion: 1,
      keepBoth: false,
    );
    final TemplateMerge both = MergeTemplates.resolve(
      localVersion: 1,
      incomingVersion: 2,
      capturedVersion: 1,
      keepBoth: true,
    );
    expect(chosen.action, TemplateAction.chooseOne);
    expect(both.action, TemplateAction.keepBoth);
    expect(chosen.recordVersion, 1);
    expect(both.recordVersion, 1);
  });
}
