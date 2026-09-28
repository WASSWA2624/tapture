import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/normalise/search_text.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/presentation/template_locations.dart';

import '../domain/field_def.dart';
import '../domain/shipped_search_document.dart';
import '../domain/shipped_template_entry.dart';
import '../domain/shipped_template_ranking.dart';
import '../domain/template_def.dart';
import '../templates.dart' show shippedTemplateLoaderProvider;
import 'shipped_library_expanded.dart';
import 'shipped_library_filter.dart';
import 'shipped_suggestions_controller.dart';
import 'template_list_screen.dart';

/// Picker for the shipped library: areas and collapsible, counted
/// categories to browse (FBK0000161, D11), a search that ranks a name, a
/// code or a plain description of the work (D12), and filters; preview a
/// template's fields, then copy it into the project.
class ShippedPickerScreen extends ConsumerStatefulWidget {
  /// Creates the library picker.
  const ShippedPickerScreen({super.key});

  @override
  ConsumerState<ShippedPickerScreen> createState() =>
      _ShippedPickerScreenState();
}

class _ShippedPickerScreenState extends ConsumerState<ShippedPickerScreen> {
  final TextEditingController _name = TextEditingController();
  String _query = '';
  final Set<String> _picked = <String>{};
  bool _saving = false;

  /// The list [_documents] was built for, so a reload rebuilds it.
  List<ShippedTemplateEntry>? _indexed;

