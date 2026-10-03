import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/record_entry.dart';
import '../domain/record_value.dart';
import 'record_edit_controller.dart';
import 'record_field_draft.dart';
import 'record_field_input.dart';
import 'record_providers.dart';

/// Edits a saved record's values (task 014 step 5), so nothing about a
/// record is frozen after capture.
///
/// Every live field of the record's template is edited through the shared
/// inline field editor, as capture edits it (FE-CONS-01). Values the
/// template no longer declares are kept and shown read-only as retired;
/// they are never edited or deleted here. A value whose source photos were
/// removed is marked. Save writes only what changed, in one transaction with
/// an audit row per value; an approved record goes back to review, and the
/// page says so before Save. Leaving with unsaved changes asks first; a
/// failed save keeps what was typed (FE-SIMP-09).
class RecordEditScreen extends ConsumerWidget {
  /// Creates the values page for [recordId].
  const RecordEditScreen({required this.recordId, super.key});

  /// The record whose values are edited.
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

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
    return AppPage(
      key: const ValueKey<String>('route-record-values'),
      title: localCopy.recordValuesEditTitle,
      subtitle: entry == null || entry.name.isEmpty ? null : entry.name,
      scrollable: false,
      body: _body(context, ref, record, template),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<RecordEntry?> record,
    AsyncValue<TemplateDef?> template,
  ) {
    final RecordEntry? entry = record.value;
    if (!record.hasError &&
        !template.hasError &&
        template.hasValue &&
        entry != null &&
        !entry.isDeleted) {
      final TemplateDef? loaded = template.value;
      final List<RecordEditEntry> entries = recordEditEntries(
        template: loaded,
        record: entry,
      );
      final List<RecordValue> retired = recordRetiredValues(
        template: loaded,
        record: entry,
      );
      if (entries.isNotEmpty || retired.isNotEmpty) {
        return _RecordValuesForm(
          record: entry,
          template: loaded,
          entries: entries,
          retired: retired,
        );
      }
    }
    // Loading, failure and the empty states scroll, so 200 percent text in
    // landscape never clips them (FE-A11Y-03).
    return _StatePanel(
      child: AsyncValueView<RecordEntry?>(
        value: record,
        loadingShape: SkeletonShape.detail,
        onRetry: () => ref.invalidate(recordEntryProvider(recordId)),
        isEmpty: (RecordEntry? loaded) => loaded == null,
        empty: () => AppEmptyState(
          icon: AppIcons.records,
          headline: Copy.of(context).recordGoneHeadline,
          message: Copy.of(context).recordGoneMessage,
        ),
        data: (RecordEntry? loaded) {
          final RecordEntry found = loaded!;
          if (found.isDeleted) {
            return AppEmptyState(
              icon: AppIcons.delete,
              headline: Copy.of(context).recordEditDeletedHeadline,
              message: Copy.of(context).recordEditDeletedMessage,
            );
          }
          return AsyncValueView<TemplateDef?>(
            value: template,
            loadingShape: SkeletonShape.detail,
            onRetry: () =>
                ref.invalidate(recordEditTemplateProvider(found.templateId)),
            data: (TemplateDef? loadedTemplate) => AppEmptyState(
              icon: AppIcons.fields,
              headline: Copy.of(context).recordEditNoFieldsHeadline,
              message: loadedTemplate == null
                  ? Copy.of(context).recordTemplateMissingNotice
                  : Copy.of(context).recordEditNoFieldsMessage,
            ),
          );
        },
      ),
    );
  }
}

/// The values form: notices, one inline editor per live field, then the
/// retired values read-only, over a pinned Save.
class _RecordValuesForm extends ConsumerWidget {
  const _RecordValuesForm({
    required this.record,
    required this.template,
    required this.entries,
    required this.retired,
  });

  final RecordEntry record;

