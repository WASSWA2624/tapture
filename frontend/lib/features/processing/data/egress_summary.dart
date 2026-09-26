import 'dart:convert';
import 'dart:io';

import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettingsResolved;
import 'package:tapture/features/settings/settings.dart';

import '../domain/extraction_request.dart';
import '../domain/online_skip_rule.dart';
import '../domain/processing_job.dart';
import 'on_device_stage.dart';
import 'online_completion.dart';
import 'photo_paths.dart';
import 'record_bundle.dart';
import 'record_bundle_loader.dart';
import 'stage_settings.dart';
import 'stage_support.dart';

/// What the egress preview says would leave the device for one job.
final class EgressSummary {
  /// Creates the summary over the same collaborators the online stage uses.
  const EgressSummary({
    required this._loader,
    required this._settings,
    required this._paths,
    required this._onDevice,
    required this._completion,
  });

  final RecordBundleLoader _loader;
  final StageSettings _settings;
  final PhotoPaths _paths;
  final OnDeviceStage _onDevice;
  final OnlineCompletion _completion;

  /// The image count and approximate payload bytes for [job], or zero for
  /// both when no online call would be made.
  Future<({int imageCount, int payloadBytes})> summarise(
    ProcessingJob job,
  ) async {
    final RecordBundle bundle = await _loader.load(job.recordId);
    final ProjectSettingsResolved settings = _settings.project(bundle);
    if (OnlineSkipRule.reason(await _completion.forOnline(job, bundle)) !=
            null ||
        _settings.read(SettingKeys.offlineByChoice) ||
        !settings.aiEnabled ||
        !_settings
            .selection(AiOperation.extractFields)
            .provider
            .service
            .isAvailable) {
      return (imageCount: 0, payloadBytes: 0);
    }
    final List<String> images = settings.doNotSendImages
        ? const <String>[]
        : await _paths.compressed(bundle);
    var bytes = utf8.encode(await _onDevice.text(bundle)).length;
    bytes += utf8.encode(bundle.template.name).length;
    for (final TemplateField field in bundle.fields) {
      bytes += utf8.encode(field.label).length;
    }
    for (final Caption caption in bundle.captions) {
      bytes += utf8.encode(caption.textRaw).length;
    }
    for (final MapEntry<String, String> entry in StageSupport.stringMap(
      bundle.record.contextJson,
    ).entries) {
      bytes += utf8.encode(entry.key).length;
      bytes += utf8.encode(entry.value).length;
    }
    for (final TemplateRow row in bundle.rows) {
      bytes += utf8.encode(row.label).length;
    }
    for (final String rule in ExtractionRequest.defaultRules) {
      bytes += utf8.encode(rule).length;
    }
    for (final String path in images) {
      final File file = File(path);
      if (await file.exists()) {
        bytes += await file.length();
      }
    }
    return (imageCount: images.length, payloadBytes: bytes);
  }
}