  /// Searchable words per template, in catalogue order.
  List<ShippedSearchDocument> _documents = const <ShippedSearchDocument>[];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ShippedTemplateEntry>> value = ref.watch(
      shippedLibraryProvider,
    );
    final _ShippedPickerView view = ref.watch(_shippedPickerProvider);
    final ShippedTemplateEntry? preview = _selected(
      value.asData?.value,
      view.previewKey,
    );
    if (preview != null && _name.text.isEmpty) {
      _name.text = preview.title;
    }
    return AppPage(
      key: const ValueKey<String>('route-template-library'),
      title: preview == null ? Copy.templatesLibraryTitle : preview.title,
      scrollable: false,
      footer: preview != null
          ? null
          : value.maybeWhen(
              data: (List<ShippedTemplateEntry> rows) {
                if (rows.isEmpty) {
                  return null;
                }
                return AppPrimaryAction(
                  label: Copy.save,
                  busy: _saving,
                  onPressed: _picked.isEmpty
                      ? null
                      : () => unawaited(_savePicked()),
                );
              },
              orElse: () => null,
            ),
      leading: preview == null
          ? null
          : AppIconButton(
              icon: AppIcons.back,
              semanticLabel: Copy.close,
              tooltip: Copy.close,
              outlined: false,
              onPressed: () {
                _name.clear();
                ref.read(_shippedPickerProvider.notifier).closePreview();
              },
            ),
      body: AsyncValueView<List<ShippedTemplateEntry>>(
        value: value,
        isEmpty: (List<ShippedTemplateEntry> rows) => rows.isEmpty,
        empty: _empty,
        onRetry: () => ref.invalidate(shippedLibraryProvider),
        data: (List<ShippedTemplateEntry> rows) {
          final Set<String> attached = <String>{
            for (final TemplateDef template
                in ref.watch(templateListProvider).asData?.value ??
                    const <TemplateDef>[])
              template.templateKey,
          };
          return preview == null
              ? _library(rows, attached)
              : _preview(preview, view, attached.contains(preview.templateKey));
        },
      ),
    );
  }

  void _togglePicked(ShippedTemplateEntry entry, bool picked) {
    if (picked) {
      // A category holding a ticked template stays open.
      ref
          .read(shippedLibraryExpandedProvider.notifier)
          .open(entry.category.code);
    }
    setState(() {
      if (picked) {
        _picked.add(entry.templateKey);
      } else {
        _picked.remove(entry.templateKey);
      }
    });
  }

  Future<void> _savePicked() async {
    if (_saving || _picked.isEmpty) {
      return;
    }
    final String? projectId =
        ref.read(currentProjectProvider) ??
        TemplateLocations.projectIdOf(context);
    if (projectId == null || projectId.isEmpty) {
      showAppSnack(context, Copy.statusNoProject, tone: SnackTone.error);
      return;
    }
    final Map<String, ShippedTemplateEntry> rows =
        <String, ShippedTemplateEntry>{
          for (final ShippedTemplateEntry entry
              in ref.read(shippedLibraryProvider).asData?.value ??
                  const <ShippedTemplateEntry>[])
            entry.templateKey: entry,
        };
    final List<String> keys = List<String>.of(_picked);
    setState(() => _saving = true);
    Failure? failure;
    for (final String key in keys) {
      final ShippedTemplateEntry? source = rows[key];
      if (source == null) {
        continue;
      }
      final Result<TemplateDef> result = await ref
          .read(shippedTemplateLoaderProvider)
          .copyToProject(
            templateKey: key,
            projectId: projectId,
            name: source.title,
          );
      if (result is FailureResult<TemplateDef>) {
        failure = result.failure;
        break;
      }
      _picked.remove(key);
    }
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (failure != null) {
      showAppSnack(context, failure.message, tone: SnackTone.error);
      return;
    }
    context.go(TemplateLocations.root(context));
  }

  Widget _library(List<ShippedTemplateEntry> rows, Set<String> attached) {
    final ShippedLibraryFilterState filter = ref.watch(
      shippedLibraryFilterProvider,
    );
    final bool searching = searchWords(_query).isNotEmpty;
    final Map<String, ShippedTemplateEntry> byKey =
        <String, ShippedTemplateEntry>{
          for (final ShippedTemplateEntry entry in rows)
            entry.templateKey: entry,
        };
    final List<ShippedTemplateEntry> shown = <ShippedTemplateEntry>[
      for (final String key in ShippedTemplateRanking.rank(
        _query,
        _searchIndex(rows),
      ))
        if (ShippedLibraryFilter.matches(byKey[key]!, filter)) byKey[key]!,
    ];
    final suggestion = ref.watch(shippedSuggestionsProvider);
    final bool hasSuggestion =
        suggestion.query == _query && suggestion.keys.isNotEmpty;
    if (hasSuggestion) {
      final Map<String, int> order = <String, int>{
        for (int index = 0; index < suggestion.keys.length; index++)
          suggestion.keys[index]: index,
      };
      final Map<String, int> original = <String, int>{
        for (int index = 0; index < shown.length; index++)
          shown[index].templateKey: index,
      };
      shown.sort(
        (ShippedTemplateEntry a, ShippedTemplateEntry b) =>
            (order[a.templateKey] ??
                    suggestion.keys.length + original[a.templateKey]!)
                .compareTo(
                  order[b.templateKey] ??
                      suggestion.keys.length + original[b.templateKey]!,
                ),
      );
    }
    final int active = ShippedLibraryFilter.activeCount(filter);
    final List<_Row> items = searching || active > 0
        ? <_Row>[
            for (final ShippedTemplateEntry entry in shown) _Template(entry),
          ]
        : _rows(shown, ref.watch(shippedLibraryExpandedProvider));
    final double gutter = AppPage.gutter(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x1, gutter, Space.x2),
          child: AppSearchField(
            hint: Copy.shippedLibrarySearchHint,
            text: _query,
            onChanged: (String value) => setState(() => _query = value),
            onFilter: () =>
                unawaited(showShippedLibraryFilters(context, ref, rows)),
            activeFilterCount: active,
            resultCount: !searching && active == 0 ? null : shown.length,
          ),
        ),
        if (searching &&
            shown.isNotEmpty &&
            ref.watch(shippedSuggestionServiceProvider) != null)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.x0, gutter, Space.x2),
            child: AppButton(
              label: Copy.shippedSuggestWithAi,
              variant: AppButtonVariant.secondary,
              busy: suggestion.busy,
              onPressed: () => unawaited(
                ref
                    .read(shippedSuggestionsProvider.notifier)
                    .suggest(_query, shown),
              ),
            ),
          ),
        if (hasSuggestion)
          AppListTile(
            title: Copy.shippedAiSuggestion,
            subtitle: Copy.shippedAiSuggestionHelp,
            trailing: AppIconButton(
              icon: AppIcons.close,
              semanticLabel: Copy.close,
              tooltip: Copy.close,
              onPressed: () =>
                  ref.read(shippedSuggestionsProvider.notifier).clear(),
            ),
            dense: true,
          ),
        if (suggestion.query == _query && suggestion.failure != null)
          AppListTile(
            title: suggestion.failure!.message,
            subtitle: suggestion.failure!.recoveryAction,
            dense: true,
          ),
        Expanded(
          child: shown.isEmpty
              ? AppEmptyState(
                  icon: AppIcons.searchEmpty,
                  headline: Copy.shippedLibraryNoMatch(_query),
                  message: Copy.shippedLibraryNoMatchMessage,
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (BuildContext _, int index) {
                    return switch (items[index]) {
                      _Heading(:final String title) => AppSectionHeader(
                        title: title,
                      ),
                      _Category(
                        :final String code,
                        :final String title,
                        :final bool expanded,
                      ) =>
                        AppSectionHeader(
                          key: ValueKey<String>('shipped-category-$code'),
                          title: title,
                          dense: true,
                          expanded: expanded,
                          onToggle: () => ref
                              .read(shippedLibraryExpandedProvider.notifier)
                              .toggle(code),
                        ),
                      _Template(:final ShippedTemplateEntry entry) =>
                        _libraryRow(entry, attached),
                    };
                  },
                ),
        ),
      ],
    );
  }

  /// Searchable words per template: its name, code, category, area, record
  /// type and kind, its own field labels, and how its record type is
  /// captured, assisted and output. Built once per loaded list.
  List<ShippedSearchDocument> _searchIndex(List<ShippedTemplateEntry> rows) {
    if (identical(rows, _indexed)) {
      return _documents;
    }
    _indexed = rows;
    _documents = <ShippedSearchDocument>[
      for (final ShippedTemplateEntry entry in rows)
        ShippedSearchDocument.of(
          entry,
          fieldLabels: <String>[
            for (final String key in entry.fieldKeys)
              Copy.shippedLabel('templates.$key'),
          ],
        ),
    ];
    return _documents;
  }

  Widget _libraryRow(ShippedTemplateEntry entry, Set<String> attached) {
    final bool isAttached = attached.contains(entry.templateKey);
    final bool picked = _picked.contains(entry.templateKey);
    return AppListTile(
      title: entry.title,
      subtitle: isAttached
          ? Copy.shippedAddedToProject
          : Copy.shippedCatalogueSubtitle(
              entry.code,
              entry.recordType.title,
              entry.fieldCount,
            ),
      selected: picked,
      trailing: isAttached
          ? const Icon(AppIcons.success)
          : Checkbox(
              value: picked,
              onChanged: (bool? value) => _togglePicked(entry, value ?? false),
            ),
      onTap: () =>
          ref.read(_shippedPickerProvider.notifier).preview(entry.templateKey),
      onLongPress: isAttached ? null : () => _togglePicked(entry, !picked),
    );
  }

  Widget _preview(
    ShippedTemplateEntry entry,
    _ShippedPickerView view,
    bool attached,
  ) {
    final AsyncValue<TemplateDef> template = ref.watch(
      shippedTemplateProvider(entry.templateKey),
    );
    return AppForm(
      guardUnsaved: true,
      errors: view.saveError == null
          ? const <String>[]
          : <String>[view.saveError!],
      fields: <Widget>[
        AppTextField(
          label: Copy.projectName,
          controller: _name,
          requiredness: FieldRequiredness.required,
          textInputAction: TextInputAction.done,
          errorText: view.nameError,
        ),
        if (attached)
          const AppListTile(
            title: Copy.shippedAddedToProject,
            leading: Icon(AppIcons.success),
            dense: true,
          ),
        ..._about(entry),
        ...template.when(
          data: _fieldRows,
          loading: () => const <Widget>[AppSkeleton()],
          error: (Object error, StackTrace _) => <Widget>[
            AppListTile(
              title: Failure.from(error).message,
              leading: const Icon(AppIcons.error),
              dense: true,
            ),
          ],
        ),
      ],
      submitLabel: attached
          ? Copy.templatesCustomCopy
          : Copy.templatesAddToProject,
      onSubmit: () async {
        final GoRouter? router = GoRouter.maybeOf(context);
        final TemplateDef? created = await ref
            .read(_shippedPickerProvider.notifier)
            .add(name: _name.text, templateKey: entry.templateKey);
        if (created == null) {
          return false;
        }
        if (router == null || !mounted) {
          return true;
        }
        router.go(TemplateLocations.detail(context, created.id));
        return true;
      },
    );
  }
}

