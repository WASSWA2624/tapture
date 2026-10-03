import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/processing/processing.dart'
    show ConfidenceBand, ConfidenceIndicator;
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef, TemplateRow;
import '../domain/review_group.dart';
import '../domain/review_repository.dart';
import 'evidence_viewer.dart';
import 'not_detected_row.dart';
import 'raw_refined_toggle.dart';
import 'reanalyse_action.dart';
import 'review_controller.dart';
import 'review_providers.dart';
import 'verify_action.dart';

/// The record's name, or its number when nothing names it yet.
String reviewTitleOf(RecordEntry entry, {LocalizedCopy? localizedCopy}) {
  return entry.name.trim().isEmpty
      ? (localizedCopy ?? Copy.english).recordsUntitled(entry.number)
      : entry.name;
}

/// Whether [entry] may be approved from review now.
bool canApproveInReview(RecordEntry entry) {
  return !entry.isDeleted &&
      RecordLifecycle.allows(entry.status, RecordStatus.approved);
}

/// One record's fields under review, as the review screen and the batch
/// queue both show them (task 016 step 1).
///
/// Fields that need attention come first; the confident ones sit in one
/// group that starts collapsed. Each row shows the field's label, its
/// value, its confidence band and where it came from; a tap edits it in the
/// shared value editor, and its evidence opens in one more tap. On an
/// expanded window the photos sit beside the fields.
final class ReviewBody extends ConsumerWidget {
  /// Creates the review of record [recordId] in project [projectId].
  const ReviewBody({
    required this.projectId,
    required this.recordId,
    this.onBackToRecords,
    super.key,
  });

  /// The project the record belongs to.
  final String projectId;

  /// The record under review.
  final String recordId;

  /// Leaves for the records list, from the empty state.
  final VoidCallback? onBackToRecords;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView<RecordEntry?>(
      value: ref.watch(recordEntryProvider(recordId)),
      loadingShape: SkeletonShape.detail,
      loadingCount: 1,
      isEmpty: (RecordEntry? entry) => entry == null,
      empty: () => AppEmptyState(
        icon: AppIcons.review,
        headline: Copy.of(context).recordGoneHeadline,
        message: Copy.of(context).recordGoneMessage,
        actionLabel: Copy.of(context).reviewBackToRecords,
        onAction: onBackToRecords,
      ),
      onRetry: () => ref.invalidate(recordEntryProvider(recordId)),
      data: (RecordEntry? entry) => AsyncValueView<TemplateDef?>(
        value: ref.watch(reviewTemplateProvider(recordId)),
        loadingShape: SkeletonShape.detail,
        loadingCount: 1,
        onRetry: () => ref.invalidate(reviewTemplateProvider(recordId)),
        data: (TemplateDef? template) =>
            _Loaded(projectId: projectId, entry: entry!, template: template),
      ),
    );
  }
}

