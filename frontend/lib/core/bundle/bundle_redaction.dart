import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/constants/document_assets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/logging/logging_stub.dart'
    if (dart.library.io) 'package:tapture/core/logging/logging_io.dart'
    as platform;

import 'bundle_payload_scanner.dart';

/// Keeps secrets out of a bundle (task 019, FE-SEC-02).
///
/// [excluded] columns are never serialised. [assertClean] runs the same
/// patterns as `tool/secret_patterns.yaml`, passed in as that file's text
/// so there is not a second copy of the patterns.
final class BundleRedaction {
  /// Creates a checker from the shared pattern file's [yaml] text.
  BundleRedaction.parse(String yaml) : _patterns = _compile(yaml);

  /// Loads the same canonical pattern file used by build-time checks.
  static Future<String> loadPatterns() async {
    final String? local = (await runIsolate<Object?, String?>(
      _readPatterns,
      null,
    )).getOrThrow();
    return local ?? rootBundle.loadString(DocumentAssets.secretPatterns);
  }

  /// Columns and settings keys never written into a bundle.
  static const Set<String> excluded = <String>{
    'password',
    'api_key',
    'token',
    'secret',
    'credential',
    'device_secret',
    'access_token',
    'refresh_token',
    'client_secret',
    'private_key',
    'secret_key',
  };

  static final RegExp _keySeparators = RegExp(r'[_\-\s]');
  static final Set<String> _normalizedExcluded = excluded
      .map((String key) => key.replaceAll(_keySeparators, ''))
      .toSet();

  final List<({String name, RegExp pattern})> _patterns;

  /// Drops secret-bearing keys recursively, including JSON settings values.
  Map<String, Object?> strip(Map<String, Object?> row) => redact(row);

  /// Removes secret keys without loading pattern matchers or changing a source row.
  static Map<String, Object?> redact(Map<String, Object?> row) {
    return <String, Object?>{
      for (final MapEntry<String, Object?> entry in row.entries)
        if (!_normalizedExcluded.contains(
          entry.key.toLowerCase().replaceAll(_keySeparators, ''),
        ))
          entry.key: _stripValue(
            entry.value,
            decodeJson: entry.key == 'settings',
          ),
    };
  }

  static Object? _stripValue(Object? value, {bool decodeJson = false}) {
    if (value is Map<String, Object?>) {
      return redact(value);
    }
    if (value is List<Object?>) {
      return value.map(_stripValue).toList();
    }
    if (decodeJson && value is String) {
      try {
        return jsonEncode(_stripValue(jsonDecode(value)));
      } on FormatException {
        // Malformed application settings retain their original value and
        // still pass the secret-shaped payload scan before publication.
      }
    }
    return value;
  }

  /// Throws when [text] carries a secret-shaped value.
  void assertClean(String text) => _assertClean(text, text);

  void _assertClean(String raw, String base64View) {
    for (final ({String name, RegExp pattern}) entry in _patterns) {
      if (entry.pattern.hasMatch(
        entry.name == 'long_base64' ? base64View : raw,
      )) {
        throw ValidationFailure(
          localizedMessage: Copy.messages.failureTheBundleContainsASecretAndWas,
          localizedRecovery:
              Copy.messages.failureRemoveTheSecretAndExportTheBundle,
        );
      }
    }
  }

  /// Strictly scans bytes without PDF lexical adjustments.
  /// Binary payloads are decoded one byte per character, preserving ASCII
  /// secret shapes without mis-decoding arbitrary image bytes.
  void assertCleanBytes(List<int> bytes) => assertClean(latin1.decode(bytes));

  /// Creates a bounded scan of one payload with PDF dictionary-name boundaries.
  BundlePayloadScanner payloadScanner() => BundlePayloadScanner(_assertClean);

  /// Checks payloads and generated nested archives such as XLSX before zipping.
  /// Bounded nesting and content limits fail closed on opaque or oversized data.
  void assertCleanPayload(List<int> bytes) =>
      _payload(bytes, 0, _PayloadBudget());

