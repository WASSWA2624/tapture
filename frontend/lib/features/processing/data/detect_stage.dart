import 'package:drift/drift.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/projects/projects.dart' show ProjectSettings;
import 'package:tapture/features/settings/settings.dart';

import '../domain/template_choice_needed.dart';
import '../domain/template_detection.dart';
import 'on_device_stage.dart';
import 'record_bundle.dart';
import 'stage_settings.dart';
import 'stage_support.dart';
import 'template_choice_writer.dart';

/// The detect stage: settles which template the record fills, on the device
/// and before any model call.
///
/// A project with one template, or one set to choose templates by hand, keeps
/// the template capture gave the record. Otherwise the selection order runs:
/// a template pinned to the record's context, then a confident local score
/// of on-device text against each template's detection profile. When local
/// scoring narrows the field without deciding, the stage returns a
/// [TemplateChoiceNeeded] for the model, then the operator, to answer. With no signal at
/// all the capture template stands. No network is used here.
final class DetectStage {
  /// Creates the stage.
  const DetectStage({
    required this._db,
    required this._settings,
    required this._onDevice,
    required this._choices,
  });

  final AppDatabase _db;
  final StageSettings _settings;
  final OnDeviceStage _onDevice;
  final TemplateChoiceWriter _choices;

  /// Settles [bundle]'s template, or returns the question when it cannot.
  Future<TemplateChoiceNeeded?> run(
    RecordBundle bundle,
    CancellationToken cancel,
  ) async {
    if (bundle.template.id.isEmpty) {
      throw const ValidationFailure(
        message: 'This record has no template.',
        recoveryAction: 'Choose a template, then retry processing.',
      );
    }
    final List<Template> templates = await _projectTemplates(
      bundle.record.projectId,
    );
    if (templates.length <= 1) {
      return null;
    }
    final String? choice = ProjectSettings.decode(
      bundle.project.settings,
    ).templateChoice;
    if (choice != null && choice != _auto) {
      // The operator picked this template at capture.
      return null;
    }
    final String? pinKey = TemplateChoiceWriter.pinKeyFor(
      bundle.record.contextJson,
    );
    final DetectionDecision decision = TemplateDetection.decide((
      pinnedTemplateId: pinKey == null
          ? null
          : TemplateChoiceWriter.pinned(bundle.project, pinKey),
      templates: <DetectionProfile>[
        for (final Template template in templates) _profile(template),
      ],
      ocrText: await _onDevice.text(bundle),
      referenceTemplateId: null,
      confident: _settings.read(SettingKeys.aiDetectionConfident),
      gap: _settings.read(SettingKeys.aiDetectionGap),
    ));
    final String? decided = decision.templateId;
    if (decided != null) {
      await _choices.setTemplate(
        bundle.record.id,
        decided,
        reason: decision.rule.name,
      );
      return null;
    }
    if (decision.shortlist.isEmpty) {
      return null;
    }
    final Map<String, String> names = <String, String>{
      for (final Template template in templates) template.id: template.name,
    };
    return TemplateChoiceNeeded(
      recordId: bundle.record.id,
      projectId: bundle.record.projectId,
      shortlist: <({String templateId, String label})>[
        for (final String id in decision.shortlist)
          (templateId: id, label: names[id] ?? id),
      ],
      pinKey: pinKey,
      modelMayDecide: decision.callModel,
    );
  }

  Future<List<Template>> _projectTemplates(String projectId) async {
    final List<Template> rows =
        await (_db.select(_db.templates)
              ..where(
                ($TemplatesTable table) => table.projectId.equals(projectId),
              )
              ..orderBy(<OrderClauseGenerator<$TemplatesTable>>[
                ($TemplatesTable table) => OrderingTerm.asc(table.name),
              ]))
            .get();
    if (rows.isEmpty) {
      return rows;
    }
    final Set<String> removed = <String>{
      for (final Tombstone row
          in await (_db.select(_db.tombstones)..where(
                ($TombstonesTable table) =>
                    table.entityType.equals(_db.templates.actualTableName) &
                    table.entityId.isIn(<String>[
                      for (final Template template in rows) template.id,
                    ]),
              ))
              .get())
        row.entityId,
    };
    return <Template>[
      for (final Template template in rows)
        if (!removed.contains(template.id)) template,
    ];
  }
}

/// A template's stored detection profile, as local scoring reads it. Object
/// classes count as keywords.
DetectionProfile _profile(Template template) {
  final Map<String, Object?> detection = switch (StageSupport.json(
    template.detection,
  )) {
    final Map<Object?, Object?> map => <String, Object?>{
      for (final MapEntry<Object?, Object?> entry in map.entries)
        if (entry.key is String) entry.key! as String: entry.value,
    },
    _ => const <String, Object?>{},
  };
  List<String> strings(String key) {
    final Object? raw = detection[key];
    return raw is List
        ? <String>[
            for (final Object? item in raw)
              if (item is String && item.trim().isNotEmpty) item,
          ]
        : const <String>[];
  }

  return (
    templateId: template.id,
    keywords: <String>[...strings('keywords'), ...strings('object_classes')],
    negativeKeywords: strings('negative_keywords'),
    identifierPatterns: strings('identifier_patterns'),
    weight: 1,
  );
}

/// The project setting value under which capture assigns a template itself.
const String _auto = 'auto';
