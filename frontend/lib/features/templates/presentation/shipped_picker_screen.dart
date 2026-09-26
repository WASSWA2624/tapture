import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
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
import '../domain/shipped_template_category.dart';
import '../domain/shipped_template_entry.dart';
import '../domain/template_def.dart';
import '../templates.dart' show shippedTemplateLoaderProvider;
import 'shipped_library_filter.dart';
import 'template_list_screen.dart';

/// Picker for the shipped library: the starter templates of §13.4 and the
/// full catalogue, grouped by area and category, searchable and filterable;
/// preview a template's fields, then copy it into the project.
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

  /// The list [_search] was built for, so a reload rebuilds it.
  List<ShippedTemplateEntry>? _indexed;

  /// Lower-case text search matches against, keyed by template key.
  Map<String, String> _search = const <String, String>{};

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
      _name.text = shippedEntryName(preview);
    }
    return AppPage(
      key: const ValueKey<String>('route-template-library'),
      title: preview == null
          ? Copy.templatesLibraryTitle
          : shippedEntryName(preview),
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

  void _togglePicked(String templateKey, bool picked) {
    setState(() {
      if (picked) {
        _picked.add(templateKey);
      } else {
        _picked.remove(templateKey);
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
            name: shippedEntryName(source),
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
    final Map<String, String> search = _searchIndex(rows);
    final List<String> terms = <String>[
      for (final String term in _query.toLowerCase().split(_whitespace))
        if (term.isNotEmpty) term,
    ];
    final List<ShippedTemplateEntry> shown = <ShippedTemplateEntry>[
      for (final ShippedTemplateEntry entry in rows)
        if (ShippedLibraryFilter.matches(entry, filter) &&
            terms.every(search[entry.templateKey]!.contains))
          entry,
    ];
    final List<_Row> items = _rows(shown);
    final int active = ShippedLibraryFilter.activeCount(filter);
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
            resultCount: terms.isEmpty && active == 0 ? null : shown.length,
          ),
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
                      _Heading(:final String title, :final bool dense) =>
                        AppSectionHeader(title: title, dense: dense),
                      _Template(:final ShippedTemplateEntry entry) =>
                        _libraryRow(entry, attached),
                    };
                  },
                ),
        ),
      ],
    );
  }

  /// Search text per template: its name, code, category, area, record type,
  /// kind and its own field labels, built once per loaded list.
  Map<String, String> _searchIndex(List<ShippedTemplateEntry> rows) {
    if (identical(rows, _indexed)) {
      return _search;
    }
    _indexed = rows;
    _search = <String, String>{
      for (final ShippedTemplateEntry entry in rows)
        entry.templateKey: _searchText(entry),
    };
    return _search;
  }

  Widget _libraryRow(ShippedTemplateEntry entry, Set<String> attached) {
    final bool isAttached = attached.contains(entry.templateKey);
    final bool picked = _picked.contains(entry.templateKey);
    final String? code = entry.code;
    return AppListTile(
      title: shippedEntryName(entry),
      subtitle: isAttached
          ? Copy.shippedAddedToProject
          : code == null
          ? Copy.fieldsCount(entry.fieldCount)
          : Copy.shippedCatalogueSubtitle(
              code,
              entry.recordType?.title ?? entry.kind,
              entry.fieldCount,
            ),
      selected: picked,
      trailing: isAttached
          ? const Icon(AppIcons.success)
          : Checkbox(
              value: picked,
              onChanged: (bool? value) =>
                  _togglePicked(entry.templateKey, value ?? false),
            ),
      onTap: () =>
          ref.read(_shippedPickerProvider.notifier).preview(entry.templateKey),
      onLongPress: isAttached
          ? null
          : () => _togglePicked(entry.templateKey, !picked),
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
        if (created == null || router == null || !mounted) {
          return;
        }
        router.go(TemplateLocations.detail(context, created.id));
      },
    );
  }
}