  void _payload(List<int> bytes, int depth, _PayloadBudget budget) {
    payloadScanner()
      ..add(bytes)
      ..finish();
    if (bytes.length < 4 ||
        !looksLikeZip(Uint8List.fromList(bytes.take(4).toList()))) {
      return;
    }
    if (depth >= 4) {
      throw ValidationFailure(
        localizedMessage:
            Copy.messages.failureTheBundleHasTooManyNestedArchives,
      );
    }
    final Uint8List source = bytes is Uint8List
        ? bytes
        : Uint8List.fromList(bytes);
    if (checkZipDirectory(
          length: source.length,
          read: (int offset, int length) => Uint8List.sublistView(
            source,
            offset,
            (offset + length).clamp(offset, source.length),
          ),
          maxUncompressed:
              AppConstants.imports.bundleMaxBytes - budget.expanded,
        ) !=
        null) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.failureANestedBundleArchiveCouldNotBe,
      );
    }
    final ZipDecoder decoder = ZipDecoder();
    final Archive archive = decoder.decodeBytes(source);
    for (final ZipFileHeader header in decoder.directory.fileHeaders) {
      if (header.generalPurposeBitFlag & 1 != 0 ||
          header.file!.flags & 1 != 0 ||
          (header.compressionMethod != ZipFile.zipCompressionStore &&
              header.compressionMethod != ZipFile.zipCompressionDeflate)) {
        throw ValidationFailure(
          localizedMessage:
              Copy.messages.failureAnEncryptedOrUnsupportedAttachmentCouldNot,
        );
      }
    }
    for (final ArchiveFile entry in archive.files) {
      assertClean(entry.name);
      if (!entry.isFile) {
        continue;
      }
      budget.expanded += entry.size;
      if (budget.expanded > AppConstants.imports.bundleMaxBytes) {
        throw ValidationFailure(
          localizedMessage: Copy.messages.failureANestedBundleArchiveIsTooLarge,
        );
      }
      final _LimitedMemoryOutput output = _LimitedMemoryOutput(entry.size);
      final InputStream input = entry.rawContent!
          .getStream(decompress: false)
          .subset();
      if (entry.compression == CompressionType.deflate) {
        Inflate.stream(input, output: output);
      } else {
        output.writeStream(input);
      }
      if (output.length != entry.size) {
        throw ValidationFailure(
          localizedMessage: Copy.messages.failureANestedBundleEntryHasAnInvalid,
        );
      }
      _payload(output.getBytes(), depth + 1, budget);
    }
  }

  static List<({String name, RegExp pattern})> _compile(String yaml) {
    final RegExp nameLine = RegExp(r'^  ([a-z][a-z0-9_]*):\s*$');
    final RegExp patternLine = RegExp(r"pattern:\s*'([^']*)'");
    final List<({String name, RegExp pattern})> patterns =
        <({String name, RegExp pattern})>[];
    String name = '';
    for (final String line in const LineSplitter().convert(yaml)) {
      final RegExpMatch? named = nameLine.firstMatch(line);
      if (named != null) name = named.group(1)!;
      final RegExpMatch? pattern = patternLine.firstMatch(line);
      if (pattern != null) {
        patterns.add((
          name: name,
          pattern: RegExp(pattern.group(1)!, caseSensitive: false),
        ));
      }
    }
    if (patterns.isEmpty) {
      throw const FormatException('No secret patterns are configured.');
    }
    return patterns;
  }
}

String? _readPatterns(Object? _) => platform.readSecretPatternsYaml();

final class _PayloadBudget {
  int expanded = 0;
}

final class _LimitedMemoryOutput extends OutputMemoryStream {
  _LimitedMemoryOutput(this.maximum);
  final int maximum;

  void _reserve(int count) {
    if (length + count > maximum) {
      throw ValidationFailure(
        localizedMessage:
            Copy.messages.failureANestedBundleEntryExceedsItsDeclared,
      );
    }
  }

  @override
  void writeByte(int value) {
    _reserve(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _reserve(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _reserve(stream.length);
    super.writeStream(stream);
  }

  @override
  void writeBackReference(int distance, int count) {
    // Archive 4 copies dictionary bytes directly into its memory buffer.
    _reserve(count);
    super.writeBackReference(distance, count);
  }
}
