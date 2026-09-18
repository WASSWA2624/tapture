import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tapture/core/ai/stt_result.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the stand-in', () {
    test('is the default and cannot listen', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final SttService service = container.read(sttServiceProvider);
      expect(service.isSupported, isFalse);
      await expectLater(
        service.listen(languageTag: 'en'),
        emitsError(
          isA<ProviderFailure>().having(
            (ProviderFailure f) => f.message,
            'message',
            Copy.dictationUnavailable,
          ),
        ),
      );
    });
  });

  group('the platform service', () {
    test(
      'opens, reports partials, then one final result, then closes',
      () async {
        final _Recogniser speech = _Recogniser();
        final SttService service = SttService.withRecogniser(speech);
        final List<SttResult> seen = <SttResult>[];
        final Completer<void> done = Completer<void>();
        service
            .listen(languageTag: 'lg-UG')
            .listen(seen.add, onDone: done.complete);
        await _settle();
        expect(speech.options?.localeId, 'lg-UG');
        expect(speech.options?.listenMode, ListenMode.dictation);
        expect(speech.options?.onDevice, isFalse);
        speech.say('the pump', last: false);
        speech.say('the pump leaks', last: true);
        await done.future;
        expect(seen.map((SttResult r) => r.text), <String>[
          '',
          'the pump',
          'the pump leaks',
        ]);
        expect(seen.last.isFinal, isTrue);
        expect(seen.last.languageTag, 'lg-UG');
      },
    );

    test('offline by choice asks for recognition on the device', () async {
      final _Recogniser speech = _Recogniser();
      final SttService service = SttService.withRecogniser(speech);
      service.listen(languageTag: 'en', onDeviceOnly: true).listen((_) {});
      await _settle();
      expect(speech.options?.onDevice, isTrue);
    });

    test('a refused microphone says so, and the next tap asks again', () async {
      final _Recogniser speech = _Recogniser(ready: false, permitted: false);
      final SttService service = SttService.withRecogniser(speech);
      await expectLater(
        service.listen(languageTag: 'en'),
        emitsError(
          isA<PermissionFailure>().having(
            (PermissionFailure f) => f.message,
            'message',
            Copy.dictationNoMicrophone,
          ),
        ),
      );
      speech
        ..ready = true
        ..permitted = true;
      service.listen(languageTag: 'en').listen((_) {});
      await _settle();
      expect(speech.initialised, 2);
      expect(speech.listens, 1);
    });

    test('a recogniser that will not start is reported unavailable', () async {
      final SttService service = SttService.withRecogniser(
        _Recogniser(ready: false),
      );
      await expectLater(
        service.listen(languageTag: 'en'),
        emitsError(
          isA<ProviderFailure>().having(
            (ProviderFailure f) => f.message,
            'message',
            Copy.dictationUnavailable,
          ),
        ),
      );
    });

    test('silence ends the listen with nothing heard', () async {
      final _Recogniser speech = _Recogniser();
      final SttService service = SttService.withRecogniser(speech);
      final Future<void> heard = expectLater(
        service.listen(languageTag: 'en').where((SttResult r) => r.isFinal),
        emitsError(
          isA<CancelledFailure>().having(
            (CancelledFailure f) => f.message,
            'message',
            Copy.dictationNothingHeard,
          ),
        ),
      );
      await _settle();
      speech.fail('error_no_match');
      await heard;
    });

    test('an error after words keeps the words', () async {
      final _Recogniser speech = _Recogniser();
      final SttService service = SttService.withRecogniser(speech);
      final Future<List<SttResult>> all = service
          .listen(languageTag: 'en')
          .toList();
      await _settle();
      speech.say('meter is broken', last: false);
      speech.fail('network');
      final List<SttResult> results = await all;
      expect(results.last.isFinal, isTrue);
      expect(results.last.text, 'meter is broken');
    });

    test('stop hands over the words heard when the platform is done', () async {
      final _Recogniser speech = _Recogniser();
      final SttService service = SttService.withRecogniser(speech);
      final Future<List<SttResult>> all = service
          .listen(languageTag: 'en')
          .toList();
      await _settle();
      speech.say('almost there', last: false);
      await service.stop();
      expect(speech.stops, 1);
      speech.status(SpeechToText.doneStatus);
      final List<SttResult> results = await all;
      expect(results.last.isFinal, isTrue);
      expect(results.last.text, 'almost there');
    });

    test('cancelling the subscription cancels the recognition', () async {
      final _Recogniser speech = _Recogniser();
      final SttService service = SttService.withRecogniser(speech);
      final StreamSubscription<SttResult> sub = service
          .listen(languageTag: 'en')
          .listen((_) {});
      await _settle();
      await sub.cancel();
      await _settle();
      expect(speech.cancels, 1);
    });

    test(
      'a second listen ends the first with its words, then starts',
      () async {
        final _Recogniser speech = _Recogniser();
        final SttService service = SttService.withRecogniser(speech);
        final Future<List<SttResult>> first = service
            .listen(languageTag: 'en')
            .toList();
        await _settle();
        speech.say('first field', last: false);
        final List<SttResult> second = <SttResult>[];
        service.listen(languageTag: 'en').listen(second.add);
        await _settle();
        final List<SttResult> firstResults = await first;
        expect(firstResults.last.isFinal, isTrue);
        expect(firstResults.last.text, 'first field');
        expect(speech.cancels, 1);
        expect(speech.listens, 2);
        // The old recognition's stop and abort do not end the new listen.
        expect(second.single.isFinal, isFalse);
        speech.say('second field', last: true);
        await _settle();
        expect(second.last.text, 'second field');
        expect(second.last.isFinal, isTrue);
      },
    );
  });
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// A recogniser scripted by the test. It reports the statuses and errors
/// the real plugin does, when the test says so.
final class _Recogniser extends SpeechToText {
  _Recogniser({this.ready = true, this.permitted = true})
    : super.withMethodChannel();

  bool ready;
  bool permitted;
  int initialised = 0;
  int listens = 0;
  int stops = 0;
  int cancels = 0;
  SpeechListenOptions? options;
  SpeechStatusListener? _status;
  SpeechErrorListener? _error;
  SpeechResultListener? _result;
  bool _live = false;

  void say(String words, {required bool last}) {
    _result?.call(
      SpeechRecognitionResult(<SpeechRecognitionWords>[
        SpeechRecognitionWords(words, null, 0.9),
      ], last ? ResultType.finalResult.value : ResultType.partial.value),
    );
  }

  void fail(String name) {
    _error?.call(SpeechRecognitionError(name, true));
  }

  void status(String name) => _status?.call(name);

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    Object? debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    initialised++;
    _status = onStatus;
    _error = onError;
    return ready;
  }

  @override
  Future<bool> get hasPermission async => permitted;

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    Object? cancelOnError = false,
    Object? partialResults = true,
    Object? onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    Object? sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    listens++;
    options = listenOptions;
    _result = onResult;
    _live = true;
    _status?.call(SpeechToText.listeningStatus);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    if (_live) {
      _live = false;
      // The platform reports the stop, then an abort, as the real one does.
      _status?.call(SpeechToText.notListeningStatus);
      _error?.call(SpeechRecognitionError('aborted', false));
    }
  }
}
