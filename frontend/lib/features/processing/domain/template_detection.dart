import 'package:tapture/core/constants/app_constants.dart';

/// Chooses a template from local signals, then stops.
///
/// Order: pinned, the only template, a reference match, a confident local
/// score, otherwise ask. A pinned template never reaches the later rules.
final class TemplateDetection {
  /// Decides from [input]. No network.
  static DetectionDecision decide(DetectionInput input) {
    final double confident =
        input.confident ?? AppConstants.processing.detectionConfident;
    final double gap = input.gap ?? AppConstants.processing.detectionGap;
    if (input.pinnedTemplateId != null &&
        input.templates.any(
          (DetectionProfile profile) =>
              profile.templateId == input.pinnedTemplateId,
        )) {
      return (
        templateId: input.pinnedTemplateId,
        rule: DetectionRule.pinned,
        callModel: false,
        shortlist: const <String>[],
      );
    }
    if (input.templates.length == 1) {
      return (
        templateId: input.templates.first.templateId,
        rule: DetectionRule.onlyTemplate,
        callModel: false,
        shortlist: const <String>[],
      );
    }
    if (input.referenceTemplateId != null &&
        input.templates.any(
          (DetectionProfile profile) =>
              profile.templateId == input.referenceTemplateId,
        )) {
      return (
        templateId: input.referenceTemplateId,
        rule: DetectionRule.reference,
        callModel: false,
        shortlist: const <String>[],
      );
    }
    final List<({String id, double score})> scored =
        <({String id, double score})>[
          for (final DetectionProfile profile in input.templates)
            (id: profile.templateId, score: _score(profile, input.ocrText)),
        ]..sort(
          (({String id, double score}) a, ({String id, double score}) b) =>
              b.score.compareTo(a.score),
        );
    if (scored.isEmpty) {
      return (
        templateId: null,
        rule: DetectionRule.ask,
        callModel: false,
        shortlist: const <String>[],
      );
    }
    final double top = scored.first.score;
    final double second = scored.length > 1 ? scored[1].score : 0;
    final bool confidentScore = top >= confident && (top - second) >= gap;
    if (confidentScore) {
      return (
        templateId: scored.first.id,
        rule: DetectionRule.local,
        callModel: false,
        shortlist: const <String>[],
      );
    }
    final List<String> shortlist = <String>[
      for (final ({String id, double score}) row in scored)
        if (row.score >= top - gap && row.score > 0) row.id,
    ];
    return (
      templateId: null,
      rule: DetectionRule.ask,
      callModel: shortlist.isNotEmpty,
      shortlist: shortlist,
    );
  }
}

/// Why a template was chosen.
enum DetectionRule {
  /// Pinned for this session. Detection does not run.
  pinned,

  /// The project has one template.
  onlyTemplate,

  /// An identifier matched a reference dataset's template.
  reference,

  /// Local keywords and patterns were confident.
  local,

  /// Local scoring did not decide.
  ask,
}

/// A template's detection profile, scored on device.
typedef DetectionProfile = ({
  String templateId,
  List<String> keywords,
  List<String> negativeKeywords,
  List<String> identifierPatterns,
  double weight,
});

/// Signals available before any model call.
typedef DetectionInput = ({
  String? pinnedTemplateId,
  List<DetectionProfile> templates,
  String ocrText,
  String? referenceTemplateId,
  double? confident,
  double? gap,
});

/// The decision, and whether a model may be asked about [shortlist].
typedef DetectionDecision = ({
  String? templateId,
  DetectionRule rule,
  bool callModel,
  List<String> shortlist,
});

double _score(DetectionProfile profile, String text) {
  final String folded = text.toLowerCase();
  var hits = 0.0;
  for (final String keyword in profile.keywords) {
    if (keyword.isNotEmpty && folded.contains(keyword.toLowerCase())) {
      hits += AppConstants.processing.detectionKeywordWeight;
    }
  }
  for (final String pattern in profile.identifierPatterns) {
    try {
      if (RegExp(pattern).hasMatch(text)) {
        hits += AppConstants.processing.detectionPatternWeight;
      }
    } on FormatException {
      continue;
    }
  }
  for (final String keyword in profile.negativeKeywords) {
    if (keyword.isNotEmpty && folded.contains(keyword.toLowerCase())) {
      hits -= AppConstants.processing.detectionNegativeKeywordWeight;
    }
  }
  final double weighted = hits * (profile.weight <= 0 ? 1 : profile.weight);
  if (weighted < 0) {
    return 0;
  }
  if (weighted > 1) {
    return 1;
  }
  return weighted;
}
