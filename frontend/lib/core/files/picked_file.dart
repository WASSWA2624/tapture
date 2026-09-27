part of 'picked_document.dart';

/// A chosen document as a file on this device: the picker's own copy on a
/// phone ([isCopy]), which the caller deletes when it is done with it, or
/// the operator's own file on a desktop, which it must leave alone.
final class PickedFile extends PickedDocument {
  /// Creates a picked file.
  const PickedFile(
    this.file,
    super.name,
    this.byteLength, {
    this.isCopy = false,
  });

  /// Where the file sits.
  final File file;

  @override
  final int byteLength;

  /// Whether [file] is a copy the picker made for this app alone.
  final bool isCopy;
}
