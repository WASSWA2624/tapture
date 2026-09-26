import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/template_choice_needed.dart';

void main() {
  test('the question carries the record, the shortlist and the pin key', () {
    const TemplateChoiceNeeded needed = TemplateChoiceNeeded(
      recordId: 'record-1',
      projectId: 'project-1',
      shortlist: <({String templateId, String label})>[
        (templateId: 'pump', label: 'Pump'),
        (templateId: 'motor', label: 'Motor'),
      ],
      pinKey: 'room=Plant room',
    );

    expect(needed.modelMayDecide, isFalse, reason: 'the operator by default');
    expect(needed.recordId, 'record-1');
    expect(needed.projectId, 'project-1');
    expect(needed.shortlist.first, (templateId: 'pump', label: 'Pump'));
    expect(needed.pinKey, 'room=Plant room');
  });

  test('a record with no context has no pin key', () {
    const TemplateChoiceNeeded needed = TemplateChoiceNeeded(
      recordId: 'record-1',
      projectId: 'project-1',
      shortlist: <({String templateId, String label})>[],
    );
    const TemplateChoice choice = (templateId: 'pump', pin: false);

    expect(needed.pinKey, isNull);
    expect(choice.pin, isFalse);
  });
}
