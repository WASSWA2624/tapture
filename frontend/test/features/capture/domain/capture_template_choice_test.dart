import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/capture_template_choice.dart';

void main() {
  const List<String> ids = <String>['t1', 't2', 't3'];

  test('the home selection wins when it belongs to the project', () {
    expect(
      CaptureTemplateChoice.resolve(
        templateIds: ids,
        selection: 't2',
        sessionTemplateId: 't3',
        choice: 'manual',
      ),
      't2',
    );
  });

  test('the session template is kept when there is no selection', () {
    expect(
      CaptureTemplateChoice.resolve(
        templateIds: ids,
        selection: '',
        sessionTemplateId: 't3',
        choice: 'auto',
      ),
      't3',
    );
  });

  test('an automatic project defaults to its first template', () {
    for (final String? choice in <String?>[null, 'auto']) {
      expect(
        CaptureTemplateChoice.resolve(
          templateIds: ids,
          selection: '',
          sessionTemplateId: '',
          choice: choice,
        ),
        't1',
        reason: '$choice',
      );
    }
  });

  test('a manual project waits for a pick', () {
    for (final String choice in <String>['manual', 'suggest']) {
      expect(
        CaptureTemplateChoice.resolve(
          templateIds: ids,
          selection: '',
          sessionTemplateId: '',
          choice: choice,
        ),
        isNull,
        reason: choice,
      );
    }
  });

  test('another project template never applies', () {
    expect(
      CaptureTemplateChoice.resolve(
        templateIds: ids,
        selection: 'other-project-template',
        sessionTemplateId: 'another-one',
        choice: 'manual',
      ),
      isNull,
    );
    expect(
      CaptureTemplateChoice.resolve(
        templateIds: const <String>[],
        selection: 't1',
        sessionTemplateId: 't1',
        choice: null,
      ),
      isNull,
    );
  });
}
