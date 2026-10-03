import 'package:drift/drift.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/exports/exports.dart' show ExportSharingPolicy;

/// Ensures a retry or resumed transfer uses the current protection policy.
final class ExportUploadGuard {
  /// Uses the saved export registry and its current sharing policy.
  const ExportUploadGuard({
    required this.db,
    required this.storage,
    required this.policy,
  });

  /// Saved export paths and record snapshots.
  final AppDatabase db;

  /// Root used to normalize native absolute file paths.
  final StorageRoot storage;

  /// Policy shared with the operator's local share action.
  final ExportSharingPolicy policy;

  /// Refuses obsolete or untracked app artifacts before each transfer attempt.
  Future<Result<void>> check(String filePath) => Result.captureAsync(() async {
    final String root = (await storage.resolve()).getOrThrow().path.replaceAll(
      '\\',
      '/',
    );
    final String path = filePath.replaceAll('\\', '/');
    final String relative = path.startsWith('$root/')
        ? path.substring(root.length + 1)
        : path;
    final List<ExportRow> matches =
        await (db.select(db.exports)..where(
              ($ExportsTable row) =>
                  row.filePath.equals(relative) &
                  row.formats.equals('["cloud-upload"]').not(),
            ))
            .get();
    if (matches.isEmpty) {
      if (relative.startsWith('projects/') && relative.contains('/exports/')) {
        throw ValidationFailure(message: Copy.exportPrivacyChanged);
      }
      // A file explicitly chosen outside the app's export tree has no app
      // record snapshot to replay; the operator's upload confirmation governs it.
      return;
    }
    (await policy.allowShare(matches.first.id)).getOrThrow();
  });
}
