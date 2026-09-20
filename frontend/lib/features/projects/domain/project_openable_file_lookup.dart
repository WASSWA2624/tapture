import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Finds the imported template workbook, or the newest export, for a project.
abstract interface class ProjectOpenableFileLookup {
  /// A stand-in that returns [file] so tests never touch a folder
  /// (FE-TEST-03).
  factory ProjectOpenableFileLookup.fake({
    ProjectOpenableFile? file,
    bool? present,
    Failure? fail,
    void Function(String projectId, String folderName)? onExists,
    void Function(String projectId, String folderName)? onFind,
  }) {
    return _FakeProjectOpenableFileLookup(
      file: file,
      present: present ?? file != null,
      fail: fail,
      onExists: onExists,
      onFind: onFind,
    );
  }

  /// Whether the project has an imported workbook or an export to open.
  Future<Result<bool>> exists({
    required String projectId,
    required String folderName,
  });

  /// The file to hand off, or null when the project has none.
  Future<Result<ProjectOpenableFile?>> find({
    required String projectId,
    required String folderName,
  });
}

/// The failure when a project has no spreadsheet, document or PDF to open.
StorageFailure projectNothingToOpenFailure() {
  return const StorageFailure(
    message: Copy.projectNothingToOpen,
    recoveryAction: Copy.projectNothingToOpenRecovery,
  );
}

final class _FakeProjectOpenableFileLookup
    implements ProjectOpenableFileLookup {
  _FakeProjectOpenableFileLookup({
    required this._file,
    required this._present,
    required this._fail,
    required this._onExists,
    required this._onFind,
  });

  final ProjectOpenableFile? _file;
  final bool _present;
  final Failure? _fail;
  final void Function(String projectId, String folderName)? _onExists;
  final void Function(String projectId, String folderName)? _onFind;

  @override
  Future<Result<bool>> exists({
    required String projectId,
    required String folderName,
  }) async {
    _onExists?.call(projectId, folderName);
    final Failure? forced = _fail;
    if (forced != null) {
      return FailureResult<bool>(forced);
    }
    return Success<bool>(_present);
  }

  @override
  Future<Result<ProjectOpenableFile?>> find({
    required String projectId,
    required String folderName,
  }) async {
    _onFind?.call(projectId, folderName);
    final Failure? forced = _fail;
    if (forced != null) {
      return FailureResult<ProjectOpenableFile?>(forced);
    }
    return Success<ProjectOpenableFile?>(_file);
  }
}

/// A project's spreadsheet, document or PDF, as bytes a caller can hand off.
/// The stored path never leaves the lookup (FE-SEC-08).
typedef ProjectOpenableFile = ({
  String fileName,
  Uint8List bytes,
  String mimeType,
});
