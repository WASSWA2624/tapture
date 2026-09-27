part of 'picked_document.dart';

/// A chosen document read into memory, as a browser hands it over.
final class PickedBytes extends PickedDocument {
  /// Creates picked bytes.
  const PickedBytes(this.bytes, super.name);

  /// The document's content.
  final Uint8List bytes;

  @override
  int get byteLength => bytes.length;
}
