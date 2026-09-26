import 'dart:convert';

import 'package:tapture/core/constants/app_constants.dart';

part 'project_settings_json.dart';

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
    this.templateChoice,
    this.coverPhoto,
    this.refineCaptions,
    this.dailyRequestCap,
    this.locale,
    this.providerSelection,
    this.templatePins,
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
      templateChoice: _readTemplateChoice(map[_templateChoice]),
      coverPhoto: _readCoverPhoto(map[_coverPhoto]),
      refineCaptions: _bool(map[_refineCaptions]),
      dailyRequestCap: _count(map[_dailyRequestCap]),
      locale: _text(map[_locale]),
      providerSelection: _readProviderSelection(map[_providerSelection]),
      templatePins: _readTemplatePins(map[_templatePins]),
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

  /// How capture picks a template: `auto`, `suggest`, `manual`, or null
  /// for the same behaviour as `auto`.
  final String? templateChoice;

  /// The project's optional photo, shown as its list thumbnail
  /// (FBK0000154). Null keeps the project number.
  final ProjectCoverPhoto? coverPhoto;

  /// Captions are refined without being asked. Null inherits
  /// [SettingKeys.aiRefineCaptions].
  final bool? refineCaptions;

  /// Online extraction requests allowed for this project today. Null
  /// inherits [SettingKeys.aiDailyRequestCap].
  final int? dailyRequestCap;

  /// Locale dates and numbers are read in, such as `en-UG`. Null inherits
  /// [SettingKeys.appLanguage].
  final String? locale;

  /// Provider and model per operation, keyed by `AiOperation.name`. An
  /// operation missing here uses the app selection. There is no app
  /// default for the map itself.
  final Map<String, ({String provider, String model})>? providerSelection;

  /// Template pinned per context, keyed by the record's context as
  /// `'<levelKey>=<value>'` pairs in level-key order joined with `|`, so
  /// the template question is asked once per place. Project-only.
  final Map<String, String>? templatePins;

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
      if (templateChoice != null) _templateChoice: templateChoice,
      if (coverPhoto case final ProjectCoverPhoto photo)
        _coverPhoto: <String, Object?>{
          _coverPath: photo.path,
          _coverSha256: photo.sha256,
        },
      if (refineCaptions != null) _refineCaptions: refineCaptions,
      if (dailyRequestCap != null) _dailyRequestCap: dailyRequestCap,
      if (locale != null) _locale: locale,
      if (providerSelection
          case final Map<String, ({String provider, String model})> selection)
        _providerSelection: _writeProviderSelection(selection),
      if (templatePins case final Map<String, String> pins)
        _templatePins: Map<String, String>.of(pins),
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
    String? templateChoice,
    ProjectCoverPhoto? coverPhoto,
    bool? refineCaptions,
    int? dailyRequestCap,
    String? locale,
    Map<String, ({String provider, String model})>? providerSelection,
    Map<String, String>? templatePins,
    bool clearAiEnabled = false,
    bool clearDoNotSendImages = false,
    bool clearGpsEnabled = false,
    bool clearFolderStrategy = false,
    bool clearConfidenceHigh = false,
    bool clearConfidenceMedium = false,
    bool clearRefineColumns = false,
    bool clearTemplateChoice = false,
    bool clearCoverPhoto = false,
    bool clearRefineCaptions = false,
    bool clearDailyRequestCap = false,
    bool clearLocale = false,
    bool clearProviderSelection = false,
    bool clearTemplatePins = false,
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
      templateChoice: clearTemplateChoice
          ? null
          : (templateChoice ?? this.templateChoice),
      coverPhoto: clearCoverPhoto ? null : (coverPhoto ?? this.coverPhoto),
      refineCaptions: clearRefineCaptions
          ? null
          : (refineCaptions ?? this.refineCaptions),
      dailyRequestCap: clearDailyRequestCap
          ? null
          : (dailyRequestCap ?? this.dailyRequestCap),
      locale: clearLocale ? null : (locale ?? this.locale),
      providerSelection: clearProviderSelection
          ? null
          : (providerSelection ?? this.providerSelection),
      templatePins: clearTemplatePins
          ? null
          : (templatePins ?? this.templatePins),
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
      refineCaptions: refineCaptions ?? app.refineCaptions,
      dailyRequestCap: dailyRequestCap ?? app.dailyRequestCap,
      locale: locale ?? app.locale,
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
    templateChoice,
    coverPhoto,
    refineCaptions,
    dailyRequestCap,
    locale,
    _mapHash(providerSelection),
    _mapHash(templatePins),
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
            other.refineColumns == refineColumns &&
            other.templateChoice == templateChoice &&
            other.coverPhoto == coverPhoto &&
            other.refineCaptions == refineCaptions &&
            other.dailyRequestCap == dailyRequestCap &&
            other.locale == locale &&
            _sameMap(other.providerSelection, providerSelection) &&
            _sameMap(other.templatePins, templatePins));
  }
}

/// A project's photo: its path under the storage root, as
/// `projects/<folder>/cover/<id>.jpg`, and the file's hash (D7).
typedef ProjectCoverPhoto = ({String path, String sha256});

/// App-store values a project setting falls back to when unset.
typedef ProjectSettingsDefaults = ({
  bool aiEnabled,
  bool doNotSendImages,
  bool gpsEnabled,
  String folderStrategy,
  double confidenceHigh,
  double confidenceMedium,
  bool refineColumns,
  bool refineCaptions,
  int dailyRequestCap,
  String locale,
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
  bool refineCaptions,
  int dailyRequestCap,
  String locale,
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
    refineCaptions: false,
    dailyRequestCap: AppConstants.processing.dailyRequestCap,
    locale: AppConstants.defaultLanguage,
  );
}
