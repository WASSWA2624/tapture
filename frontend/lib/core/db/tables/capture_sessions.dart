import 'dart:convert';

import 'package:drift/drift.dart';

import '../columns.dart';

/// One interrupted capture session per project.
///
/// The payload is deliberately stored as validated JSON. Capture owns the
/// schema of that payload, while Drift provides project-scoped durability on
/// every database backend.
class CaptureSessions extends Table with MergeColumns {
  /// Project whose unfinished capture this row restores.
  TextColumn get projectId => text().unique()();

  /// Serialised capture session object.
  TextColumn get payloadJson => text()();
}

/// Validates capture payloads at the data-layer boundary for web databases
/// whose SQLite implementation may not enforce the table check identically.
bool isCaptureSessionJson(String value) {
  try {
    return jsonDecode(value) is Map;
  } on FormatException {
    return false;
  }
}