/// What a catalogue template is: its category, record type, suggested
/// privacy and tier, and how its record type is captured, assisted, output
/// and reviewed. A starter template shows none of this.
List<Widget> _about(ShippedTemplateEntry entry) {
  final ShippedCatalogueCategory? category = entry.category;
  final ShippedRecordType? type = entry.recordType;
  final String? code = entry.code;
  if (category == null || code == null) {
    return const <Widget>[];
  }
  return <Widget>[
    AppListTile(
      title: Copy.shippedCategoryLabel,
      subtitle: '$code · ${category.title}',
      dense: true,
    ),
    if (type != null)
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
    if (type != null)
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

/// The operator-facing name of [entry]: the catalogue's title, or the copy
/// helper's name for a starter template.
String shippedEntryName(ShippedTemplateEntry entry) {
  return entry.title ?? Copy.shippedTemplateName(entry.templateKey);
}

String _searchText(ShippedTemplateEntry entry) {
  final ShippedCatalogueCategory? category = entry.category;
  return <String>[
    shippedEntryName(entry),
    entry.templateKey,
    entry.kind,
    ?entry.code,
    if (category == null)
      Copy.shippedCategoryTitle(entry.starterCategory.name)
    else ...<String>[category.code, category.title, category.supergroupTitle],
    ?entry.recordType?.title,
    for (final String key in entry.fieldKeys)
      Copy.shippedLabel('templates.$key'),
  ].join('\n').toLowerCase();
}

/// One line of the library list: a heading or a template.
sealed class _Row {
  const _Row();
}

final class _Heading extends _Row {
  const _Heading(this.title, {required this.dense});

  final String title;
  final bool dense;
}

final class _Template extends _Row {
  const _Template(this.entry);

  final ShippedTemplateEntry entry;
}

/// [shown] as list lines. Starter templates come first, in their group
/// order; the catalogue follows in catalogue order. Area headings appear
/// only once catalogue templates are listed, so the starter library alone
/// reads as it always has.
List<_Row> _rows(List<ShippedTemplateEntry> shown) {
  final List<ShippedTemplateEntry> starters = <ShippedTemplateEntry>[
    for (final ShippedTemplateEntry entry in shown)
      if (entry.isStarter) entry,
  ]..sort(_byCategory);
  final List<ShippedTemplateEntry> ordered = <ShippedTemplateEntry>[
    ...starters,
    for (final ShippedTemplateEntry entry in shown)
      if (!entry.isStarter) entry,
  ];
  final bool withAreas = ordered.length > starters.length;
  final List<_Row> rows = <_Row>[];
  String? area;
  String? section;
  for (final ShippedTemplateEntry entry in ordered) {
    final ShippedCatalogueCategory? category = entry.category;
    final String areaKey = ShippedLibraryFilter.areaOf(entry);
    if (withAreas && areaKey != area) {
      area = areaKey;
      section = null;
      rows.add(
        _Heading(
          category == null
              ? Copy.shippedStarterArea
              : Copy.shippedAreaTitle(
                  category.supergroupCode,
                  category.supergroupTitle,
                ),
          dense: false,
        ),
      );
    }
    final String sectionKey = category == null
        ? 'starter.${entry.starterCategory.name}'
        : category.code;
    if (sectionKey != section) {
      section = sectionKey;
      rows.add(
        _Heading(
          category == null
              ? Copy.shippedCategoryTitle(entry.starterCategory.name)
              : Copy.shippedCatalogueCategoryTitle(
                  category.code,
                  category.title,
                ),
          dense: true,
        ),
      );
    }
    rows.add(_Template(entry));
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

/// Starter order: group order first, then the order inside the group, then
/// the name for keys the grouping does not list.
int _byCategory(ShippedTemplateEntry a, ShippedTemplateEntry b) {
  final int group = ShippedTemplateCategory.of(
    a.templateKey,
  ).index.compareTo(ShippedTemplateCategory.of(b.templateKey).index);
  if (group != 0) {
    return group;
  }
  final int order = ShippedTemplateCategory.orderOf(
    a.templateKey,
  ).compareTo(ShippedTemplateCategory.orderOf(b.templateKey));
  if (order != 0) {
    return order;
  }
  return shippedEntryName(a).compareTo(shippedEntryName(b));
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

final RegExp _whitespace = RegExp(r'\s+');

/// Live shipped library: every starter and catalogue template as a light
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
