import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/projects/domain/project_settings.dart';

void main() {
  test('malformed processing values are ignored rather than thrown', () {
    final ProjectSettings read = ProjectSettings.decode(
      '{"refineCaptions": "yes", "dailyRequestCap": -3, "locale": "",'
      ' "providerSelection": {"extractFields": {"provider": "openai"},'
      ' "transcribe": "backend", "readText": {"provider": "backend",'
      ' "model": "default"}},'
      ' "templatePins": {"room=A": 3, "": "t", "room=B": "template-b"}}',
    );

    expect(read.refineCaptions, isNull);
    expect(read.dailyRequestCap, isNull);
    expect(read.locale, isNull);
    expect(read.providerSelection, <String, ({String provider, String model})>{
      'readText': (provider: 'backend', model: 'default'),
    });
    expect(read.templatePins, <String, String>{'room=B': 'template-b'});
  });

  test('a processing value of the wrong shape is unset', () {
    final ProjectSettings read = ProjectSettings.decode(
      '{"dailyRequestCap": 2.5, "locale": 7,'
      ' "providerSelection": [], "templatePins": "room=A"}',
    );

    expect(read, ProjectSettings.defaults);
  });

  test('empty maps survive a round trip as empty, not unset', () {
    const ProjectSettings empty = ProjectSettings(
      providerSelection: <String, ({String provider, String model})>{},
      templatePins: <String, String>{},
    );

    final ProjectSettings read = ProjectSettings.decode(empty.encode());

    expect(read, empty);
    expect(read.templatePins, isEmpty);
    expect(read.providerSelection, isEmpty);
    expect(read, isNot(ProjectSettings.defaults));
  });
}
