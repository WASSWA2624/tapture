import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/files/path_sanitizer.dart';

/// Composes a project-relative photo folder from the strategy in force.
///
/// The type this file is named for (FE-STR-06). The contract name is
/// [buildPhotoPath].
abstract final class PhotoPathBuilder {
  /// Relative photo folder for [strategy]. Never touches the filesystem.
  static String buildPhotoPath({
    required PhotoFolderStrategy strategy,
    required List<String> contextValues,
    DateTime? capturedAt,
    String? templateName,
  }) {
    return switch (strategy) {
      PhotoFolderStrategy.byContext => _byContext(contextValues),
      PhotoFolderStrategy.byTemplate => _byTemplate(templateName),
      PhotoFolderStrategy.byCaptureDate => _byCaptureDate(capturedAt),
      PhotoFolderStrategy.flat => _photos,
    };
  }

  /// The strategy [AppConstants.folders.defaultStrategy] names.
  static PhotoFolderStrategy get defaultStrategy {
    switch (AppConstants.folders.defaultStrategy) {
      case 'byTemplate':
        return PhotoFolderStrategy.byTemplate;
      case 'byCaptureDate':
        return PhotoFolderStrategy.byCaptureDate;
      case 'flat':
        return PhotoFolderStrategy.flat;
      default:
        return PhotoFolderStrategy.byContext;
    }
  }
}

/// How a project's photos are grouped on disk.
enum PhotoFolderStrategy {
  /// `photos/<level1>/<level2>/<level3>/` from the context in force.
  byContext,

  /// `photos/<template>/`.
  byTemplate,

  /// `photos/<year>/<month>/<day>/` from [capturedAt].
  byCaptureDate,

  /// `photos/` with no extra folders.
  flat,
}

/// Relative photo folder for [strategy]. Never touches the filesystem
/// (FE-PERF-02).
String buildPhotoPath({
  required PhotoFolderStrategy strategy,
  required List<String> contextValues,
  DateTime? capturedAt,
  String? templateName,
}) {
  return PhotoPathBuilder.buildPhotoPath(
    strategy: strategy,
    contextValues: contextValues,
    capturedAt: capturedAt,
    templateName: templateName,
  );
}

String _byContext(List<String> contextValues) {
  final List<String> levels = <String>[
    for (int index = 0; index < _contextLevels; index++)
      _level(contextValues, index),
  ];
  if (levels.every((String level) => level == _unfiled)) {
    return '$_photos/$_unfiled';
  }
  return '$_photos/${levels.join('/')}';
}

String _byTemplate(String? templateName) {
  final String? name = templateName?.trim();
  if (name == null || name.isEmpty) {
    return '$_photos/$_unfiled';
  }
  return '$_photos/${sanitiseSegment(name)}';
}

String _byCaptureDate(DateTime? capturedAt) {
  if (capturedAt == null) {
    return '$_photos/$_unfiled';
  }
  final String month = capturedAt.month.toString().padLeft(2, '0');
  final String day = capturedAt.day.toString().padLeft(2, '0');
  return '$_photos/${capturedAt.year}/$month/$day';
}

String _level(List<String> contextValues, int index) {
  if (index >= contextValues.length) {
    return _unfiled;
  }
  final String raw = contextValues[index].trim();
  if (raw.isEmpty) {
    return _unfiled;
  }
  return sanitiseSegment(raw);
}

const String _photos = 'photos';
const String _unfiled = '_unfiled';
const int _contextLevels = 3;