/// One field as review lays it out.
typedef _Field = ({
  String fieldKey,
  String label,
  RecordValue? value,
  bool attention,
});

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.projectId,
    required this.entry,
    required this.template,
  });

  final String projectId;
  final RecordEntry entry;
  final TemplateDef? template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ReviewState state = ref.watch(reviewControllerProvider(entry.id));
    final ReviewController controller = ref.read(
      reviewControllerProvider(entry.id).notifier,
    );
    final ReviewFacts facts =
        ref.watch(reviewFactsProvider(entry.id)).value ?? noReviewFacts;
    final Map<String, String> labels = <String, String>{
      for (final FieldDef field in template?.fields ?? const <FieldDef>[])
        if (field.label.trim().isNotEmpty) field.fieldKey: field.label,
    };
    final List<_Field> fields = <_Field>[
      for (final (FieldValue field, ReviewGroup group) in orderForReview(
        entry,
        template ?? _noTemplate(entry),
      ))
        (
          fieldKey: field.fieldKey,
          label: labels[field.fieldKey] ?? field.fieldKey,
          value: entry.valueOf(field.fieldKey),
          attention:
              group == ReviewGroup.needsAttention ||
              facts.conflicts.contains(field.fieldKey),
        ),
    ];
    final bool editable = canApproveInReview(entry);
    final Widget columns = _Fields(
      projectId: projectId,
      entry: entry,
      fields: fields,
      facts: facts,
      state: state,
      controller: controller,
      editable: editable,
    );
    final bool sideBySide =
        context.sizeClass == SizeClass.expanded && entry.photos.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (state.failure case final Failure failure) ...<Widget>[
          AppBanner(
            key: const ValueKey<String>('review-failure'),
            message: <String>[
              Copy.of(context).failureMessage(failure),
              ?Copy.of(context).failureRecovery(failure),
            ].join(' '),
            icon: AppIcons.error,
            tone: SnackTone.error,
            onDismiss: controller.dismissFailure,
          ),
          const SizedBox(height: Space.x3),
        ],
        if (!editable) ...<Widget>[
          AppBanner(
            key: const ValueKey<String>('review-settled'),
            message: localCopy.reviewRecordSettled,
            icon: AppIcons.info,
            tone: SnackTone.info,
          ),
          const SizedBox(height: Space.x3),
        ],
        if (state.reanalysing) ...<Widget>[
          _Reanalysis(entry: entry, state: state, controller: controller),
          const SizedBox(height: Space.x3),
        ],
        if (sideBySide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: _Photos(
                  key: const ValueKey<String>('review-evidence-pane'),
                  photos: entry.photos,
                  size: Space.x12 * 3,
                ),
              ),
              const SizedBox(width: Space.x4),
              Expanded(
                flex: 3,
                child: KeyedSubtree(
                  key: const ValueKey<String>('review-fields-pane'),
                  child: columns,
                ),
              ),
            ],
          )
        else ...<Widget>[
          if (entry.photos.isNotEmpty) ...<Widget>[
            _Photos(photos: entry.photos, size: Space.x12 * 2),
            const SizedBox(height: Space.x3),
          ],
          columns,
        ],
        _Context(entry: entry, labels: labels),
        if (editable && !state.reanalysing) ...<Widget>[
          const SizedBox(height: Space.x4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              key: const ValueKey<String>('review-reanalyse'),
              label: localCopy.reviewReanalyse,
              icon: AppIcons.processing,
              variant: AppButtonVariant.text,
              busy: state.busy,
              onPressed: () => unawaited(_reanalyse(context, controller)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _reanalyse(
    BuildContext context,
    ReviewController controller,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<void> queued = await controller.reanalyse();
    if (queued is Success<void> && context.mounted) {
      showAppSnack(
        context,
        localCopy.reviewReanalyseQueued,
        tone: SnackTone.info,
      );
    }
  }
}

/// A template with no fields, when the record's is not on this device: the
/// values still show, by key.
TemplateDef _noTemplate(RecordEntry entry) {
  return TemplateDef(
    id: entry.templateId,
    templateKey: entry.templateId,
    name: '',
    version: entry.templateVersion,
    fields: const <FieldDef>[],
    identityFieldKeys: const <String>[],
    rows: const <TemplateRow>[],
  );
}

/// Needs attention, then the confident group behind one heading.
class _Fields extends StatelessWidget {
  const _Fields({
    required this.projectId,
    required this.entry,
    required this.fields,
    required this.facts,
    required this.state,
    required this.controller,
    required this.editable,
  });

  final String projectId;
  final RecordEntry entry;
  final List<_Field> fields;
  final ReviewFacts facts;
  final ReviewState state;
  final ReviewController controller;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<_Field> attention = <_Field>[
      for (final _Field field in fields)
        if (field.attention) field,
    ];
    final List<_Field> confident = <_Field>[
      for (final _Field field in fields)
        if (!field.attention) field,
    ];
    final List<String> unverified = <String>[
      for (final _Field field in confident)
        if (!(field.value?.verified ?? false)) field.fieldKey,
    ];
    if (fields.isEmpty) {
      return Text(
        localCopy.recordDetailNoValues,
        key: const ValueKey<String>('review-no-values'),
        style: AppText.body.copyWith(color: context.colors.onSurface),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (attention.isNotEmpty) ...<Widget>[
          AppSectionHeader(title: localCopy.reviewNeedsAttention),
          for (final _Field field in attention) _row(field, attention: true),
        ],
        if (confident.isNotEmpty) ...<Widget>[
          AppSectionHeader(
            key: const ValueKey<String>('review-confident-toggle'),
            title: localCopy.reviewConfidentGroup(confident.length),
            expanded: state.confidentOpen,
            onToggle: controller.toggleConfident,
          ),
          if (editable && unverified.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x4,
                vertical: Space.x1,
              ),
              child: VerifyAction(
                confidentCount: unverified.length,
                onVerifyConfident: state.busy
                    ? null
                    : () => unawaited(_verify(context, unverified)),
              ),
            ),
          if (state.confidentOpen)
            for (final _Field field in confident) _row(field, attention: false),
        ],
      ],
    );
  }

  Widget _row(_Field field, {required bool attention}) {
    return _FieldRow(
      key: ValueKey<String>(
        attention
            ? 'review-field-${field.fieldKey}'
            : 'review-confident-${field.fieldKey}',
      ),
      projectId: projectId,
      entry: entry,
      field: field,
      facts: facts,
      busy: state.busy,
      controller: controller,
      editable: editable,
      attention: attention,
    );
  }

  Future<void> _verify(BuildContext context, List<String> keys) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<void> verified = await controller.verify(keys);
    if (verified is Success<void> && context.mounted) {
      showAppSnack(
        context,
        localCopy.reviewVerifiedCount(keys.length),
        tone: SnackTone.success,
      );
    }
  }
}

