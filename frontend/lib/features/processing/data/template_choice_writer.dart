import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/projects.dart' show upsertProject;
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart' show ProjectSettings;

import '../domain/template_choice_needed.dart';
import 'stage_support.dart';

/// Applies a template decided during processing, and keeps the pins that
/// let a room answer the question once.
///
/// A pin lives in the project's own settings, keyed by the record's whole
/// context, so every item captured in the same place reuses it and the pin
/// travels with the project.
final class TemplateChoiceWriter {
  /// Creates the writer over [db].
  const TemplateChoiceWriter({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;

  /// The pin key for a record's stored context JSON: every level and value,
  /// in a stable order. Null when the record has no context to pin to.
  static String? pinKeyFor(String contextJson) {
    final Map<String, String> context = StageSupport.stringMap(contextJson);
    if (context.isEmpty) {
      return null;
    }
    final List<String> keys = context.keys.toList()..sort();
    return <String>[
      for (final String key in keys) '$key=${context[key]}',
    ].join('|');
  }

  /// The template [project] has pinned for [pinKey], or null.
  static String? pinned(Project project, String pinKey) {
    return ProjectSettings.decode(project.settings).templatePins?[pinKey];
  }

  /// Sets the record in [needed] to [choice]'s template, and pins it to the
  /// record's context when [TemplateChoice.pin] is set.
  Future<Result<void>> apply(
    TemplateChoiceNeeded needed,
    TemplateChoice choice,
  ) async {
    try {
      final Template? template =
          await (_db.select(_db.templates)..where(
                ($TemplatesTable table) => table.id.equals(choice.templateId),
              ))
              .getSingleOrNull();
      if (template == null || template.projectId != needed.projectId) {
        return const FailureResult<void>(
          ValidationFailure(
            message: 'That template is not in this project.',
            recoveryAction: 'Choose one of the templates offered.',
          ),
        );
      }
      final String? pinKey = needed.pinKey;
      await _db.transaction(() async {
        await setTemplate(needed.recordId, choice.templateId, reason: 'chosen');
        if (choice.pin && pinKey != null) {
          await _pin(needed.projectId, pinKey, choice.templateId);
        }
      });
      return const Success<void>(null);
    } on Failure catch (failure) {
      return FailureResult<void>(failure);
    } on Object catch (error) {
      return FailureResult<void>(storageFailureFrom(error));
    }
  }

  /// Stores [templateId] as [projectId]'s answer for [pinKey]. The project
  /// write bumps its revision and stamps this device.
  Future<void> _pin(String projectId, String pinKey, String templateId) async {
    final Project? project =
        await (_db.select(_db.projects)
              ..where(($ProjectsTable table) => table.id.equals(projectId)))
            .getSingleOrNull();
    if (project == null) {
      throw const ValidationFailure(
        message: 'That project is no longer on this device.',
        recoveryAction: 'Refresh the queue and try again.',
      );
    }
    final ProjectSettings settings = ProjectSettings.decode(project.settings);
    StageSupport.unwrap(
      await upsertProject(
        _db,
        row: ProjectsCompanion(
          id: Value<String>(projectId),
          settings: Value<String>(
            settings
                .copyWith(
                  templatePins: <String, String>{
                    ...?settings.templatePins,
                    pinKey: templateId,
                  },
                )
                .encode(),
          ),
        ),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      ),
    );
  }

  /// Moves [recordId] onto [templateId] and audits how it was decided.
  /// Does nothing when the record already uses it.
  Future<void> setTemplate(
    String recordId,
    String templateId, {
    required String reason,
  }) async {
    await _db.transaction(() async {
      final RecordRow? record =
          await (_db.select(_db.records)
                ..where(($RecordsTable table) => table.id.equals(recordId)))
              .getSingleOrNull();
      if (record == null || record.templateId == templateId) {
        return;
      }
      await (_db.update(
        _db.records,
      )..where(($RecordsTable table) => table.id.equals(recordId))).write(
        RecordsCompanion(
          templateId: Value<String>(templateId),
          updatedAt: Value<DateTime>(_clock.nowUtc()),
          updatedByDevice: Value<String>(_deviceId),
          rev: Value<int>(record.rev + 1),
        ),
      );
      await appendAudit(
        _db,
        entityType: 'records',
        entityId: recordId,
        action: AuditAction.updated,
        fieldKey: 'templateId',
        previousValue: record.templateId,
        newValue: templateId,
        reason: jsonEncode(<String, String>{'method': reason}),
        clock: _clock,
        device: _deviceId,
      );
    });
  }
}
