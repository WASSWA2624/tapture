import 'dart:convert';

import 'package:tapture/core/constants/app_constants.dart';

/// Validated project-scoped switches stored as the row's settings JSON.
///
/// A null field is unset: callers [resolve] it against the app store
/// default. Missing keys and unknown shapes become [defaults] rather than
/// a throw. Unknown keys are ignored so a newer writer cannot break an
/// older reader.
final class ProjectSettings {
  /// Creates settings. Omitted values inherit the app default.
  const ProjectSettings({
    this.aiEnabled,
    this.doNotSendImages,
    this.gpsEnabled,
    this.folderStrategy,
    this.confidenceHigh,
    this.confidenceMedium,
    this.refineColumns,
  });

  /// Every switch unset, so [resolve] returns the app defaults.
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
      aiEnabled: _bool(map[_aiEnabled]),
      doNotSendImages: _bool(map[_doNotSendImages]),
      gpsEnabled: _bool(map[_gpsEnabled]),
      folderStrategy: _readFolderStrategy(
        map[_folderStrategy] ?? map[_photoFolderStrategy],
      ),
      confidenceHigh: _number(map[_confidenceHigh]),
      confidenceMedium: _number(map[_confidenceMedium]),
      refineColumns: _bool(map[_refineColumns]) ?? _bool(map[_refinedColumns]),
    );
  }

  /// Provider calls are allowed for this project. Null inherits the app
  /// default (on, when the store has no AI kill switch).
  final bool? aiEnabled;

  /// Originals stay on the device; providers see no image bytes. Null
  /// inherits [SettingKeys.aiDoNotSendImages].
  final bool? doNotSendImages;

  /// GPS is stamped at capture. Null inherits the app GPS default.
  final bool? gpsEnabled;

  /// How new photo folders are grouped. Null inherits the app strategy.
  /// Existing files stay put.
  final String? folderStrategy;

  /// High-confidence band. Null inherits the app high band.
  final double? confidenceHigh;

  /// Medium-confidence band. Null inherits the app medium band.
  final double? confidenceMedium;

  /// Exports include refined columns. Null inherits the built-in default.
  final bool? refineColumns;

  /// The validated object written onto the row. Unset keys are omitted so
  /// a later read can still fall back to the app store.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (aiEnabled != null) _aiEnabled: aiEnabled,
      if (doNotSendImages != null) _doNotSendImages: doNotSendImages,
      if (gpsEnabled != null) _gpsEnabled: gpsEnabled,
      if (folderStrategy != null) _folderStrategy: folderStrategy,
      if (confidenceHigh != null) _confidenceHigh: confidenceHigh,
      if (confidenceMedium != null) _confidenceMedium: confidenceMedium,
      if (refineColumns != null) _refineColumns: refineColumns,
    };
  }

  /// [toJson] encoded as the row's settings text.
  String encode() => jsonEncode(toJson());

  /// Returns a copy with the provided fields replaced. A `clear*` flag
  /// unsets that override so [resolve] returns the app default again.
  ProjectSettings copyWith({
    bool? aiEnabled,
    bool? doNotSendImages,
    bool? gpsEnabled,
    String? folderStrategy,
    double? confidenceHigh,
    double? confidenceMedium,
    bool? refineColumns,
    bool clearAiEnabled = false,
    bool clearDoNotSendImages = false,
    bool clearGpsEnabled = false,
    bool clearFolderStrategy = false,
    bool clearConfidenceHigh = false,
    bool clearConfidenceMedium = false,
    bool clearRefineColumns = false,
  }) {
    return ProjectSettings(
      aiEnabled: clearAiEnabled ? null : (aiEnabled ?? this.aiEnabled),
      doNotSendImages: clearDoNotSendImages
          ? null
          : (doNotSendImages ?? this.doNotSendImages),
      gpsEnabled: clearGpsEnabled ? null : (gpsEnabled ?? this.gpsEnabled),
      folderStrategy: clearFolderStrategy
          ? null
          : (folderStrategy ?? this.folderStrategy),
      confidenceHigh: clearConfidenceHigh
          ? null
          : (confidenceHigh ?? this.confidenceHigh),
      confidenceMedium: clearConfidenceMedium
          ? null
          : (confidenceMedium ?? this.confidenceMedium),
      refineColumns: clearRefineColumns
          ? null
          : (refineColumns ?? this.refineColumns),
    );
  }

  /// Effective switches: each override wins; an unset field uses [app].
  ProjectSettingsResolved resolve(ProjectSettingsDefaults app) {
    return (
      aiEnabled: aiEnabled ?? app.aiEnabled,
      doNotSendImages: doNotSendImages ?? app.doNotSendImages,
      gpsEnabled: gpsEnabled ?? app.gpsEnabled,
      folderStrategy: folderStrategy ?? app.folderStrategy,
      confidenceHigh: confidenceHigh ?? app.confidenceHigh,
      confidenceMedium: confidenceMedium ?? app.confidenceMedium,
      refineColumns: refineColumns ?? app.refineColumns,
    );
  }

  /// Whether a provider may be called for this project. AI off stops every
  /// call (FE-SEC-03).
  bool allowsProviderCalls(ProjectSettingsDefaults app) {
    return resolve(app).aiEnabled;
  }

  /// Whether a provider may see image bytes. AI off or do-not-send-images
  /// on both refuse egress (FE-SEC-03).
  bool allowsImageEgress(ProjectSettingsDefaults app) {
    final ProjectSettingsResolved resolved = resolve(app);
    return resolved.aiEnabled && !resolved.doNotSendImages;
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

/// App-store values a project setting falls back to when unset.
typedef ProjectSettingsDefaults = ({
  bool aiEnabled,
  bool doNotSendImages,
  bool gpsEnabled,
  String folderStrategy,
  double confidenceHigh,
  double confidenceMedium,
  bool refineColumns,
});

/// Effective switches after [ProjectSettings.resolve].
typedef ProjectSettingsResolved = ({
  bool aiEnabled,
  bool doNotSendImages,
  bool gpsEnabled,
  String folderStrategy,
  double confidenceHigh,
  double confidenceMedium,
  bool refineColumns,
});

/// Built-in fallbacks when the app store has no matching key.
ProjectSettingsDefaults get builtInProjectSettingsDefaults {
  return (
    aiEnabled: true,
    doNotSendImages: false,
    gpsEnabled: false,
    folderStrategy: AppConstants.folders.defaultStrategy,
    confidenceHigh: AppConstants.confidence.high,
    confidenceMedium: AppConstants.confidence.medium,
    refineColumns: true,
  );
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

String? _readFolderStrategy(Object? raw) {
  if (raw is String && _folderStrategies.contains(raw)) {
    return raw;
  }
  return null;
}