/// What a template is: its category, record type, suggested privacy and
/// tier, and how its record type is captured, assisted, output and reviewed.
List<Widget> _about(ShippedTemplateEntry entry) {
  final ShippedRecordType type = entry.recordType;
  return <Widget>[
    AppListTile(
      title: Copy.shippedCategoryLabel,
      subtitle: '${entry.code} · ${entry.category.title}',
      dense: true,
    ),
    AppListTile(
      title: Copy.shippedRecordTypeLabel,
      subtitle: type.title,
      dense: true,
    ),
    AppListTile(
      title: Copy.shippedPrivacyTierLabel,
      subtitle: Copy.shippedPrivacyTier(entry.privacy, entry.rollout),
      dense: true,
    ),
    for (final (String label, String text) in <(String, String)>[
      (Copy.shippedCaptureLabel, type.capture),
      (Copy.shippedAiAssistanceLabel, type.aiAssistance),
      (Copy.shippedOutputsLabel, type.outputs),
      (Copy.shippedReviewLabel, type.review),
    ])
      if (text.isNotEmpty)
        AppListTile(title: label, subtitle: text, dense: true),
  ];
}

/// [template]'s resolved fields under a heading per group, in stored order,
/// each with its type and suggested requiredness.
List<Widget> _fieldRows(TemplateDef template) {
  final List<Widget> rows = <Widget>[];
  String? group;
  for (final FieldDef field in template.fields) {
    if (field.group != null && field.group != group) {
      group = field.group;
      rows.add(
        AppSectionHeader(title: Copy.requiredColumnGroup(group!), dense: true),
      );
    }
    rows.add(
      AppListTile(
        title: Copy.shippedLabel(field.label),
        subtitle: Copy.shippedFieldSubtitle(
          field.type.name,
          _requiredness(field.requiredness),
        ),
        dense: true,
      ),
    );
  }
  return rows;
}