/// One field: its label and value, marks beside it, and under it the step
/// the field needs, when it needs one.
class _FieldRow extends ConsumerWidget {
  const _FieldRow({
    required this.projectId,
    required this.entry,
    required this.field,
    required this.facts,
    required this.busy,
    required this.controller,
    required this.editable,
    required this.attention,
    super.key,
  });

  final String projectId;
  final RecordEntry entry;
  final _Field field;
  final ReviewFacts facts;
  final bool busy;
  final ReviewController controller;
  final bool editable;
  final bool attention;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordValue? value = field.value;
    final bool filled = value != null && value.hasValue;
    final bool twoSided = value != null && isTwoSided(value);
    final ValueSide side = value == null
        ? ValueSide.refined
        : finalSideOf(value, ref.watch(reviewSideProvider));
    final String shown = !filled
        ? localCopy.reviewNotDetected
        : twoSided && side == ValueSide.raw
        ? value.raw
        : value.display;
    final List<ValueEvidence> evidence =
        facts.evidence[field.fieldKey] ?? const <ValueEvidence>[];
    final VoidCallback? edit = editable
        ? () => unawaited(
            RecordFieldSheet.show(
              context,
              recordId: entry.id,
              fieldKey: field.fieldKey,
              label: field.label,
            ),
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppListTile(
          title: field.label,
          subtitle: shown,
          dense: true,
          trailing: _Marks(
            value: value,
            conflict: facts.conflicts.contains(field.fieldKey),
            showVerified: !attention,
            verifier: facts.verifiedBy[field.fieldKey] ?? '',
            onEvidence: evidence.isEmpty
                ? null
                : () => unawaited(
                    showAppSheet<void>(
                      context,
                      title: field.label,
                      contentSized: true,
                      builder: (BuildContext _) => EvidenceViewer(
                        evidence: evidence,
                        photos: entry.photos,
                      ),
                    ),
                  ),
          ),
          onTap: edit,
        ),
        if (editable && (!filled || twoSided || attention))
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.x4,
              Space.x1,
              Space.x4,
              Space.x3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!filled)
                  NotDetectedRow(
                    label: field.label,
                    onType: edit,
                    onPhotograph: () => unawaited(
                      context.push<void>(
                        RoutePaths.projectRecordEdit(projectId, entry.id),
                      ),
                    ),
                  )
                else ...<Widget>[
                  if (twoSided) ...<Widget>[
                    RawRefinedToggle(
                      side: side,
                      raw: value.raw,
                      refined: value.refined,
                      onChanged: busy
                          ? null
                          : (ValueSide next) => unawaited(
                              controller.chooseSide(
                                field.fieldKey,
                                next,
                                next == ValueSide.raw
                                    ? value.raw
                                    : value.refined!,
                              ),
                            ),
                    ),
                    const SizedBox(height: Space.x2),
                  ],
                  if (attention)
                    VerifyAction(
                      fieldLabel: field.label,
                      verified: value.verified,
                      verifier: facts.verifiedBy[field.fieldKey],
                      onVerify: busy
                          ? null
                          : () => unawaited(
                              controller.verify(<String>[field.fieldKey]),
                            ),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Beside a value: its conflict, lost evidence, verification or confidence,
/// and the control that shows its evidence.
class _Marks extends StatelessWidget {
  const _Marks({
    required this.value,
    required this.conflict,
    required this.showVerified,
    required this.verifier,
    required this.onEvidence,
  });

  final RecordValue? value;
  final bool conflict;
  final bool showVerified;

  /// Who verified the value; blank when no operator was known.
  final String verifier;
  final VoidCallback? onEvidence;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Widget? mark = _mark(context);
    final VoidCallback? evidence = onEvidence;
    if (mark == null && evidence == null) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (mark != null)
          ConstrainedBox(
            // The value keeps most of the row; a long mark shortens.
            constraints: BoxConstraints(
              maxWidth: context.responsive<double>(
                compact: Space.x12 * 2,
                medium: Space.x12 * 4,
              ),
            ),
            child: mark,
          ),
        if (evidence != null)
          AppIconButton(
            key: const ValueKey<String>('review-show-evidence'),
            icon: AppIcons.show,
            semanticLabel: localCopy.reviewShowEvidence,
            tooltip: localCopy.reviewShowEvidence,
            outlined: false,
            onPressed: evidence,
          ),
      ],
    );
  }

