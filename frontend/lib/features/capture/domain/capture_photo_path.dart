import 'package:tapture/core/files/photo_path_builder.dart';

/// Where capture writes a new photo inside its project folder: the folder
/// the capture-time context names, or `photos/_unfiled/` before any level is
/// set (spec section 8.1 rules 2 and 3). Saving the record later moves the
/// file only if its context changed in between.
abstract final class CapturePhotoPath {
  /// The project-relative path of [fileName] for a capture under [context].
  ///
  /// [strategy] is the project's stored folder strategy, or null for the
  /// default. [levelKeys] are the project's context levels in hierarchy
  /// order.
  static String of({
    required String fileName,
    required String? strategy,
    required List<String> levelKeys,
    required Map<String, String> context,
    required DateTime capturedAt,
    String? templateName,
  }) {
    final String folder = buildPhotoPath(
      strategy: strategy == null
          ? PhotoPathBuilder.defaultStrategy
          : PhotoPathBuilder.strategyNamed(strategy),
      contextValues: PhotoPathBuilder.contextValues(
        levelKeys: levelKeys,
        snapshot: context,
      ),
      capturedAt: capturedAt,
      templateName: templateName,
    );
    return '$folder/$fileName';
  }
}
