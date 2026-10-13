import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettingsResolved;

import '../domain/confidence.dart';
import '../domain/online_skip_rule.dart';
import '../domain/processing_job.dart';
import '../domain/proposal_application.dart';
import 'proposal_collector.dart';
import 'record_bundle.dart';
import 'stage_settings.dart';
import 'stage_support.dart';

/// Current grounded proposals, as the online skip rule reads them.
/// Stored unapproved confidence cannot certify changed or removed evidence.
final class OnlineCompletion {
  /// Creates the reader over the proposal [collector].
  const OnlineCompletion({required this._collector, required this._settings});

  final ProposalCollector _collector;
  final StageSettings _settings;

  /// Extractable template fields in order; consent is always operator input.
  Future<List<SkipField>> forOnline(
    ProcessingJob job,
    RecordBundle bundle,
  ) async {
    final Map<String, ProposedValue> proposed = <String, ProposedValue>{
      for (final ProposedValue value in (await _collector.collect(
        job,
        bundle,
      )).proposals)
        value.fieldKey: value,
    };
    final ProjectSettingsResolved settings = _settings.project(bundle);
    return <SkipField>[
      for (final TemplateField field in StageSupport.extractionFields(bundle))
        (
          requiredField: field.isRequired,
          value: proposed[field.fieldKey]?.value,
          band: proposed[field.fieldKey] == null
              ? null
              : Confidence.band(
                  score: proposed[field.fieldKey]!.confidence,
                  high: settings.confidenceHigh,
                  medium: settings.confidenceMedium,
                ),
        ),
    ];
  }
}
