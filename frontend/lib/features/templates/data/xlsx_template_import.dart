import 'dart:io';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/projects.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';

import '../domain/template_repository.dart';
import 'template_mapper.dart';

/// Copies a chosen workbook into the project `templates/` folder and saves
/// the confirmed mapping as a template. Writes nothing of its own.
final class XlsxTemplateImport {
  /// Creates the importer. Tests pass a fake [storageRoot] and repository.
  const XlsxTemplateImport({
    required this.storageRoot,
    required this.folders,
    required this.writer,
    required this.templates,
  });

  /// Root the copied workbook is stored under.
  final StorageRoot storageRoot;

  /// Creates and resolves the project's `templates/` folder.
  final ProjectFolders folders;

  /// Atomic copy of the chosen file. Never the original path.
  final FileWriter writer;

  /// Where the confirmed template is saved.
  final TemplateRepository templates;

  /// Reads a suggested type name. Unknown names become [FieldType.text].
  static FieldType typeFromWire(String raw) {
    try {
      return TemplateMapper.fieldTypeFromWire(raw);
    } on Failure {
      return FieldType.text;
    }
  }

  /// Copies [path] unmodified into `templates/`, then saves [draft].
  ///
  /// The original file is never opened for write. An existing copy is left
  /// in place and a new unique name is used (FE-SEC-08).
  Future<Result<TemplateDef>> apply({
    required String projectId,
    required String projectName,
    required String folderName,
    required String path,
    required TemplateDef draft,
  }) async {
    final File source = File(path);
    if (path.trim().isEmpty || !source.existsSync()) {
      return const FailureResult<TemplateDef>(
        ValidationFailure(
          message: Copy.xlsxMappingMissing,
          recoveryAction: Copy.xlsxMappingMissingRecovery,
        ),
      );
    }
    final Result<Directory> root = await storageRoot.resolve();
    switch (root) {
      case FailureResult<Directory>(:final Failure failure):
        return FailureResult<TemplateDef>(failure);
      case Success<Directory>(:final Directory value):
        return _copyInto(
          projectId: projectId,
          projectName: projectName,
          folderName: folderName,
          source: source,
          draft: draft,
          root: value,
        );
    }
  }

  Future<Result<TemplateDef>> _copyInto({
    required String projectId,
    required String projectName,
    required String folderName,
    required File source,
    required TemplateDef draft,
    required Directory root,
  }) async {
    final Result<Directory> projectDir = await folders.create(
      _folderRow(id: projectId, name: projectName, folderName: folderName),
    );
    switch (projectDir) {
      case FailureResult<Directory>(:final Failure failure):
        return FailureResult<TemplateDef>(failure);
      case Success<Directory>(:final Directory value):
        return _writeCopy(
          projectId: projectId,
          source: source,
          draft: draft,
          root: root,
          projectDir: value,
        );
    }
  }

  Future<Result<TemplateDef>> _writeCopy({
    required String projectId,
    required File source,
    required TemplateDef draft,
    required Directory root,
    required Directory projectDir,
  }) async {
    final Directory templatesDir = Directory(
      '${projectDir.path}/$_templatesFolder',
    );
    final String destName = _uniqueName(source, templatesDir);
    final File dest = File('${templatesDir.path}/$destName');
    if (dest.existsSync()) {
      return const FailureResult<TemplateDef>(
        StorageFailure(
          message: Copy.xlsxMappingExists,
          recoveryAction: Copy.xlsxMappingExistsRecovery,
        ),
      );
    }
    final String relative;
    try {
      relative = _relativeTo(root.path, dest.path);
    } on Failure catch (failure) {
      return FailureResult<TemplateDef>(failure);
    }
    final Result<WrittenFile> copied = await writer.copyIn(source, relative);
    switch (copied) {
      case FailureResult<WrittenFile>(:final Failure failure):
        return FailureResult<TemplateDef>(failure);
      case Success<WrittenFile>(:final WrittenFile value):
        return templates.save(
          draft.copyWith(
            id: '',
            projectId: projectId,
            version: draft.version < 1 ? 1 : draft.version,
            source: _importedSource,
            sourceFilePath: value.relativePath,
          ),
        );
    }
  }
}

String _uniqueName(File source, Directory templatesDir) {
  final String original = source.uri.pathSegments.isEmpty
      ? 'workbook'
      : source.uri.pathSegments.last;
  final int dot = original.lastIndexOf('.');
  final String ext = dot <= 0 ? '' : original.substring(dot).toLowerCase();
  final String stem = dot <= 0 ? original : original.substring(0, dot);
  String safe;
  try {
    safe = sanitiseSegment(stem);
  } on Failure {
    safe = 'workbook';
  }
  var name = '$safe$ext';
  var suffix = 2;
  while (File('${templatesDir.path}/$name').existsSync()) {
    name = '$safe-$suffix$ext';
    suffix += 1;
  }
  return name;
}

String _relativeTo(String root, String dest) {
  final String prefix = _slash(root);
  final String path = _slash(dest);
  final String base = prefix.endsWith('/') ? prefix : '$prefix/';
  if (path.startsWith(base)) {
    return path.substring(base.length);
  }
  if (path.toLowerCase().startsWith(base.toLowerCase()) &&
      path.length > base.length) {
    return path.substring(base.length);
  }
  throw const ValidationFailure(
    message: Copy.xlsxMappingMissing,
    recoveryAction: Copy.xlsxMappingMissingRecovery,
  );
}

String _slash(String path) => path.replaceAll(r'\', '/');

Project _folderRow({
  required String id,
  required String name,
  required String folderName,
}) {
  final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return Project(
    id: id,
    createdAt: epoch,
    updatedAt: epoch,
    updatedByDevice: '',
    rev: 1,
    name: name,
    client: '',
    status: ProjectStatus.active,
    folderName: folderName,
    settings: '{}',
  );
}

const String _templatesFolder = 'templates';

const String _importedSource = 'imported';
