import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:xml/xml.dart';

/// Bounded Office ZIP reader that replaces selected XML parts and preserves others.
final class OoxmlPackage {
  OoxmlPackage._(this._archive);

  /// Checks names and declared sizes before inflating any document content.
  factory OoxmlPackage.open(Uint8List bytes) {
    if (bytes.isEmpty ||
        bytes.length > AppConstants.imports.spreadsheetMaxBytes) {
      throw invalid();
    }
    final Archive archive;
    try {
      final ZipDirectory directory = ZipDirectory.read(InputStream(bytes));
      var total = 0;
      final Set<String> names = <String>{};
      for (final ZipFileHeader header in directory.fileHeaders) {
        final String name = header.filename;
        safeRelativePath(
          name.endsWith('/') ? name.substring(0, name.length - 1) : name,
        );
        final int size = header.uncompressedSize ?? -1;
        total += size;
        final int mode = (header.externalFileAttributes ?? 0) >> 16;
        if (name.contains('\u0000') ||
            !names.add(name) ||
            size < 0 ||
            total > AppConstants.imports.archiveUncompressedMaxBytes ||
            (mode & 0xf000) == 0xa000 ||
            (header.generalPurposeBitFlag & 1) != 0) {
          throw invalid();
        }
      }
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw invalid();
    }
    if (archive.findFile('[Content_Types].xml') == null ||
        archive.findFile('_rels/.rels') == null) {
      throw invalid();
    }
    return OoxmlPackage._(archive);
  }

  final Archive _archive;
  final Map<String, Uint8List> _changed = <String, Uint8List>{};

  /// Original part names, in original archive order.
  Iterable<String> get names => _archive.files.map((file) => file.name);

  /// A part's original bytes, or its replacement when one was supplied.
  Uint8List part(String name) {
    if (_changed[name] case final Uint8List bytes) return bytes;
    final ArchiveFile? file = _archive.findFile(name);
    if (file == null || file.size > AppConstants.imports.spreadsheetMaxBytes) {
      throw invalid();
    }
    try {
      return Uint8List.fromList(file.content as List<int>);
    } on Object {
      throw invalid();
    }
  }

  /// Namespace-aware parsing; document types and external entity declarations fail.
  XmlDocument xml(String name) {
    try {
      final String source = utf8.decode(part(name));
      final XmlDocument document = XmlDocument.parse(source);
      if (document.children.any((node) => node is XmlDoctype)) {
        throw invalid();
      }
      return document;
    } on Failure {
      rethrow;
    } on Object {
      throw invalid();
    }
  }

  /// Changes only [name]; all other package parts retain their original contents.
  void replaceXml(String name, XmlDocument document) {
    if (_archive.findFile(name) == null) throw invalid();
    _changed[name] = Uint8List.fromList(utf8.encode(document.toXmlString()));
  }

  /// Encodes a fresh copy; the caller's source buffer is never mutated.
  Uint8List encode() {
    final Archive result = Archive();
    for (final ArchiveFile file in _archive.files) {
      final Uint8List? replacement = _changed[file.name];
      if (replacement == null) {
        result.addFile(file);
      } else {
        result.addFile(
          ArchiveFile(file.name, replacement.length, replacement)
            ..lastModTime = file.lastModTime
            ..mode = file.mode,
        );
      }
    }
    return Uint8List.fromList(ZipEncoder().encode(result)!);
  }

  /// Shared typed refusal for corrupt or unsupported source templates.
  static ValidationFailure invalid() => ValidationFailure(
    localizedMessage: DomainCopy.messages.templatesImportInvalid,
    localizedRecovery: DomainCopy.messages.templatesImportInvalidRecovery,
  );
}
