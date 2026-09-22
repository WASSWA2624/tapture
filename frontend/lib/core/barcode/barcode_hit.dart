part of 'barcode_scanner_service.dart';

/// One decoded barcode inside the scan region.
final class BarcodeHit {
  /// Creates a hit.
  const BarcodeHit({
    required this.rawValue,
    required this.format,
    this.confidence,
  });

  /// Decoded payload, treated as data never as a path (FE-SEC-05).
  final String rawValue;

  /// Symbology name (for example `code128`, `qr`).
  final String format;

  /// Optional decoder confidence 0–1.
  final double? confidence;
}
