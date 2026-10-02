import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Whether the browser offers the native `BarcodeDetector` API, which decodes
/// without loading any script.
bool hasNativeBarcodeDetector() => globalContext.has('BarcodeDetector');
