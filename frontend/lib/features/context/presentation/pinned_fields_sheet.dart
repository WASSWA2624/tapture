import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/context_repository.dart';
import '../domain/context_state.dart';
import 'context_picker_sheet.dart';
import 'context_providers.dart';

/// Opens the pinned-fields sheet: every field the templates mark stickable,
/// each opening the same picker a level uses.
Future<void> showPinnedFieldsSheet({
  required BuildContext context,
  required String projectId,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<void>(
    context,
    title: localCopy.contextPinnedTitle,
    contentSized: true,
    builder: (BuildContext context) {
      return PinnedFieldsSheet(projectId: projectId);
    },
  );
}

/// Opens the picker for pinned [field]: its recents, its dataset search and
/// free text, as for a level, and a way to clear the pin (spec §20.3).
Future<void> showPinPickerSheet({
  required BuildContext context,
  required String projectId,
  required FieldDef field,
  required String currentValue,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  final Object? datasetId = field.lookup['datasetId'];
  return showAppSheet<void>(
    context,
    title: localCopy.contextPickerTitle(field.label),
    contentSized: true,
    builder: (BuildContext context) {
      final LocalizedCopy localCopy = Copy.of(context);

      return ContextPickerSheet(
        projectId: projectId,
        fieldKey: field.fieldKey,
        label: field.label,
        datasetId: datasetId is String ? datasetId : null,
        currentValue: currentValue,
        clearLabel: localCopy.contextClearPin,
        write: (ContextRepository repo, String value) =>
            _pin(repo, projectId, field.fieldKey, value),
      );
    },
  );
}

/// Lists the stickable non-hierarchical fields and their pinned values.
class PinnedFieldsSheet extends ConsumerWidget {
  /// Creates the sheet body.
  const PinnedFieldsSheet({super.key, required this.projectId});

  /// Owning project.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TemplateDef>> templates = ref.watch(
      contextTemplatesProvider(projectId),
    );
    final ContextState state =
        ref.watch(projectContextProvider(projectId)).asData?.value ??
        const ContextState();
    return AsyncValueView<List<TemplateDef>>(
      value: templates,
      isEmpty: (List<TemplateDef> loaded) =>
          pinnableFields(loaded, state).isEmpty,
      empty: () => _empty(context, templates.asData?.value ?? const []),
      onRetry: () => ref.invalidate(contextTemplatesProvider(projectId)),
      data: (List<TemplateDef> loaded) {
        final LocalizedCopy localCopy = Copy.of(context);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppBanner(
              message: localCopy.contextPinnedRelevance,
              icon: AppIcons.pin,
              tone: SnackTone.info,
            ),
            for (final FieldDef field in pinnableFields(loaded, state))
              AppListTile(
                key: ValueKey<String>('pinned-field-${field.fieldKey}'),
                title: field.label,
                subtitle:
                    state.pinned[field.fieldKey] ??
                    localCopy.contextValueNotSet,
                leading: const Icon(AppIcons.pin),
                trailing: const Icon(AppIcons.open),
                onTap: () => unawaited(
                  showPinPickerSheet(
                    context: context,
                    projectId: projectId,
                    field: field,
                    currentValue: state.pinned[field.fieldKey] ?? '',
                  ),
                ),
              ),
            const SizedBox(height: Space.x3),
          ],
        );
      },
    );
  }

  /// No stickable field yet: mark one on a template, or add a template.
  Widget _empty(BuildContext context, List<TemplateDef> templates) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool hasTemplates = templates.isNotEmpty;
    return AppEmptyState(
      icon: AppIcons.pin,
      headline: localCopy.contextPinnedEmptyHeadline,
      message: hasTemplates
          ? localCopy.contextPinnedEmptyMessage
          : localCopy.contextNoTemplatesMessage,
      actionLabel: hasTemplates
          ? localCopy.contextMarkPinnable
          : localCopy.contextOpenTemplates,
      onAction: () => unawaited(
        context.push(
          hasTemplates
              ? RoutePaths.projectTemplates(projectId)
              : RoutePaths.templateLibrary(projectId: projectId),
        ),
      ),
    );
  }
}

/// Pins [value] on [fieldKey], or clears that pin when [value] is empty,
/// keeping every other pin.
Future<Result<ContextState>> _pin(
  ContextRepository repo,
  String projectId,
  String fieldKey,
  String value,
) async {
  final Result<ContextState> loaded = await repo.load(projectId);
  switch (loaded) {
    case FailureResult<ContextState>():
      return loaded;
    case Success<ContextState>(value: final ContextState current):
      final Map<String, String> pinned = <String, String>{...current.pinned};
      if (value.isEmpty) {
        pinned.remove(fieldKey);
      } else {
        pinned[fieldKey] = value;
      }
      return repo.savePinned(projectId, pinned);
  }
}
