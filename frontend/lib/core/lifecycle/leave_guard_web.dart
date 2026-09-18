import 'dart:js_interop';

import 'leave_guard.dart';

/// The browser leave prompt, armed while any owner holds.
LeaveGuard platformLeaveGuard() => _BrowserLeaveGuard();

final class _BrowserLeaveGuard implements LeaveGuard {
  final Set<Object> _owners = <Object>{};
  JSFunction? _listener;

  @override
  void hold(Object owner) {
    _owners.add(owner);
    _sync();
  }

  @override
  void release(Object owner) {
    _owners.remove(owner);
    _sync();
  }

  @override
  bool get isHeld => _owners.isNotEmpty;

  void _sync() {
    if (isHeld) {
      _listen();
    } else {
      _ignore();
    }
  }

  void _listen() {
    if (_listener != null) {
      return;
    }
    _listener = ((JSObject event) {
      _BeforeUnloadEvent._(event)
        ..preventDefault()
        ..returnValue = '';
    }).toJS;
    _window.addEventListener('beforeunload', _listener!);
  }

  void _ignore() {
    final JSFunction? listener = _listener;
    if (listener == null) {
      return;
    }
    _window.removeEventListener('beforeunload', listener);
    _listener = null;
  }
}

@JS('window')
external _Window get _window;

extension type _Window._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

extension type _BeforeUnloadEvent._(JSObject _) implements JSObject {
  external void preventDefault();
  external set returnValue(String value);
}
