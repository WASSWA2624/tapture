import 'dart:convert';

import 'package:tapture/core/constants/app_constants.dart';

/// Validated project-scoped switches stored as the row's settings JSON.
///
/// Missing keys and unknown shapes become [defaults] rather than a throw.
/// Unknown keys are ignored so a newer writer cannot break an older reader.
final class ProjectSettings {
  /// Creates settings. Omitted values are the built-in defaults.
  const ProjectSettings({
    this.aiEnabled = true,
    this.doNotSendImages = false,
    this.gpsEnabled = false,
    this.folderStrategy = 'byContext',
    this.confidenceHigh = 0.85,
    this.confidenceMedium = 0.60,
    this.refineColumns = true,
  });

  /// Every switch at its built-in default.
  static const ProjectSettings defaults = ProjectSettings();

  /// Reads [raw] JSON. Invalid, missing or non-object values become
  /// [defaults].
  factory ProjectSettings.decode(String raw) {
    if (raw.trim().isEmpty) {
      return defaults;
    }
    try {
      return ProjectSettings.fromJson(jsonDecode(raw));
    } on FormatException {
      return defaults;
    }
  }

  /// Reads a decoded JSON value. A non-object is [defaults].
  factory ProjectSettings.fromJson(Object? json) {
    if (json is! Map) {
      return defaults;
    }
    final Map<String, Object?> map = Map<String, Object?>.from(json);
    return ProjectSettings(
      aiEnabled: _bool(map[_aiEnabled]) ?? true,
      doNotSendImages: _bool(map[_doNotSendImages]) ?? false,
      gpsEnabled: _bool(map[_gpsEnabled]) ?? false,
      folderStrategy: _readFolderStrategy(
        map[_folderStrategy] ?? map[_photoFolderStrategy],
      ),
      confidenceHigh:
          _number(map[_confidenceHigh]) ?? AppConstants.confidence.high,
      confidenceMedium:
          _number(map[_confidenceMedium]) ?? AppConstants.confidence.medium,
      refineColumns:
          _bool(map[_refineColumns]) ?? _bool(map[_refinedColumns]) ?? true,
    );
  }

  /// Provider calls are allowed for this project.
  final bool aiEnabled;

  /// Originals stay on the device; providers see no image bytes.
  final bool doNotSendImages;

  /// GPS is stamped at capture.
  final bool gpsEnabled;

  /// How new photo folders are grouped. Existing files stay put.
  final String folderStrategy;

  /// High-confidence band; at or above this is accepted automatically.
  final double confidenceHigh;

  /// Medium-confidence band; below [confidenceHigh].
  final double confidenceMedium;

  /// Exports include refined columns by default.
  final bool refineColumns;

  /// The validated object written onto the row.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      _aiEnabled: aiEnabled,
      _doNotSendImages: doNotSendImages,
      _gpsEnabled: gpsEnabled,
      _folderStrategy: folderStrategy,
      _confidenceHigh: confidenceHigh,
      _confidenceMedium: confidenceMedium,
      _refineColumns: refineColumns,
    };
  }

  /// [toJson] encoded as the row's settings text.
  String encode() => jsonEncode(toJson());

  /// Returns a copy with the provided fields replaced.
  ProjectSettings copyWith({
    bool? aiEnabled,
    bool? doNotSendImages,
    bool? gpsEnabled,
    String? folderStrategy,
    double? confidenceHigh,
    double? confidenceMedium,
    bool? refineColumns,
  }) {
    return ProjectSettings(
      aiEnabled: aiEnabled ?? this.aiEnabled,
      doNotSendImages: doNotSendImages ?? this.doNotSendImages,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      folderStrategy: folderStrategy ?? this.folderStrategy,
      confidenceHigh: confidenceHigh ?? this.confidenceHigh,
      confidenceMedium: confidenceMedium ?? this.confidenceMedium,
      refineColumns: refineColumns ?? this.refineColumns,
    );
  }

  @override
  int get hashCode => Object.hash(
    aiEnabled,
    doNotSendImages,
    gpsEnabled,
    folderStrategy,
    confidenceHigh,
    confidenceMedium,
    refineColumns,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ProjectSettings &&
            other.aiEnabled == aiEnabled &&
            other.doNotSendImages == doNotSendImages &&
            other.gpsEnabled == gpsEnabled &&
            other.folderStrategy == folderStrategy &&
            other.confidenceHigh == confidenceHigh &&
            other.confidenceMedium == confidenceMedium &&
            other.refineColumns == refineColumns);
  }
}

const String _aiEnabled = 'aiEnabled';
const String _doNotSendImages = 'doNotSendImages';
const String _gpsEnabled = 'gpsEnabled';
const String _folderStrategy = 'folderStrategy';
const String _photoFolderStrategy = 'photoFolderStrategy';
const String _confidenceHigh = 'confidenceHigh';
const String _confidenceMedium = 'confidenceMedium';
const String _refineColumns = 'refineColumns';
const String _refinedColumns = 'refinedColumns';

const Set<String> _folderStrategies = <String>{
  'byContext',
  'byTemplate',
  'byCaptureDate',
  'flat',
};

bool? _bool(Object? raw) => raw is bool ? raw : null;

double? _number(Object? raw) {
  if (raw is double) {
    return raw;
  }
  if (raw is num) {
    return raw.toDouble();
  }
  return null;
}

String _readFolderStrategy(Object? raw) {
  if (raw is String && _folderStrategies.contains(raw)) {
    return raw;
  }
  return AppConstants.folders.defaultStrategy;
}
