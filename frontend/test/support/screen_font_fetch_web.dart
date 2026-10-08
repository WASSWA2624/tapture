import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter_test/flutter_test.dart';

/// Keeps the browser test environment while respecting loaded UI font faces.
void useScreenFontMetrics() {
  final ui_web.TestEnvironment current = ui_web.TestEnvironment.instance;
  if (!current.forceTestFonts) return;
  ui_web.TestEnvironment.setUp(
    ui_web.TestEnvironment(
      ignorePlatformMessages: current.ignorePlatformMessages,
      forceTestFonts: false,
      disableFontFallbacks: current.disableFontFallbacks,
      keepSemanticsDisabledOnUpdate: current.keepSemanticsDisabledOnUpdate,
      defaultToTestUrlStrategy: current.defaultToTestUrlStrategy,
    ),
  );
}

/// Reads only same-origin SDK font fixtures prepared by the browser runner.
Future<ByteData> fetchScreenFont(Uri uri) async {
  if (uri.origin != Uri.base.origin) {
    throw TestFailure('Screen font fixtures must use the test server origin.');
  }
  final _FontResponse response = await _fetch(uri.toString()).toDart;
  if (!response.ok) {
    throw TestFailure('Screen font fixture failed: $uri (${response.status}).');
  }
  final JSArrayBuffer buffer = await response.arrayBuffer().toDart;
  return ByteData.view(buffer.toDart);
}

@JS('fetch')
external JSPromise<_FontResponse> _fetch(String url);

extension type _FontResponse._(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}