String _requiredness(Requiredness requiredness) {
  return switch (requiredness) {
    Requiredness.required => Copy.fieldRequired,
    Requiredness.recommended => Copy.fieldRecommended,
    Requiredness.optional => Copy.fieldOptional,
  };
}

/// One line of the library list: an area heading, a category that opens and
/// closes, or a template.
sealed class _Row {
  const _Row();
}

final class _Heading extends _Row {
  const _Heading(this.title);

  final String title;
}

final class _Category extends _Row {
  const _Category(this.code, this.title, {required this.expanded});

  final String code;
  final String title;
  final bool expanded;
}

final class _Template extends _Row {
  const _Template(this.entry);

  final ShippedTemplateEntry entry;
}

/// [shown] as list lines, in catalogue order: each area's heading, then its
/// categories with their counts, each listing its templates only while it
/// is in [expanded]. The list stays lazy (FE-PERF-03).
List<_Row> _rows(List<ShippedTemplateEntry> shown, Set<String> expanded) {
  final Map<String, int> counts = <String, int>{};
  for (final ShippedTemplateEntry entry in shown) {
    counts.update(entry.category.code, (int n) => n + 1, ifAbsent: () => 1);
  }
  final List<_Row> rows = <_Row>[];
  String? area;
  String? section;
  for (final ShippedTemplateEntry entry in shown) {
    final ShippedCatalogueCategory category = entry.category;
    if (category.supergroupCode != area) {
      area = category.supergroupCode;
      section = null;
      rows.add(
        _Heading(
          Copy.shippedAreaTitle(
            category.supergroupCode,
            category.supergroupTitle,
          ),
        ),
      );
    }
    final bool open = expanded.contains(category.code);
    if (category.code != section) {
      section = category.code;
      rows.add(
        _Category(
          category.code,
          Copy.shippedCategoryHeading(
            category.code,
            category.title,
            counts[category.code]!,
          ),
          expanded: open,
        ),
      );
    }
    if (open) {
      rows.add(_Template(entry));
    }
  }
  return rows;
}

