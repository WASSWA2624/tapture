import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/core/ai/stt_result.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

/// Mic affordance for long-text fields: listening state and live partials.
final class VoiceInputButton extends StatefulWidget {
  /// Creates a voice button.
  const VoiceInputButton({
    required this.stt,
    required this.languageTag,
    required this.onFinal,
    this.permissions,
    this.onPartial,
    super.key,
  });

  /// Speech port.
  final SttService stt;

  /// Voice language from settings.
  final String languageTag;

  /// Final editable text — never auto-submitted.
  final ValueChanged<String> onFinal;

  /// Live partial text.
  final ValueChanged<String>? onPartial;

  /// Optional permission check before listen.
  final PermissionsService? permissions;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  bool _listening = false;
  String _partial = '';
  StreamSubscription<SttResult>? _sub;

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await widget.stt.stop();
      setState(() => _listening = false);
      return;
    }
    final PermissionsService? permissions = widget.permissions;
    if (permissions != null) {
      final Result<PermissionState> status = await permissions.request(
        AppPermission.microphone,
      );
      final bool granted = status.fold(
        (Failure _) => false,
        (PermissionState s) => s == PermissionState.granted,
      );
      if (!granted) {
        return;
      }
    }
    setState(() {
      _listening = true;
      _partial = '';
    });
    _sub = widget.stt
        .listen(languageTag: widget.languageTag)
        .listen(
          (SttResult result) {
            if (result.isFinal) {
              widget.onFinal(result.text);
              setState(() {
                _listening = false;
                _partial = '';
              });
            } else {
              widget.onPartial?.call(result.text);
              setState(() => _partial = result.text);
            }
          },
          onError: (Object _) {
            setState(() => _listening = false);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: _listening ? Copy.stopDictating('') : Copy.dictateInto(''),
          onPressed: _toggle,
          icon: Icon(_listening ? Icons.mic : Icons.mic_none),
        ),
        if (_listening) const Text(Copy.captureListening),
        if (_partial.isNotEmpty) Text(_partial),
      ],
    );
  }
}
