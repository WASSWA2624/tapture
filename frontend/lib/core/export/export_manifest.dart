import 'dart:convert';

import 'export_request.dart';

/// The manifest written last in an export package (task 018).
final class ExportManifest {
  /// Creates a manifest for one finished export.
  const ExportManifest({
    required this.exportId,
    required this.createdAt,
    required this.request,
    required this.entries,
    this.exportedBy = '',
  });

  /// Export id.
  final String exportId;

  /// When the package was written.
  final DateTime createdAt;

  /// The request that produced the package.
  final ExportRequest request;

  /// One row per exported record.
  final List<ManifestEntry> entries;

  /// The operator who produced the package, from the device profile.
  final String exportedBy;

  /// JSON matching the package example: id, time, operator, request and
  /// entries.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exportId': exportId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'exportedBy': exportedBy,
      'request': request.toJson(),
      'entries': <Map<String, Object?>>[
        for (final ManifestEntry entry in entries)
          <String, Object?>{
            'recordId': entry.recordId,
            'recordNumber': entry.recordNumber,
            'sheet': entry.sheet,
            'row': entry.row,
            'photoPaths': entry.photoPaths,
          },
      ],
    };
  }

  /// Encoded [toJson].
  String encode() => jsonEncode(toJson());

  /// Streams the same manifest without materializing its request's records.
  Iterable<String> chunks() sync* {
    final String header = jsonEncode(<String, Object?>{
      'exportId': exportId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'exportedBy': exportedBy,
      'entries': <Map<String, Object?>>[
        for (final ManifestEntry entry in entries)
          <String, Object?>{
            'recordId': entry.recordId,
            'recordNumber': entry.recordNumber,
            'sheet': entry.sheet,
            'row': entry.row,
            'photoPaths': entry.photoPaths,
          },
      ],
    });
    yield '${header.substring(0, header.length - 1)},"request":';
    yield* request.chunks();
    yield '}';
  }
}

/// One record's place in the workbook and its photo paths.
typedef ManifestEntry = ({
  String recordId,
  String recordNumber,
  String sheet,
  int row,
  List<String> photoPaths,
});
