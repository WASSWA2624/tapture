import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/fields/dictation_phase.dart';
import 'package:tapture/core/widgets/fields/dictation_session.dart';

import '../../../support/fakes/fake_stt_service.dart';

void main() {
  late FakeSttService speech;
  late List<String> spoken;
  late List<Failure> failures;
  late DictationSession session;

  setUp(() {
    speech = FakeSttService();
    spoken = <String>[];
    failures = <Failure>[];
    session = DictationSession(onSpoken: spoken.add, onFailure: failures.add);
  });

  tearDown(() => session.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a tap opens the microphone, then words are heard', () async {
    session.toggle(speech, languageTag: 'sw', onDeviceOnly: true);
    expect(session.phase, DictationPhase.starting);
    expect(speech.listens.single, (languageTag: 'sw', onDeviceOnly: true));
    speech.open();
    await settle();
    expect(session.phase, DictationPhase.listening);
    speech.hear('the pump');
    await settle();
    expect(session.heard, 'the pump');
  });

  test('the final words are handed over and the session goes idle', () async {
    session.start(speech, languageTag: 'en');
    speech.hear('it leaks');
    await speech.finish('it leaks at night');
    await settle();
    expect(spoken, <String>['it leaks at night']);
    expect(session.phase, DictationPhase.idle);
    expect(session.heard, isEmpty);
  });

  test('a second tap while listening stops and waits for the words', () async {
    session.start(speech, languageTag: 'en');
    speech.hear('almost');
    await settle();
    session.toggle(speech, languageTag: 'en');
    await settle();
    expect(session.phase, DictationPhase.finishing);
    expect(speech.stops, 1);
    await speech.finish('almost done');
    await settle();
    expect(spoken, <String>['almost done']);
    expect(session.phase, DictationPhase.idle);
  });

  test('a tap before the microphone opens cancels outright', () async {
    session.start(speech, languageTag: 'en');
    session.toggle(speech, languageTag: 'en');
    await settle();
    expect(session.phase, DictationPhase.idle);
    expect(speech.cancels, 1);
    expect(speech.stops, 0);
  });

  test('a failure is reported and nothing is inserted', () async {
    session.start(speech, languageTag: 'en');
    await speech.fail(const PermissionFailure());
    await settle();
    expect(failures.single, isA<PermissionFailure>());
    expect(spoken, isEmpty);
    expect(session.phase, DictationPhase.idle);
  });

  test('disposing mid-listen cancels the recognition', () async {
    final DictationSession leaving = DictationSession(
      onSpoken: spoken.add,
      onFailure: failures.add,
    );
    leaving.start(speech, languageTag: 'en');
    speech.hear('half a sen');
    await settle();
    leaving.dispose();
    await settle();
    expect(speech.cancels, 1);
    expect(speech.isListening, isFalse);
    expect(spoken, isEmpty);
  });
}
