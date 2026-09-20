import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/project_openable_file_lookup.dart';

/// Reads the imported workbook, then the newest export, from disk.
ProjectOpenableFileLookup createProjectOpenableFileLookup({
  required TemplateRepository templates,
}) {
  return projectOpenableFileLookupIo(
    templates: templates,
    storageRoot: StorageRoot(),
  );
}

/// The seam a suite points at a fake root and in-memory templates.
ProjectOpenableFileLookup projectOpenableFileLookupIo({
  required TemplateRepository templates,
  required StorageRoot storageRoot,
}) {
  return _IoProjectOpenableFileLookup(
    templates: templates,
    storageRoot: storageRoot,
  );
}

final class _IoProjectOpenableFileLookup implements ProjectOpenableFileLookup {
  _IoProjectOpenableFileLookup({
    required this._templates,
    required this._storageRoot,
  });

  final TemplateRepository _templates;
  final StorageRoot _storageRoot;

  @override
  Future<Result<bool>> exists({
    required String projectId,
    required String folderName,
  }) async {
    final Result<File?> found = await _locate(
      projectId: projectId,
      folderName: folderName,
    );
    return found.fold(
      FailureResult<bool>.new,
      (File? file) => Success<bool>(file != null),
    );
  }

  @override
  Future<Result<ProjectOpenableFile?>> find({
    required String projectId,
    required String folderName,
  }) async {
    final Result<File?> found = await _locate(
      projectId: projectId,
      folderName: folderName,
    );
    switch (found) {
      case FailureResult<File?>(:final Failure failure):
        return FailureResult<ProjectOpenableFile?>(failure);
      case Success<File?>(:final File? value):
        if (value == null) {
          return const Success<ProjectOpenableFile?>(null);
        }
        try {
          final Uint8List bytes = await value.readAsBytes();
          final String name = value.uri.pathSegments.isEmpty
              ? 'file'
              : value.uri.pathSegments.last;
          return Success<ProjectOpenableFile?>((
            fileName: name,
            bytes: bytes,
            mimeType: mimeTypeForFileName(name),
          ));
        } on Object {
          return FailureResult<ProjectOpenableFile?>(
            StorageFailure(
              message: 'Tapture could not read $folderName.',
              recoveryAction: 'Free some space, then try again.',
            ),
          );
        }
    }
  }

  Future<Result<File?>> _locate({
    required String projectId,
    required String folderName,
  }) async {
    final Result<Directory> root = await _storageRoot.resolve();
    switch (root) {
      case FailureResult<Directory>(:final Failure failure):
        return FailureResult<File?>(failure);
      case Success<Directory>(:final Directory value):
        try {
          final List<TemplateDef> templates = await _templates
              .watchByProject(projectId)
              .first;
          for (final TemplateDef template in templates) {
            final File? imported = _importedWorkbook(value, template);
            if (imported != null) {
              return Success<File?>(imported);
            }
          }
          return Success<File?>(_newestExport(value, folderName));
        } on Failure catch (failure) {
          return FailureResult<File?>(failure);
        } on Object {
          return const FailureResult<File?>(
            StorageFailure(
              message: 'Tapture could not look up a file for this project.',
              recoveryAction: 'Try again.',
            ),
          );
        }
    }
  }

  File? _importedWorkbook(Directory root, TemplateDef template) {
    if (template.source != _importedSource) {
      return null;
    }
    final String? relative = template.sourceFilePath;
    if (relative == null || !_isSafeRelative(relative)) {
      return null;
    }
    final File file = File('${root.path}/${relative.replaceAll('\\', '/')}');
    return file.existsSync() ? file : null;
  }

  File? _newestExport(Directory root, String folderName) {
    if (folderName.contains('..') ||
        folderName.contains('/') ||
        folderName.contains('\\')) {
      return null;
    }
    final Directory folder = Directory(
      '${root.path}/$_projects/$folderName/$_exports',
    );
    if (!folder.existsSync()) {
      return null;
    }
    final List<File> files = folder.listSync().whereType<File>().where((
      File file,
    ) {
      final String name = file.uri.pathSegments.isEmpty
          ? ''
          : file.uri.pathSegments.last;
      return name.isNotEmpty && !name.endsWith(_partSuffix);
    }).toList();
    if (files.isEmpty) {
      return null;
    }
    files.sort((File a, File b) {
      final int byTime = b.lastModifiedSync().compareTo(a.lastModifiedSync());
      if (byTime != 0) {
        return byTime;
      }
      return b.path.compareTo(a.path);
    });
    return files.first;
  }
}

/// MIME type from the file name's extension.
String mimeTypeForFileName(String fileName) {
  final int dot = fileName.lastIndexOf('.');
  final String extension = dot <= 0
      ? ''
      : fileName.substring(dot + 1).toLowerCase();
  return switch (extension) {
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'xls' => 'application/vnd.ms-excel',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'doc' => 'application/msword',
    'pdf' => 'application/pdf',
    'json' => 'application/json',
    _ => 'application/octet-stream',
  };
}

bool _isSafeRelative(String path) {
  final String normalized = path.replaceAll('\\', '/');
  if (normalized.isEmpty ||
      normalized.startsWith('/') ||
      normalized.contains('..')) {
    return false;
  }
  if (RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
    return false;
  }
  return true;
}

const String _importedSource = 'imported';

const String _projects = 'projects';

const String _exports = 'exports';

const String _partSuffix = '.part';
