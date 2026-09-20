import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../domain/template_version.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'template_list_screen.dart' show templateListProvider;

/// One pass over a template's requiredness and visibility (§13.2, §12.3).
final class RequirednessController extends Notifier<RequirednessView> {
  /// Creates the controller for [templateId].
  RequirednessController(this.templateId);

  /// Template this pass edits.
  final String templateId;

  RequirednessView? _held;

  /// REQUIRED never refuses a capture write (§13.2).
  static bool get blocksCapture => false;

  /// Incomplete required fields land here, not in a refused save.
  static RecordStatus get incompleteSaveStatus => RecordStatus.needsReview;

  /// Records captured under an earlier version stay as they were.
  static bool marksOlderRecordIncomplete({
    required int capturedVersion,
    required int currentVersion,
  }) {
    return false;
  }

  @override
  RequirednessView build() {
    ref.onDispose(() => _held = null);
    final List<TemplateDef> rows =
        ref.watch(templateListProvider).asData?.value ?? const <TemplateDef>[];
    final RequirednessView? held = _held;
    if (held != null && held.dirty && held.templateId == templateId) {
      return held;
    }
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return _from(row);
      }
    }
    return _empty(templateId);
  }

  /// Sets [fieldKey] to [value] without writing.
  void set(String fieldKey, Requiredness value) {
    _replace(<FieldDef>[
      for (final FieldDef field in state.fields)
        field.fieldKey == fieldKey
            ? field.copyWith(requiredness: value)
            : field,
    ]);
  }

  /// Sets [hidden] on [fieldKey] without writing. Values stay on records.
  void setHidden(String fieldKey, bool hidden) {
    _replace(<FieldDef>[
      for (final FieldDef field in state.fields)
        field.fieldKey == fieldKey ? field.copyWith(hidden: hidden) : field,
    ]);
  }

  /// Expands or collapses [group] so inherited §13.3 groups can stay shut.
  void toggleGroup(String group) {
    final Set<String> next = Set<String>.of(state.expandedGroups);
    if (!next.add(group)) {
      next.remove(group);
    }
    state = (
      templateId: state.templateId,
      fields: state.fields,
      shippedRequiredness: state.shippedRequiredness,
      shippedHidden: state.shippedHidden,
      expandedGroups: next,
      saveError: state.saveError,
      dirty: state.dirty,
    );
    _held = state;
  }

  /// Writes every edit as one [TemplateRepository.save], which bumps version.
  Future<TemplateVersion> commit() async {
    final TemplateDef? source = _source();
    if (source == null) {
      const StorageFailure missing = StorageFailure(
        message: 'That template is no longer on this device.',
        recoveryAction: 'Open the template list and try again.',
      );
      state = (
        templateId: state.templateId,
        fields: state.fields,
        shippedRequiredness: state.shippedRequiredness,
        shippedHidden: state.shippedHidden,
        expandedGroups: state.expandedGroups,
        saveError: missing.message,
        dirty: state.dirty,
      );
      _held = state;
      throw missing;
    }
    if (!state.dirty) {
      return TemplateVersion(template: source);
    }
    final Map<String, FieldDef> drafts = <String, FieldDef>{
      for (final FieldDef field in state.fields) field.fieldKey: field,
    };
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(
          source.copyWith(
            fields: <FieldDef>[
              for (final FieldDef field in source.fields)
                drafts[field.fieldKey] ?? field,
            ],
          ),
        );
    switch (result) {
      case Success<TemplateDef>(:final TemplateDef value):
        _held = null;
        state = _from(value);
        return TemplateVersion(template: value);
      case FailureResult<TemplateDef>(:final Failure failure):
        state = (
          templateId: state.templateId,
          fields: state.fields,
          shippedRequiredness: state.shippedRequiredness,
          shippedHidden: state.shippedHidden,
          expandedGroups: state.expandedGroups,
          saveError: failure.message,
          dirty: true,
        );
        _held = state;
        throw failure;
    }
  }

  void _replace(List<FieldDef> fields) {
    state = (
      templateId: state.templateId,
      fields: fields,
      shippedRequiredness: state.shippedRequiredness,
      shippedHidden: state.shippedHidden,
      expandedGroups: state.expandedGroups,
      saveError: null,
      dirty: true,
    );
    _held = state;
  }

  TemplateDef? _source() {
    final List<TemplateDef> rows =
        ref.read(templateListProvider).asData?.value ?? const <TemplateDef>[];
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return row;
      }
    }
    return null;
  }
}

/// Draft of requiredness and visibility for one template. Records use
/// positional fields so the screen can read them without a second class.
typedef RequirednessView = ({
  String templateId,
  List<FieldDef> fields,
  Map<String, Requiredness> shippedRequiredness,
  Map<String, bool> shippedHidden,
  Set<String> expandedGroups,
  String? saveError,
  bool dirty,
});

/// Draft for one opening of the required-columns screen (FE-STATE-09).
final requirednessControllerProvider = NotifierProvider.autoDispose
    .family<RequirednessController, RequirednessView, String>(
      RequirednessController.new,
      retry: (int _, Object _) => null,
    );

RequirednessView _from(TemplateDef template) {
  return (
    templateId: template.id,
    fields: template.fields,
    shippedRequiredness: <String, Requiredness>{
      for (final FieldDef field in template.fields)
        field.fieldKey: field.requiredness,
    },
    shippedHidden: <String, bool>{
      for (final FieldDef field in template.fields)
        field.fieldKey: field.hidden,
    },
    expandedGroups: const <String>{},
    saveError: null,
    dirty: false,
  );
}

RequirednessView _empty(String templateId) {
  return (
    templateId: templateId,
    fields: const <FieldDef>[],
    shippedRequiredness: const <String, Requiredness>{},
    shippedHidden: const <String, bool>{},
    expandedGroups: const <String>{},
    saveError: null,
    dirty: false,
  );
}
