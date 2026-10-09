import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/record_entry.dart';
import '../domain/record_value.dart';
import 'record_edit_controller.dart';
import 'record_field_draft.dart';
import 'record_field_input.dart';
import 'record_providers.dart';

/// One value of a saved record, typed by hand in the input its field type
/// names, and Save: the record detail opens it when a value is tapped
/// (FBK0000162, FE-CONS-10). The captured original stays; the typed value is
/// written beside it with an audit row, exactly as the values page writes it
/// (FE-SEC-08, FE-SEC-09), and an approved record goes back to review.
///
/// A retired value opens read-only, with no Save: it is never edited or
/// deleted here.
class RecordFieldSheet extends ConsumerWidget {
  /// Creates the sheet for the value of [fieldKey] on [recordId].
  const RecordFieldSheet({
    required this.recordId,
    required this.fieldKey,
    super.key,
  });

  /// The record the value belongs to.
  final String recordId;

  /// The field whose value is edited.
  final String fieldKey;

  /// Opens the value of [fieldKey] on [recordId] as a bottom sheet, or a
  /// side panel on expanded windows (FE-CONS-05). [label] titles it when the
  /// caller already shows the field's label; otherwise a generic title does.
  static Future<void> show(
    BuildContext context, {
    required String recordId,
    required String fieldKey,
    String? label,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);

    return showAppSheet<void>(
      context,
      title: label == null || label.isEmpty
          ? localCopy.recordValueEditTitle
          : label,
      contentSized: true,
      builder: (BuildContext _) =>
          RecordFieldSheet(recordId: recordId, fieldKey: fieldKey),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RecordEntry?> record = ref.watch(
      recordEntryProvider(recordId),
    );
    final RecordEntry? entry = record.value;
    final AsyncValue<TemplateDef?> template = entry == null
        ? const AsyncLoading<TemplateDef?>()
        : ref.watch(
            recordCapturedTemplateProvider((
              id: entry.templateId,
              version: entry.templateVersion,
            )),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x3,
        Space.x0,
        Space.x3,
        Space.x3,
      ),
      child: AsyncValueView<RecordEntry?>(
        value: record,
        loadingCount: 1,
        onRetry: () => ref.invalidate(recordEntryProvider(recordId)),
        isEmpty: (RecordEntry? loaded) => loaded == null,
        empty: () => AppEmptyState(
          icon: AppIcons.records,
          headline: Copy.of(context).recordGoneHeadline,
          message: Copy.of(context).recordGoneMessage,
        ),
        data: (RecordEntry? loaded) {
          final LocalizedCopy localCopy = Copy.of(context);

          final RecordEntry found = loaded!;
          if (found.isDeleted) {
            return AppEmptyState(
              icon: AppIcons.delete,
              headline: localCopy.recordEditDeletedHeadline,
              message: localCopy.recordEditDeletedMessage,
            );
          }
          return AsyncValueView<TemplateDef?>(
            value: template,
            loadingCount: 1,
            onRetry: () =>
                ref.invalidate(recordEditTemplateProvider(found.templateId)),
            data: (TemplateDef? loadedTemplate) =>
                _valueOf(context, found, loadedTemplate),
          );
        },
      ),
    );
  }

  Widget _valueOf(
    BuildContext context,
    RecordEntry record,
    TemplateDef? template,
  ) {
    for (final RecordEditEntry entry in recordEditEntries(
      template: template,
      record: record,
    )) {
      if (entry.fieldKey == fieldKey) {
        return _FieldForm(record: record, entry: entry);
      }
    }
    for (final RecordValue value in recordRetiredValues(
      template: template,
      record: record,
    )) {
      if (value.fieldKey == fieldKey) {
        return _RetiredValue(value: value, template: template);
      }
    }
    return AppEmptyState(
      icon: AppIcons.fields,
      headline: Copy.of(context).recordFieldMissingHeadline,
      message: Copy.of(context).recordFieldMissingMessage,
    );
  }
}

/// The one editable value, its notices and Save.
class _FieldForm extends ConsumerWidget {
  const _FieldForm({required this.record, required this.entry});

  final RecordEntry record;
  final RecordEditEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String text =
        ref.watch(recordFieldDraftProvider(record.id))[entry.fieldKey] ??
        entry.initial;
    final RecordEditState state = ref.watch(
      recordEditControllerProvider(record.id),
    );
    final Failure? failure = state.failure;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (record.status == RecordStatus.approved) ...<Widget>[
          AppBanner(
            key: const ValueKey<String>('record-field-approved'),
            message: localCopy.recordEditApprovedNotice,
            icon: AppIcons.review,
            tone: SnackTone.warning,
          ),
          const SizedBox(height: Space.x3),
        ],
        RecordFieldInput(
          entry: entry,
          text: text,
          onChanged: (String next) {
            ref
                .read(recordFieldDraftProvider(record.id).notifier)
                .set(entry.fieldKey, next);
            ref
                .read(recordEditControllerProvider(record.id).notifier)
                .clearProblems();
          },
        ),
        for (final String problem in state.localizedProblems.map(
          localCopy.resolve,
        )) ...<Widget>[
          const SizedBox(height: Space.x2),
          AppBanner(
            key: const ValueKey<String>('record-field-problem'),
            message: problem,
            icon: AppIcons.warning,
            tone: SnackTone.warning,
          ),
        ],
        if (failure != null) ...<Widget>[
          const SizedBox(height: Space.x2),
          AppBanner(
            key: const ValueKey<String>('record-field-failure'),
            message: <String>[
              Copy.of(context).failureMessage(failure),
              ?Copy.of(context).failureRecovery(failure),
            ].join(' '),
            icon: AppIcons.error,
            tone: SnackTone.error,
          ),
        ],
        const SizedBox(height: Space.x3),
        AppPrimaryAction(
          key: const ValueKey<String>('record-field-save'),
          label: localCopy.save,
          busy: state.saving,
          onPressed: () => unawaited(_save(context, ref)),
        ),
      ],
    );
  }

  /// Writes the value when it changed, then says so and closes. A failure
  /// keeps the sheet open with the typed value (FE-SIMP-09).
  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final NavigatorState navigator = Navigator.of(context);
    final RecordFieldDraft drafts = ref.read(
      recordFieldDraftProvider(record.id).notifier,
    );
    final String text =
        ref.read(recordFieldDraftProvider(record.id))[entry.fieldKey] ??
        entry.initial;
    if (!recordFieldChanged(entry, text)) {
      drafts.forget(<String>[entry.fieldKey]);
      navigator.pop();
      return;
    }
    final bool backToReview = record.status == RecordStatus.approved;
    final Result<void> saved = await ref
        .read(recordEditControllerProvider(record.id).notifier)
        .save(<RecordFieldChange>[(entry: entry, text: text)]);
    if (saved is! Success<void> || !context.mounted) {
      return;
    }
    drafts.forget(<String>[entry.fieldKey]);
    showAppSnack(
      context,
      localCopy.recordValuesSaved(1, backToReview: backToReview),
      tone: SnackTone.success,
    );
    navigator.pop();
  }
}

/// A retired value, read-only: why it cannot be edited, then the value.
class _RetiredValue extends StatelessWidget {
  const _RetiredValue({required this.value, required this.template});

  final RecordValue value;

  /// Null when the record's template is no longer on this device.
  final TemplateDef? template;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          localCopy.recordRetiredValuesMessage,
          style: AppText.caption.copyWith(color: context.colors.onSurface),
        ),
        const SizedBox(height: Space.x2),
        recordRetiredValueTile(value, template: template),
      ],
    );
  }
}
