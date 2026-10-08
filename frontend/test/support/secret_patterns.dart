import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// A secret shape or planted value found in an artefact.
typedef SecretHit = ({
  String artefact,
  String entry,
  int offset,
  String pattern,
});

/// Scans export, bundle and log bytes for secret shapes and planted values.
final class SecretScan {
  /// Patterns from the shared YAML, plus [secrets] planted in the run.
  static List<({String name, RegExp pattern})> compile(
    String yaml, {
    List<String> secrets = const <String>[],
  }) {
    final List<({String name, RegExp pattern})> compiled =
        <({String name, RegExp pattern})>[];
    final RegExp named = RegExp(r'^  ([A-Za-z0-9_]+):\s*$', multiLine: true);
    final List<RegExpMatch> names = named.allMatches(yaml).toList();
    for (var index = 0; index < names.length; index++) {
      final int start = names[index].end;
      final int end = index + 1 < names.length
          ? names[index + 1].start
          : yaml.length;
      final String block = yaml.substring(start, end);
      final RegExpMatch? pattern = RegExp(r"pattern: '(.*)'").firstMatch(block);
      if (pattern == null) {
        continue;
      }
      compiled.add((
        name: names[index].group(1)!,
        pattern: RegExp(pattern.group(1)!, caseSensitive: false),
      ));
    }
    for (final String secret in secrets) {
      if (secret.isEmpty) {
        continue;
      }
      compiled.add((
        name: 'planted',
        pattern: RegExp(RegExp.escape(secret), caseSensitive: false),
      ));
    }
    return compiled;
  }

  /// Every hit in [file], including nested archive entries.
  static List<SecretHit> scanFile(
    File file,
    List<({String name, RegExp pattern})> patterns,
  ) {
    final Uint8List bytes = file.readAsBytesSync();
    if (_looksLikeZip(bytes)) {
      return _scanZip(file.path, bytes, patterns);
    }
    return _scanText(
      artefact: file.path,
      entry: '',
      bytes: bytes,
      patterns: patterns,
    );
  }

  static bool _looksLikeZip(List<int> bytes) {
    return bytes.length > 3 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4b &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
  }

  static List<SecretHit> _scanZip(
    String artefact,
    List<int> bytes,
    List<({String name, RegExp pattern})> patterns,
  ) {
    final List<SecretHit> hits = <SecretHit>[];
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    for (final ArchiveFile entry in archive.files) {
      hits.addAll(
        _scanText(
          artefact: artefact,
          entry: entry.name,
          bytes: entry.name.codeUnits,
          patterns: patterns,
        ),
      );
      if (entry.isFile) {
        final List<int> content = entry.content;
        if (_looksLikeZip(content)) {
          hits.addAll(_scanZip('$artefact!${entry.name}', content, patterns));
        } else {
          hits.addAll(
            _scanText(
              artefact: artefact,
              entry: entry.name,
              bytes: content,
              patterns: patterns,
            ),
          );
        }
      }
    }
    return hits;
  }

  static List<SecretHit> _scanText({
    required String artefact,
    required String entry,
    required List<int> bytes,
    required List<({String name, RegExp pattern})> patterns,
  }) {
    final String text = utf8.decode(bytes, allowMalformed: true);
    final List<SecretHit> hits = <SecretHit>[];
    for (final ({String name, RegExp pattern}) pattern in patterns) {
      for (final RegExpMatch match in pattern.pattern.allMatches(text)) {
        hits.add((
          artefact: artefact,
          entry: entry,
          offset: match.start,
          pattern: pattern.name,
        ));
      }
    }
    return hits;
  }
}
