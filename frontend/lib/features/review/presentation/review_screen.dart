import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/field_ordering.dart';

/// One record, attention first, approvable in one tap (task 016).
///
/// Confident fields start collapsed. On an expanded window the evidence
/// sits beside the fields. The size class comes from the breakpoint helper.
final class ReviewScreen extends ConsumerWidget {
  /// Creates the review of [record], or of [recordId] loaded from the store.
  const ReviewScreen({
    this.recordId,
    this.record,
    this.template,
    this.failure,
    this.confidentOpen = false,
    this.onApprove,
    this.onToggleConfident,
    super.key,
  });

  /// Loads this record when [record] is not passed in.
  final String? recordId;

  /// The record being reviewed. Null with no [recordId] is the empty state.
  final RecordEntry? record;

  /// The template that names the fields. Null shows values by key.
  final TemplateDef? template;

  /// Why the record could not be read.
  final Failure? failure;

  /// Whether the confident group is open. It starts closed.
  final bool confidentOpen;

  /// Approves and moves on.
  final VoidCallback? onApprove;

  /// Opens or closes the confident group.
  final ValueChanged<bool>? onToggleConfident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? id = recordId;
    if (record == null && failure == null && id != null) {
      final AsyncValue<RecordEntry?> loaded = ref.watch(
        recordEntryProvider(id),
      );
      return loaded.when(
        loading: () =>
            _page(context, loaded: null, failed: null, waiting: true),
        error: (Object error, StackTrace _) =>
            _page(context, loaded: null, failed: Failure.from(error)),
        data: (RecordEntry? entry) {
          if (entry == null || template != null) {
            return _page(context, loaded: entry, failed: null, shape: template);
          }
          final AsyncValue<TemplateDef?> shape = ref.watch(
            recordEditTemplateProvider(entry.templateId),
          );
          return shape.when(
            loading: () =>
                _page(context, loaded: null, failed: null, waiting: true),
            error: (Object error, StackTrace _) =>
                _page(context, loaded: null, failed: Failure.from(error)),
            data: (TemplateDef? value) =>
                _page(context, loaded: entry, failed: null, shape: value),
          );
        },
      );
    }
    return _page(context, loaded: record, failed: failure, shape: template);
  }

  Widget _page(
    BuildContext context, {
    required RecordEntry? loaded,
    required Failure? failed,
    TemplateDef? shape,
    bool waiting = false,
  }) {
    return AppPage(
      key: const ValueKey<String>('route-review'),
      title: Copy.reviewTitle,
      footer: loaded == null || failed != null
          ? null
          : AppButton(
              key: const ValueKey<String>('review-approve'),
              label: Copy.reviewApproveNext,
              expand: true,
              onPressed: onApprove,
            ),
      body: waiting
          ? const SizedBox.shrink()
          : failed != null
          ? AppErrorState(failure: failed)
          : loaded == null
          ? const AppEmptyState(
              icon: AppIcons.review,
              headline: Copy.reviewEmptyHeadline,
              message: Copy.reviewEmptyMessage,
            )
          : _body(context, loaded, shape),
    );
  }

  Widget _body(BuildContext context, RecordEntry loaded, TemplateDef? shape) {
    final TemplateDef resolved =
        shape ??
        TemplateDef(
          id: loaded.templateId,
          templateKey: loaded.templateId,
          name: '',
          version: 1,
          fields: const <FieldDef>[],
          identityFieldKeys: const <String>[],
          rows: const <TemplateRow>[],
        );
    final List<(FieldValue, ReviewGroup)> ordered = orderForReview(
      loaded,
      resolved,
    );
    final Widget fields = _Fields(
      ordered: ordered,
      confidentOpen: confidentOpen,
      onToggleConfident: onToggleConfident,
    );
    if (context.sizeClass != SizeClass.expanded) {
      return fields;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Expanded(
          key: ValueKey<String>('review-evidence-pane'),
          child: SizedBox.shrink(),
        ),
        const SizedBox(width: Space.x4),
        Expanded(
          key: const ValueKey<String>('review-fields-pane'),
          child: fields,
        ),
      ],
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({
    required this.ordered,
    required this.confidentOpen,
    required this.onToggleConfident,
  });

  final List<(FieldValue, ReviewGroup)> ordered;
  final bool confidentOpen;
  final ValueChanged<bool>? onToggleConfident;

  @override
  Widget build(BuildContext context) {
    final List<FieldValue> attention = <FieldValue>[
      for (final (FieldValue value, ReviewGroup group) in ordered)
        if (group == ReviewGroup.needsAttention) value,
    ];
    final List<FieldValue> confident = <FieldValue>[
      for (final (FieldValue value, ReviewGroup group) in ordered)
        if (group == ReviewGroup.confident) value,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.reviewNeedsAttention),
        for (final FieldValue value in attention)
          AppListTile(
            key: ValueKey<String>('review-field-${value.fieldKey}'),
            title: value.fieldKey,
            subtitle: value.value?.toString() ?? Copy.reviewNotDetected,
          ),
        AppButton(
          key: const ValueKey<String>('review-confident-toggle'),
          label: Copy.reviewConfident,
          variant: AppButtonVariant.secondary,
          onPressed: () => onToggleConfident?.call(!confidentOpen),
        ),
        if (confidentOpen)
          for (final FieldValue value in confident)
            AppListTile(
              key: ValueKey<String>('review-confident-${value.fieldKey}'),
              title: value.fieldKey,
              subtitle: value.value?.toString(),
            ),
      ],
    );
  }
}
