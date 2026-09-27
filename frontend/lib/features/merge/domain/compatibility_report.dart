import 'compatibility_status.dart';
import 'template_match.dart';

/// Whether a package's templates can join a project, template by template
/// (task 076, W20). It heads every merge preview.
final class CompatibilityReport {
  /// Creates a report over [templates].
  const CompatibilityReport(this.templates);

  /// One match per incoming template its records use.
  final List<TemplateMatch> templates;

  /// The report as one status: blocked when any template is, otherwise
  /// with differences when any has one.
  CompatibilityStatus get status {
    if (templates.any((TemplateMatch match) => match.blocks)) {
      return CompatibilityStatus.incompatible;
    }
    if (templates.any((TemplateMatch match) => match.issues.isNotEmpty)) {
      return CompatibilityStatus.compatibleWithDifferences;
    }
    return CompatibilityStatus.compatible;
  }

  /// Whether a merge may start.
  bool get canMerge => status != CompatibilityStatus.incompatible;

  /// Incoming template id to the local template its records join.
  Map<String, String> get mapping => <String, String>{
    for (final TemplateMatch match in templates)
      if (match.localId case final String local) match.incomingId: local,
  };
}
