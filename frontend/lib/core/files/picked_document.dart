import 'dart:io';
import 'dart:typed_data';

part 'picked_bytes.dart';
part 'picked_file.dart';

/// One document the operator chose through [DocumentPicker]: a file on a
/// device, or its bytes in a browser, which has no file system.
///
/// Variants live in this library so the type stays sealed while each class
/// keeps its own file (FE-STR-06).
sealed class PickedDocument {
  /// Creates a picked document named [name].
  const PickedDocument(this.name);

  /// The file name the operator chose, as data (FE-SEC-05).
  final String name;

  /// How many bytes the document holds.
  int get byteLength;
}