  Widget? _mark(BuildContext context) {
    final RecordValue? shown = value;
    if (conflict) {
      return AppStatusPill.badge(
        status: RecordStatus.needsReview,
        label: Copy.of(context).recordsFlagHasConflict,
      );
    }
    if (shown == null || !shown.hasValue) {
      return null;
    }
    if (shown.evidenceRemoved) {
      return AppStatusPill.badge(
        status: RecordStatus.needsReview,
        label: Copy.of(context).recordValueEvidenceRemoved,
      );
    }
    if (showVerified && shown.verified) {
      return AppStatusPill.badge(
        status: RecordStatus.approved,
        label: verifier.trim().isEmpty
            ? Copy.of(context).reviewVerified
            : Copy.of(context).reviewVerifiedBy(verifier.trim()),
      );
    }
    if (shown.valueSource == ValueSource.manual) {
      return null;
    }
    final ConfidenceBand? band = ConfidenceBand.fromStored(shown.band);
    if (band == null && shown.confidence == null) {
      return null;
    }
    return ConfidenceIndicator(
      band: band,
      score: shown.confidence,
      compact: true,
    );
  }
}

/// The record's photos as cached thumbnails; a tap opens the full photo in
/// the record photo viewer.
class _Photos extends StatelessWidget {
  const _Photos({required this.photos, required this.size, super.key});

  final List<RecordPhoto> photos;
  final double size;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.capturePhotosSection),
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x2,
          children: <Widget>[
            for (int index = 0; index < photos.length; index++)
              RecordThumb(
                key: ValueKey<String>('review-photo-${photos[index].id}'),
                sha256: photos[index].sha256,
                storagePath: photos[index].storagePath,
                quarterTurns: photos[index].quarterTurns,
                size: size,
                hasCaption: photos[index].hasCaption,
                semanticLabel: localCopy.recordPhotoPosition(
                  index + 1,
                  photos.length,
                ),
                onTap: () => unawaited(
                  RecordPhotoViewerScreen.open(
                    context,
                    photos: photos,
                    initialIndex: index,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The context in force when the record was captured, when there is any.
class _Context extends StatelessWidget {
  const _Context({required this.entry, required this.labels});

  final RecordEntry entry;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<MapEntry<String, String>> levels = <MapEntry<String, String>>[
      for (final MapEntry<String, String> level in entry.context.entries)
        if (level.value.trim().isNotEmpty) level,
    ];
    if (levels.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: Space.x3),
        AppSectionHeader(title: localCopy.recordDetailContextTitle),
        for (final MapEntry<String, String> level in levels)
          AppListTile(
            key: ValueKey<String>('review-context-${level.key}'),
            title: labels[level.key] ?? level.key,
            subtitle: level.value,
            dense: true,
          ),
      ],
    );
  }
}

/// Re-analysis on the record: its progress while the job runs, then what
/// it proposes beside each current value.
class _Reanalysis extends ConsumerWidget {
  const _Reanalysis({
    required this.entry,
    required this.state,
    required this.controller,
  });

  final RecordEntry entry;
  final ReviewState state;
  final ReviewController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (entry.status == RecordStatus.queued ||
        entry.status == RecordStatus.processing) {
      return AppBanner(
        key: const ValueKey<String>('review-reanalysing'),
        message: localCopy.reviewReanalysing,
        icon: AppIcons.processing,
        tone: SnackTone.info,
      );
    }
    final AsyncValue<List<ReanalyseProposal>> proposals = ref.watch(
      reviewProposalsProvider(entry.id),
    );
    if (proposals.isLoading && !proposals.hasValue) {
      return const AppSkeleton(count: 2);
    }
    return ReanalyseAction(
      proposals: proposals.value ?? const <ReanalyseProposal>[],
      accepted: state.accepted,
      failure: proposals.hasError ? Failure.from(proposals.error!) : null,
      busy: state.busy,
      onToggle: controller.toggleProposal,
      onApply: (Map<String, String> accepted) =>
          unawaited(_apply(context, accepted)),
      onDeclineAll: controller.declineProposals,
    );
  }

  Future<void> _apply(
    BuildContext context,
    Map<String, String> accepted,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<void> written = await controller.applyProposals(accepted);
    if (written is Success<void> && context.mounted) {
      showAppSnack(
        context,
        localCopy.reviewProposalsApplied(accepted.length),
        tone: SnackTone.success,
      );
    }
  }
}
