import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tapture/core/ai/stt_result.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/errors/failure.dart';

import 'dictation_phase.dart';

/// One field's dictation: opens the recogniser on a tap, hands the words
/// heard so far to [onPartial] and the last of them to [onSpoken].
///
/// Disposing it cancels a listen that is still running, so a field that
/// leaves the screen never keeps the microphone open.
final class DictationSession extends ChangeNotifier {
  /// Creates a session. Nothing listens until [start].
  DictationSession({
    required this.onSpoken,
    required this.onFailure,
    this.onPartial,
  });

  /// Receives the final words of a listen, exactly as recognised.
  final ValueChanged<String> onSpoken;

  /// Receives why a listen ended without words.
  final ValueChanged<Failure> onFailure;

  /// Receives the words heard so far, each time they grow. The field shows
  /// them in the input itself.
  final ValueChanged<String>? onPartial;

  DictationPhase _phase = DictationPhase.idle;
  SttService? _service;
  StreamSubscription<SttResult>? _subscription;
  bool _disposed = false;

  /// Where the listen is.
  DictationPhase get phase => _phase;

  /// Whether a listen is under way.
  bool get isActive => _phase != DictationPhase.idle;

  /// Starts listening, or stops when a listen is already under way.
  void toggle(
    SttService service, {
    required String languageTag,
    bool onDeviceOnly = false,
  }) {
    if (isActive) {
      unawaited(stop());
      return;
    }
    start(service, languageTag: languageTag, onDeviceOnly: onDeviceOnly);
  }

  /// Opens the recogniser. A listen already under way here is dropped.
  void start(
    SttService service, {
    required String languageTag,
    bool onDeviceOnly = false,
  }) {
    if (_disposed) {
      return;
    }
    unawaited(_subscription?.cancel());
    _service = service;
    _set(DictationPhase.starting);
    _subscription = service
        .listen(languageTag: languageTag, onDeviceOnly: onDeviceOnly)
        .listen(_onResult, onError: _onError, onDone: _onDone);
  }

  /// Stops listening. Words already heard still reach the field.
  Future<void> stop() async {
    final SttService? service = _service;
    if (!isActive || service == null) {
      return;
    }
    if (_phase == DictationPhase.starting) {
      // Nothing heard yet, so there is nothing to wait for.
      await cancel();
      return;
    }
    _set(DictationPhase.finishing);
    await service.stop();
  }

  /// Stops listening and drops what was not yet final.
  Future<void> cancel() async {
    final StreamSubscription<SttResult>? subscription = _subscription;
    _subscription = null;
    _set(DictationPhase.idle);
    await subscription?.cancel();
  }

  void _onResult(SttResult result) {
    if (result.isFinal) {
      if (result.text.trim().isNotEmpty) {
        onSpoken(result.text);
      }
      return;
    }
    if (result.text.isNotEmpty) {
      onPartial?.call(result.text);
    }
    _set(
      _phase == DictationPhase.finishing
          ? DictationPhase.finishing
          : DictationPhase.listening,
    );
  }

  void _onError(Object error) {
    onFailure(Failure.from(error));
  }

  void _onDone() {
    _subscription = null;
    _set(DictationPhase.idle);
  }

  /// Notifies only on a real change, so words arriving do not rebuild the
  /// field: they reach it through its controller.
  void _set(DictationPhase phase) {
    if (_disposed || phase == _phase) {
      return;
    }
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
