part of 'picked_document.dart';

/// A chosen document as a file on this device: the picker's own copy,
/// which the caller deletes when it is done with it.
final class PickedFile extends PickedDocument {
  /// Creates a picked file.
  const PickedFile(this.file, super.name, this.byteLength);

  /// Where the copy sits.
  final File file;

  @override
  final int byteLength;
}
