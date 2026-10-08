import 'dart:typed_data';

/// Browser-only font configuration, excluded from native test execution.
void useScreenFontMetrics() => throw UnsupportedError(
  'Browser font configuration requires a browser target.',
);

/// Browser-only font fixture loader, excluded from native test execution.
Future<ByteData> fetchScreenFont(Uri uri) =>
    throw UnsupportedError('Browser font loading requires a browser target.');