Widget _empty() {
  return const AppEmptyState(
    icon: AppIcons.template,
    headline: Copy.templatesLibraryEmptyHeadline,
    message: Copy.templatesLibraryEmptyMessage,
  );
}

ShippedTemplateEntry? _selected(List<ShippedTemplateEntry>? rows, String? key) {
  if (rows == null || key == null) {
    return null;
  }
  for (final ShippedTemplateEntry row in rows) {
    if (row.templateKey == key) {
      return row;
    }
  }
  return null;
}

/// Live shipped library: every shipped template as a light
/// row. The picker is the only reader.
final FutureProvider<List<ShippedTemplateEntry>> shippedLibraryProvider =
    FutureProvider<List<ShippedTemplateEntry>>((Ref ref) async {
      final Result<List<ShippedTemplateEntry>> result = await ref
          .watch(shippedTemplateLoaderProvider)
          .entries();
      return switch (result) {
        Success<List<ShippedTemplateEntry>>(
          :final List<ShippedTemplateEntry> value,
        ) =>
          value,
        FailureResult<List<ShippedTemplateEntry>>(:final Failure failure) =>
          throw failure,
      };
    });

/// One shipped template with its fields resolved, for the preview.
final shippedTemplateProvider = FutureProvider.family<TemplateDef, String>((
  Ref ref,
  String templateKey,
) async {
  final Result<TemplateDef> result = await ref
      .watch(shippedTemplateLoaderProvider)
      .template(templateKey);
  return switch (result) {
    Success<TemplateDef>(:final TemplateDef value) => value,
    FailureResult<TemplateDef>(:final Failure failure) => throw failure,
  };
}, retry: (int _, Object _) => null);

final NotifierProvider<_ShippedPicker, _ShippedPickerView>
_shippedPickerProvider = NotifierProvider<_ShippedPicker, _ShippedPickerView>(
  _ShippedPicker.new,
  retry: (int _, Object _) => null,
);

typedef _ShippedPickerView = ({
  String? previewKey,
  String? nameError,
  String? saveError,
});

class _ShippedPicker extends Notifier<_ShippedPickerView> {
  @override
  _ShippedPickerView build() {
    return (previewKey: null, nameError: null, saveError: null);
  }

  /// Opens the resolved field list for [templateKey].
  void preview(String templateKey) {
    state = (previewKey: templateKey, nameError: null, saveError: null);
  }

  /// Returns to the library list.
  void closePreview() {
    state = (previewKey: null, nameError: null, saveError: null);
  }

  /// Copies [templateKey] into the open project under [name].
  Future<TemplateDef?> add({
    required String name,
    required String templateKey,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = (
        previewKey: state.previewKey,
        nameError: Copy.nameRequired,
        saveError: null,
      );
      return null;
    }
    final String? projectId = ref.read(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      state = (
        previewKey: state.previewKey,
        nameError: null,
        saveError: Copy.statusNoProject,
      );
      return null;
    }
    final Result<TemplateDef> result = await ref
        .read(shippedTemplateLoaderProvider)
        .copyToProject(
          templateKey: templateKey,
          projectId: projectId,
          name: trimmed,
        );
    switch (result) {
      case Success<TemplateDef>(:final TemplateDef value):
        state = (previewKey: null, nameError: null, saveError: null);
        return value;
      case FailureResult<TemplateDef>(:final Failure failure):
        state = (
          previewKey: state.previewKey,
          nameError: null,
          saveError: failure.message,
        );
        return null;
    }
  }
}

/// Must match [AppRoutes.template]. This file cannot import `router.dart`.
