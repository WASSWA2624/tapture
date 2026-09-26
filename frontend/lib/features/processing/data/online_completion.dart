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

/// How complete a record already is, as the skip rule reads it.
///
/// A stored value wins; an empty field falls back to the guarded local or
/// stored proposal for it.
final class OnlineCompletion {
  /// Creates the reader over the proposal [collector].
  const OnlineCompletion({required this._collector, required this._settings});

  final ProposalCollector _collector;
  final StageSettings _settings;

  /// One entry per template field, in field order.
  Future<List<SkipField>> forOnline(
    ProcessingJob job,
    RecordBundle bundle,
  ) async {
    final List<SkipField> stored = _stored(bundle);
    final Map<String, ProposedValue> proposed = <String, ProposedValue>{
      for (final ProposedValue value in (await _collector.collect(
        job,
        bundle,
      )).proposals)
        value.fieldKey: value,
    };
    final ProjectSettingsResolved settings = _settings.project(bundle);
    return <SkipField>[
      for (var index = 0; index < bundle.fields.length; index++)
        if (stored[index].value != null &&
            stored[index].value!.trim().isNotEmpty)
          stored[index]
        else
          (
            requiredField: bundle.fields[index].isRequired,
            value: proposed[bundle.fields[index].fieldKey]?.value,
            band: proposed[bundle.fields[index].fieldKey] == null
                ? null
                : Confidence.band(
                    score: proposed[bundle.fields[index].fieldKey]!.confidence,
                    high: settings.confidenceHigh,
                    medium: settings.confidenceMedium,
                  ),
          ),
    ];
  }

  List<SkipField> _stored(RecordBundle bundle) {
    final Map<String, RecordField> existing = <String, RecordField>{
      for (final RecordField field in bundle.existing) field.fieldKey: field,
    };
    return <SkipField>[
      for (final TemplateField field in bundle.fields)
        (
          requiredField: field.isRequired,
          value: existing[field.fieldKey]?.valueRaw,
          band:
              existing[field.fieldKey]?.verified == true ||
                  StageSupport.isManual(existing[field.fieldKey]?.source)
              ? ConfidenceBand.high
              : _band(existing[field.fieldKey]?.confidence, bundle),
        ),
    ];
  }

  ConfidenceBand? _band(double? score, RecordBundle bundle) {
    if (score == null) {
      return null;
    }
    final ProjectSettingsResolved settings = _settings.project(bundle);
    return Confidence.band(
      score: score,
      high: settings.confidenceHigh,
      medium: settings.confidenceMedium,
    );
  }
}
