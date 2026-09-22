import 'template_detection.dart';

/// Asks a model only after local scoring failed to decide, and only about
/// the shortlist that scoring produced.
final class TemplateDetectionAi {
  /// Returns the local choice when [decision] already decided.
  ///
  /// [model] is not called unless [DetectionDecision.callModel] is set.
  static Future<String?> choose({
    required DetectionDecision decision,
    required Future<String?> Function(List<String> shortlist) model,
  }) async {
    if (!decision.callModel) {
      return decision.templateId;
    }
    return model(decision.shortlist);
  }
}
