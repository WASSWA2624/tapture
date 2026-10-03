import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/template_def.dart';
import '../domain/template_row.dart';
import '../templates.dart' show PredefinedRowsImport;
import 'template_list_screen.dart' show templateListProvider;
import 'template_locations.dart';

/// Capture checklist grouped by context, with found versus missing.
class ChecklistScreen extends ConsumerWidget {
  /// Creates the checklist for [templateId].
  const ChecklistScreen({super.key, required this.templateId});

  /// Template whose predefined rows this screen lists.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<TemplateDef?> value = ref
        .watch(templateListProvider)
        .whenData(_pick);
    final TemplateDef? template = value.asData?.value;
    return AppPage(
      key: const ValueKey<String>('route-checklist'),
      title: localCopy.checklistTitle,
      scrollable: false,
      inset: false,
      overflow: template == null
          ? const <AppOverflowAction>[]
          : <AppOverflowAction>[
              AppOverflowAction(
                label: localCopy.checklistImportRows,
                icon: AppIcons.import,
                onTap: () => context.go(_importRows(context, template.id)),
              ),
            ],
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) => row == null || row.rows.isEmpty,
        empty: () => AppEmptyState(
          icon: AppIcons.checklist,
          headline: template == null
              ? Copy.of(context).templatesEmptyHeadline
              : Copy.of(context).checklistEmptyHeadline,
          message: template == null
              ? Copy.of(context).templatesEmptyMessage
              : Copy.of(context).checklistEmptyMessage,
          actionLabel: template == null
              ? Copy.of(context).navTemplates
              : Copy.of(context).checklistImportRows,
          onAction: () => context.go(
            template == null
                ? TemplateLocations.root(context)
                : _importRows(context, template.id),
          ),
        ),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (TemplateDef? row) => _list(context, ref, row!),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, TemplateDef template) {
    final List<_ChecklistLine> lines = _linesOf(
      template.rows,
      localizedCopy: Copy.of(context),
    );
    return ListView.builder(
      itemCount: lines.length,
      itemBuilder: (BuildContext context, int index) {
        final LocalizedCopy localCopy = Copy.of(context);

        final _ChecklistLine line = lines[index];
        return switch (line) {
          _ChecklistGroup(
            :final String name,
            :final int found,
            :final int total,
          ) =>
            AppSectionHeader(
              key: ValueKey<String>('checklist-group-$name'),
              title: localCopy.checklistProgress(
                group: name,
                found: found,
                total: total,
              ),
              dense: true,
            ),
          _ChecklistRow(:final TemplateRow row) => AppListTile(
            key: ValueKey<String>('checklist-${row.identifier}'),
            title: row.label,
            status: _pill(row, localizedCopy: Copy.of(context)),
            onTap: () => _openCapture(context, ref, row),
          ),
        };
      },
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

  void _openCapture(BuildContext context, WidgetRef ref, TemplateRow row) {
    final String? projectId = ref.read(currentProjectProvider);
    final String location = projectId == null || projectId.isEmpty
        ? _captureTab(templateId: templateId, rowId: row.identifier)
        : _capture(
            projectId: projectId,
            templateId: templateId,
            rowId: row.identifier,
          );
    context.go(location);
  }
}

String _importRows(BuildContext context, String templateId) => Uri(
  path: RoutePaths.templateXlsx(
    projectId: TemplateLocations.projectIdOf(context),
  ),
  queryParameters: <String, String>{'template': templateId},
).toString();

sealed class _ChecklistLine {
  const _ChecklistLine();
}

final class _ChecklistGroup extends _ChecklistLine {
  const _ChecklistGroup(this.name, {required this.found, required this.total});

  final String name;
  final int found;
  final int total;
}

final class _ChecklistRow extends _ChecklistLine {
  const _ChecklistRow(this.row);

  final TemplateRow row;
}

List<_ChecklistLine> _linesOf(
  List<TemplateRow> rows, {
  LocalizedCopy? localizedCopy,
}) {
  final Map<String, List<TemplateRow>> groups = <String, List<TemplateRow>>{};
  final List<String> order = <String>[];
  for (final TemplateRow row in rows) {
    final String name =
        PredefinedRowsImport.contextOf(row) ??
        (localizedCopy ?? Copy.english).checklistUngrouped;
    final List<TemplateRow>? existing = groups[name];
    if (existing == null) {
      order.add(name);
      groups[name] = <TemplateRow>[row];
    } else {
      existing.add(row);
    }
  }
  return <_ChecklistLine>[
    for (final String name in order) ...<_ChecklistLine>[
      _ChecklistGroup(
        name,
        found: groups[name]!.where(_isFound).length,
        total: groups[name]!.length,
      ),
      for (final TemplateRow row in groups[name]!) _ChecklistRow(row),
    ],
  ];
}

AppStatusPill _pill(TemplateRow row, {LocalizedCopy? localizedCopy}) {
  final bool found = _isFound(row);
  return AppStatusPill.badge(
    status: found ? RecordStatus.approved : RecordStatus.needsReview,
    label: found
        ? (localizedCopy ?? Copy.english).checklistFound
        : (localizedCopy ?? Copy.english).checklistMissing,
  );
}

bool _isFound(TemplateRow row) => row.foundStatus == _foundStatus;

/// Must match [AppRoutes.capture] with template and row query keys.
String _capture({
  required String projectId,
  required String templateId,
  required String rowId,
}) {
  return Uri(
    path: '$_projectsRoot/${Uri.encodeComponent(projectId)}/$_captureSegment',
    queryParameters: <String, String>{
      _templateQuery: templateId,
      _rowQuery: rowId,
    },
  ).toString();
}

/// Must match the capture-tab path with the same query keys.
String _captureTab({required String templateId, required String rowId}) {
  return Uri(
    path: _captureTabPath,
    queryParameters: <String, String>{
      _templateQuery: templateId,
      _rowQuery: rowId,
    },
  ).toString();
}

const String _projectsRoot = '/projects';
const String _captureSegment = 'capture';
const String _captureTabPath = '/capture';
const String _templateQuery = 'template';
const String _rowQuery = 'row';
const String _foundStatus = 'found';
