import 'dart:async';

import 'package:tapture/core/ai/stt_result.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/errors/failure.dart';

/// A recogniser a test drives by hand: it hears what the test says it
/// heard, when the test says so (FE-TEST-03).
final class FakeSttService implements SttService {
  /// Creates the fake. [isSupported] false hides every microphone.
  FakeSttService({this.isSupported = true});

  @override
  final bool isSupported;

  /// Every listen asked for, in order.
  final List<({String languageTag, bool onDeviceOnly})> listens =
      <({String languageTag, bool onDeviceOnly})>[];

  /// How many times [stop] was called.
  int stops = 0;

  /// How many listens were cancelled, by [cancel] or by the listener
  /// cancelling its subscription.
  int cancels = 0;

  StreamController<SttResult>? _current;
  String _languageTag = '';

  /// Whether a listen is open.
  bool get isListening => _current != null && !_current!.isClosed;

  @override
  Stream<SttResult> listen({
    required String languageTag,
    bool onDeviceOnly = false,
  }) {
    listens.add((languageTag: languageTag, onDeviceOnly: onDeviceOnly));
    final StreamController<SttResult>? previous = _current;
    if (previous != null && !previous.isClosed) {
      unawaited(previous.close());
    }
    late final StreamController<SttResult> controller;
    controller = StreamController<SttResult>(
      onCancel: () {
        if (!controller.isClosed) {
          cancels++;
        }
        if (identical(_current, controller)) {
          _current = null;
        }
      },
    );
    _current = controller;
    _languageTag = languageTag;
    return controller.stream;
  }

  /// The microphone opened.
  void open() => hear('');

  /// Words heard so far.
  void hear(String words) {
    _current?.add(
      SttResult(text: words, isFinal: false, languageTag: _languageTag),
    );
  }

  /// The last words, then the listen ends.
  Future<void> finish(String words) async {
    final StreamController<SttResult>? current = _current;
    if (current == null) {
      return;
    }
    current.add(
      SttResult(text: words, isFinal: true, languageTag: _languageTag),
    );
    await current.close();
  }

  /// The listen ends with [failure] and no words.
  Future<void> fail(Failure failure) async {
    final StreamController<SttResult>? current = _current;
    if (current == null) {
      return;
    }
    current.addError(failure);
    await current.close();
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> cancel() async {
    final StreamController<SttResult>? current = _current;
    _current = null;
    if (current != null && !current.isClosed) {
      cancels++;
      await current.close();
    }
  }
}
