import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';

import 'bundle_manifest.dart';
import 'bundle_vectors.dart';

/// A project package that passed every check: its manifest, its tables by
/// SQL table name, and its entries to read one at a time. Nothing has been
/// written; every value is still data, never instructions (FE-SEC-05).
final class InspectedBundle {
  /// Creates an inspected package over [readEntry] and [close].
  const InspectedBundle({
    required this.manifest,
    required this.tables,
    required this.name,
    required this._readEntry,
    required this._close,
    this._openEntry,
  });

  /// The package's manifest.
  final BundleManifest manifest;

  /// Rows by SQL table name, each keyed by column name.
  final Map<String, List<Map<String, Object?>>> tables;

  /// Package rows with causal clocks for the merge planner only.
  Map<String, List<Map<String, Object?>>> get mergeRows =>
      <String, List<Map<String, Object?>>>{
        ...tables,
        'version_vectors': BundleVectors.rows(manifest.versionVectors),
      };

  /// The file name the operator chose.
  final String name;

  final Future<Result<Uint8List>> Function(String path) _readEntry;
  final Future<void> Function() _close;
  final Future<Result<Stream<List<int>>>> Function(String path)? _openEntry;

  /// The bytes of the entry at [path], already checksum-verified.
  Future<Result<Uint8List>> readEntry(String path) => _readEntry(path);

  /// Opens one entry without buffering its whole content on native hosts.
  /// The caller must consume or cancel the stream before opening another;
  /// [close] also releases it. Byte-backed fixtures and browser packages keep
  /// the existing bounded byte-reader contract.
  Future<Result<Stream<List<int>>>> openEntry(String path) async {
    final Future<Result<Stream<List<int>>>> Function(String)? open = _openEntry;
    return open != null
        ? open(path)
        : (await readEntry(
            path,
          )).map((Uint8List bytes) => Stream<List<int>>.value(bytes));
  }

  /// Releases the package file. Safe to call more than once.
  Future<void> close() => _close();

  /// The rows of [table], or none.
  List<Map<String, Object?>> rowsOf(String table) {
    return tables[table] ?? const <Map<String, Object?>>[];
  }
}