  /// Null when the record's template is no longer on this device.
  final TemplateDef? template;
  final List<RecordEditEntry> entries;
  final List<RecordValue> retired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Map<String, String> draft = ref.watch(
      recordFieldDraftProvider(record.id),
    );
    final RecordEditState state = ref.watch(
      recordEditControllerProvider(record.id),
    );
    final Failure? failure = state.failure;
    return AppForm(
      guardUnsaved: true,
      dirty: _changesIn(draft).isNotEmpty,
      errors: state.localizedProblems
          .map(localCopy.resolve)
          .toList(growable: false),
      submitLabel: localCopy.save,
      onSubmit: () => _save(context, ref),
      fields: <Widget>[
        if (template == null)
          AppBanner(
            key: const ValueKey<String>('record-edit-template-missing'),
            message: localCopy.recordTemplateMissingNotice,
            icon: AppIcons.warning,
            tone: SnackTone.warning,
          ),
        if (record.status == RecordStatus.approved)
          AppBanner(
            key: const ValueKey<String>('record-edit-approved'),
            message: localCopy.recordEditApprovedNotice,
            icon: AppIcons.review,
            tone: SnackTone.warning,
          ),
        if (failure != null)
          AppBanner(
            key: const ValueKey<String>('record-edit-failure'),
            message: <String>[
              Copy.of(context).failureMessage(failure),
              ?Copy.of(context).failureRecovery(failure),
            ].join(' '),
            icon: AppIcons.error,
            tone: SnackTone.error,
          ),
        for (final RecordEditEntry entry in entries)
          RecordFieldInput(
            entry: entry,
            text: draft[entry.fieldKey] ?? entry.initial,
            onChanged: (String text) {
              ref
                  .read(recordFieldDraftProvider(record.id).notifier)
                  .set(entry.fieldKey, text);
              ref
                  .read(recordEditControllerProvider(record.id).notifier)
                  .clearProblems();
            },
          ),
        if (retired.isNotEmpty) ...<Widget>[
          AppSectionHeader(title: localCopy.recordRetiredValuesTitle),
          Text(
            localCopy.recordRetiredValuesMessage,
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
          for (final RecordValue value in retired)
            recordRetiredValueTile(value, template: template),
        ],
      ],
    );
  }

  List<RecordFieldChange> _changesIn(Map<String, String> draft) {
    return <RecordFieldChange>[
      for (final RecordEditEntry entry in entries)
        if (draft[entry.fieldKey] case final String text
            when recordFieldChanged(entry, text))
          (entry: entry, text: text),
    ];
  }

  /// Writes what changed, then says so and leaves. A failure stays on the
  /// page with everything typed (FE-SIMP-09).
  Future<bool> _save(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final NavigatorState navigator = Navigator.of(context);
    final RecordFieldDraft drafts = ref.read(
      recordFieldDraftProvider(record.id).notifier,
    );
    final List<RecordFieldChange> changes = _changesIn(
      ref.read(recordFieldDraftProvider(record.id)),
    );
    if (changes.isEmpty) {
      drafts.clear();
      if (navigator.canPop()) {
        navigator.pop();
      }
      return true;
    }
    final bool backToReview = record.status == RecordStatus.approved;
    final Result<void> saved = await ref
        .read(recordEditControllerProvider(record.id).notifier)
        .save(changes);
    if (saved is! Success<void>) {
      return false;
    }
    if (!context.mounted) {
      return true;
    }
    drafts.clear();
    showAppSnack(
      context,
      localCopy.recordValuesSaved(changes.length, backToReview: backToReview),
      tone: SnackTone.success,
    );
    if (navigator.canPop()) {
      navigator.pop();
    }
    return true;
  }
}

/// A state panel that scrolls in the page's readable column.
class _StatePanel extends StatelessWidget {
  const _StatePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppPage.gutter(context),
        vertical: Space.x2,
      ),
      child: ContentConstraint(child: child),
    );
  }
}
