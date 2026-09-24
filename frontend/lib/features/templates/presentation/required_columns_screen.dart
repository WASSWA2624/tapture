import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import 'requiredness_controller.dart';
import 'template_list_screen.dart' show templateListProvider;
import 'template_locations.dart';

/// Bulk requiredness and visibility for one template (§12.3, §13.2).
class RequiredColumnsScreen extends ConsumerWidget {
  /// Creates the screen for [templateId].
  const RequiredColumnsScreen({super.key, required this.templateId});

  /// Template this pass edits.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TemplateDef?> value = ref
        .watch(templateListProvider)
        .whenData(_pick);
    final RequirednessView view = ref.watch(
      requirednessControllerProvider(templateId),
    );
    return AppPage(
      key: const ValueKey<String>('route-template-required'),
      title: Copy.requiredColumnsTitle,
      scrollable: false,
      footer: value.asData?.value == null
          ? null
          : AppPrimaryAction(
              label: Copy.save,
              onPressed: () => _commit(context, ref),
            ),
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) => row == null || row.fields.isEmpty,
        empty: () => const AppEmptyState(
          icon: Icons.rule,
          headline: Copy.requiredColumnsEmptyHeadline,
          message: Copy.requiredColumnsEmptyMessage,
        ),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (TemplateDef? _) => _list(context, ref, view),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, RequirednessView view) {
    final List<_Group> groups = _groups(view);
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x4),
      children: <Widget>[
        if (view.saveError != null)
          AppBanner(
            message: view.saveError!,
            icon: Icons.error_outline,
            tone: SnackTone.error,
          ),
        for (final _Group group in groups) ...<Widget>[
          AppSectionHeader(
            title: group.title,
            dense: true,
            action: group.inherited
                ? AppButton(
                    label: group.expanded
                        ? Copy.requiredColumnHideGroup
                        : Copy.requiredColumnShowGroup,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      ref
                          .read(
                            requirednessControllerProvider(templateId).notifier,
                          )
                          .toggleGroup(group.key);
                    },
                  )
                : null,
          ),
          if (group.expanded)
            for (final FieldDef field in group.fields) _row(ref, view, field),
        ],
      ],
    );
  }

  Widget _row(WidgetRef ref, RequirednessView view, FieldDef field) {
    final Requiredness? shipped = view.shippedRequiredness[field.fieldKey];
    final bool moved = shipped != null && shipped != field.requiredness;
    final RequirednessController controller = ref.read(
      requirednessControllerProvider(templateId).notifier,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppListTile(
          title: field.label,
          subtitle: moved ? Copy.requiredColumnShipped(_mark(shipped)) : null,
          dense: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x4),
          child: AppSwitchTile(
            title: Copy.requiredColumnHide,
            value: field.hidden,
            dense: true,
            divided: false,
            onChanged: (bool hidden) {
              controller.setHidden(field.fieldKey, hidden);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x2),
          child: AppRadioGroup<Requiredness>(
            label: Copy.requiredColumnRadios(field.label),
            showLabel: false,
            direction: Axis.horizontal,
            value: field.requiredness,
            options: <Choice<Requiredness>>[
              Choice<Requiredness>(
                Requiredness.required,
                Copy.requiredColumnCell(field.label, Copy.fieldRequired),
              ),
              Choice<Requiredness>(
                Requiredness.recommended,
                Copy.requiredColumnCell(field.label, Copy.fieldRecommended),
              ),
              Choice<Requiredness>(
                Requiredness.optional,
                Copy.requiredColumnCell(field.label, Copy.fieldOptional),
              ),
            ],
            onChanged: (Requiredness value) {
              controller.set(field.fieldKey, value);
            },
          ),
        ),
      ],
    );
  }

  TemplateDef? _pick(List<TemplateDef> rows) {
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return row;
      }
    }
    return null;
  }

  Future<void> _commit(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(requirednessControllerProvider(templateId).notifier)
          .commit();
      if (context.mounted) {
        GoRouter.maybeOf(
          context,
        )?.go(TemplateLocations.detail(context, templateId));
      }
    } on Failure {
      return;
    }
  }
}

final class _Group {
  const _Group({
    required this.key,
    required this.title,
    required this.inherited,
    required this.expanded,
    required this.fields,
  });

  final String key;
  final String title;
  final bool inherited;
  final bool expanded;
  final List<FieldDef> fields;
}

List<_Group> _groups(RequirednessView view) {
  final List<String> order = <String>[];
  final Map<String, List<FieldDef>> byKey = <String, List<FieldDef>>{};
  for (final FieldDef field in view.fields) {
    final String key = field.group ?? '';
    final List<FieldDef>? existing = byKey[key];
    if (existing == null) {
      order.add(key);
      byKey[key] = <FieldDef>[field];
    } else {
      existing.add(field);
    }
  }
  return <_Group>[
    for (final String key in order)
      _Group(
        key: key,
        title: key.isEmpty
            ? Copy.requiredColumnUngrouped
            : Copy.requiredColumnGroup(key),
        inherited: _inherited.contains(key),
        expanded:
            !_inherited.contains(key) || view.expandedGroups.contains(key),
        fields: byKey[key]!,
      ),
  ];
}

String _mark(Requiredness requiredness) {
  return switch (requiredness) {
    Requiredness.required => Copy.fieldRequired,
    Requiredness.recommended => Copy.fieldRecommended,
    Requiredness.optional => Copy.fieldOptional,
  };
}

const Set<String> _inherited = <String>{
  'record_admin',
  'location_context',
  'evidence',
  'review',
};
