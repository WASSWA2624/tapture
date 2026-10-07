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
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/templates/presentation/template_locations.dart';

import '../domain/field_def.dart';
import '../domain/shipped_search_document.dart';
import '../domain/shipped_template_entry.dart';
import '../domain/shipped_template_ranking.dart';
import '../domain/template_def.dart';
import '../templates.dart'
    show shippedTemplateLoaderProvider, templateRepositoryProvider;
import 'shipped_library_expanded.dart';
import 'shipped_library_filter.dart';
import 'shipped_suggestions_controller.dart';
import 'template_actions.dart';
import 'template_duplicate_action.dart';
import 'template_editor_source.dart';
import 'template_list_screen.dart';

/// Picker for the shipped library: areas and collapsible, counted
/// categories to browse (FBK0000161, D11), a search that ranks a name, a
/// code or a plain description of the work (D12), and filters; preview a
/// template's fields, then copy it into the project.
class ShippedPickerScreen extends ConsumerStatefulWidget {
  /// Creates the library picker.
  const ShippedPickerScreen({this.projectId, this.root = false, super.key});

  /// Null browses and customizes the global library; otherwise attaches copies.
  final String? projectId;

  /// The global Templates branch already provides its page header.
  final bool root;

  @override
  ConsumerState<ShippedPickerScreen> createState() =>
      _ShippedPickerScreenState();
}

class _ShippedPickerScreenState extends ConsumerState<ShippedPickerScreen>
    with StateRefresh {
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
    final LocalizedCopy localCopy = Copy.of(context);

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
      key: ValueKey<String>(
        widget.root ? 'route-templates' : 'route-template-library',
      ),
      title: preview == null ? localCopy.navTemplates : preview.title,
      showAppBar: !widget.root || preview != null,
      scrollable: false,
      footer: preview != null
          ? null
          : widget.projectId == null
          ? AppPrimaryAction(
              label: localCopy.templatesCreate,
              onPressed: () => context.go(TemplateLocations.create(context)),
            )
          : value.maybeWhen(
              data: (List<ShippedTemplateEntry> rows) {
                final LocalizedCopy localCopy = Copy.of(context);

                if (rows.isEmpty) {
                  return null;
                }
                return AppPrimaryAction(
                  label: localCopy.save,
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
              semanticLabel: localCopy.close,
              tooltip: localCopy.close,
              outlined: false,
              onPressed: () {
                _name.clear();
                ref.read(_shippedPickerProvider.notifier).closePreview();
              },
            ),
      body: AsyncValueView<List<TemplateDef>>(
        value: ref.watch(templateLibraryProvider),
        isEmpty: (List<TemplateDef> _) => false,
        onRetry: () => ref.invalidate(templateLibraryProvider),
        data: (List<TemplateDef> library) =>
            AsyncValueView<List<ShippedTemplateEntry>>(
              value: value,
              isEmpty: (List<ShippedTemplateEntry> rows) =>
                  rows.isEmpty && library.isEmpty,
              empty: () => _empty(context),
              onRetry: () => ref.invalidate(shippedLibraryProvider),
              data: (List<ShippedTemplateEntry> rows) {
                final Set<String> attached = <String>{
                  for (final TemplateDef template
                      in (widget.projectId == null
                              ? const <TemplateDef>[]
                              : ref
                                    .watch(
                                      templateProjectListProvider(
                                        widget.projectId!,
                                      ),
                                    )
                                    .asData
                                    ?.value) ??
                          const <TemplateDef>[])
                    template.templateKey,
                };
                return preview == null
                    ? _library(rows, attached, library)
                    : _preview(
                        preview,
                        view,
                        attached.contains(preview.templateKey),
                      );
              },
            ),
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
    refresh(() {
      if (picked) {
        _picked.add(entry.templateKey);
      } else {
        _picked.remove(entry.templateKey);
      }
    });
  }

  Future<void> _savePicked() async {
    final LocalizedCopy localCopy = Copy.of(context);

    if (_saving || _picked.isEmpty) {
      return;
    }
    final String? projectId = widget.projectId;
    if (projectId == null || projectId.isEmpty) {
      showAppSnack(context, localCopy.statusNoProject, tone: SnackTone.error);
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
    refresh(() => _saving = true);
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
    refresh(() => _saving = false);
    if (failure != null) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
      return;
    }
    context.go(TemplateLocations.root(context));
  }

  Widget _library(
    List<ShippedTemplateEntry> rows,
    Set<String> attached,
    List<TemplateDef> library,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

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
    final List<_Row> shipped = searching || active > 0
        ? <_Row>[
            for (final ShippedTemplateEntry entry in shown) _Template(entry),
          ]
        : _rows(
            shown,
            ref.watch(shippedLibraryExpandedProvider),
            localizedCopy: Copy.of(context),
          );
    final String query = _query.trim().toLowerCase();
    final List<TemplateDef> saved = <TemplateDef>[
      if (active == 0)
        for (final TemplateDef template in library)
          if (query.isEmpty || template.name.toLowerCase().contains(query))
            template,
    ];
    final List<_Row> items = <_Row>[
      if (saved.isNotEmpty) _Heading(localCopy.templatesMyTemplates),
      for (final TemplateDef template in saved) _Saved(template),
      if (shipped.isNotEmpty) _Heading(localCopy.templatesLibraryTitle),
      ...shipped,
    ];
    final double gutter = AppPage.gutter(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x1, gutter, Space.x2),
          child: AppSearchField(
            hint: localCopy.shippedLibrarySearchHint,
            text: _query,
            onChanged: (String value) => refresh(() => _query = value),
            onFilter: () =>
                unawaited(showShippedLibraryFilters(context, ref, rows)),
            activeFilterCount: active,
            resultCount: !searching && active == 0
                ? null
                : shown.length + saved.length,
          ),
        ),
        if (searching &&
            shown.isNotEmpty &&
            ref.watch(shippedSuggestionServiceProvider) != null)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.x0, gutter, Space.x2),
            child: AppButton(
              label: localCopy.shippedSuggestWithAi,
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
            title: localCopy.shippedAiSuggestion,
            subtitle: localCopy.shippedAiSuggestionHelp,
            trailing: AppIconButton(
              icon: AppIcons.close,
              semanticLabel: localCopy.close,
              tooltip: localCopy.close,
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
          child: items.isEmpty
              ? AppEmptyState(
                  icon: AppIcons.searchEmpty,
                  headline: localCopy.shippedLibraryNoMatch(_query),
                  message: localCopy.shippedLibraryNoMatchMessage,
                  actionLabel: localCopy.searchClearFilters,
                  onAction: () {
                    refresh(() => _query = '');
                    ref.read(shippedLibraryFilterProvider.notifier).clear();
                    ref.read(shippedSuggestionsProvider.notifier).clear();
                  },
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
                      _Saved(:final TemplateDef template) => AppListTile(
                        key: ValueKey<String>(
                          'library-template-${template.id}',
                        ),
                        title: template.name,
                        subtitle: localCopy.fieldsCount(template.fields.length),
                        trailing: widget.projectId == null
                            ? AppOverflowMenu(
                                items: TemplateActions.items(
                                  context,
                                  ref,
                                  template,
                                  0,
                                ),
                              )
                            : null,
                        onTap: widget.projectId == null
                            ? () => TemplateActions.open(context, template.id)
                            : () => unawaited(_attachSaved(template)),
                      ),
                    };
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _attachSaved(TemplateDef source) async {
    final String? owner = widget.projectId;
    if (owner == null || _saving) return;
    refresh(() => _saving = true);
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(
          TemplateDuplicateAction.draftFrom(
            source,
          ).copyWith(projectId: owner, name: source.name),
        );
    if (!mounted) return;
    refresh(() => _saving = false);
    switch (result) {
      case Success<TemplateDef>(:final value):
        context.go(
          TemplateLocations.detail(context, value.id, projectId: owner),
        );
      case FailureResult<TemplateDef>(:final failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
    }
  }

  /// Searchable words per template: its name, code, category, area, record
  /// type and kind, its own field labels, and how its record type is
  /// captured, assisted and output. Built once per loaded list.
  List<ShippedSearchDocument> _searchIndex(List<ShippedTemplateEntry> rows) {
    final LocalizedCopy localCopy = Copy.of(context);

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
              localCopy.shippedLabel('templates.$key'),
          ],
        ),
    ];
    return _documents;
  }

  Widget _libraryRow(ShippedTemplateEntry entry, Set<String> attached) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool isAttached = attached.contains(entry.templateKey);
    final bool picked = _picked.contains(entry.templateKey);
    return AppListTile(
      title: entry.title,
      subtitle: isAttached
          ? localCopy.shippedAddedToProject
          : localCopy.shippedCatalogueSubtitle(
              entry.code,
              entry.recordType.title,
              entry.fieldCount,
            ),
      selected: picked,
      trailing: widget.projectId == null
          ? null
          : isAttached
          ? const Icon(AppIcons.success)
          : Checkbox(
              value: picked,
              onChanged: (bool? value) => _togglePicked(entry, value ?? false),
            ),
      onTap: () {
        _name.text = entry.title;
        ref.read(_shippedPickerProvider.notifier).preview(entry.templateKey);
      },
      onLongPress: widget.projectId == null || isAttached
          ? null
          : () => _togglePicked(entry, !picked),
    );
  }

  Widget _preview(
    ShippedTemplateEntry entry,
    _ShippedPickerView view,
    bool attached,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<TemplateDef> template = ref.watch(
      shippedTemplateProvider(entry.templateKey),
    );
    return AppForm(
      guardUnsaved: true,
      errors:
          Copy.of(context).stateText(view.localizedSaveError, view.saveError) ==
              null
          ? const <String>[]
          : <String>[
              Copy.of(
                context,
              ).stateText(view.localizedSaveError, view.saveError)!,
            ],
      fields: <Widget>[
        AppTextField(
          label: localCopy.projectName,
          controller: _name,
          requiredness: FieldRequiredness.required,
          textInputAction: TextInputAction.done,
          errorText: Copy.of(
            context,
          ).stateText(view.localizedNameError, view.nameError),
        ),
        if (attached)
          AppListTile(
            title: localCopy.shippedAddedToProject,
            leading: const Icon(AppIcons.success),
            dense: true,
          ),
        ..._about(entry, localizedCopy: Copy.of(context)),
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
      submitLabel: widget.projectId == null
          ? localCopy.templatesCustomizeCopy
          : attached
          ? localCopy.templatesCustomCopy
          : localCopy.templatesAddToProject,
      onSubmit: () async {
        final GoRouter? router = GoRouter.maybeOf(context);
        final TemplateDef? created = await ref
            .read(_shippedPickerProvider.notifier)
            .add(
              name: _name.text,
              templateKey: entry.templateKey,
              projectId: widget.projectId,
            );
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
List<Widget> _about(
  ShippedTemplateEntry entry, {
  LocalizedCopy? localizedCopy,
}) {
  final ShippedRecordType type = entry.recordType;
  return <Widget>[
    AppListTile(
      title: (localizedCopy ?? Copy.english).shippedCategoryLabel,
      subtitle: '${entry.code} · ${entry.category.title}',
      dense: true,
    ),
    AppListTile(
      title: (localizedCopy ?? Copy.english).shippedRecordTypeLabel,
      subtitle: type.title,
      dense: true,
    ),
    AppListTile(
      title: (localizedCopy ?? Copy.english).shippedPrivacyTierLabel,
      subtitle: (localizedCopy ?? Copy.english).shippedPrivacyTier(
        entry.privacy,
        entry.rollout,
      ),
      dense: true,
    ),
    for (final (String label, String text) in <(String, String)>[
      ((localizedCopy ?? Copy.english).shippedCaptureLabel, type.capture),
      (
        (localizedCopy ?? Copy.english).shippedAiAssistanceLabel,
        type.aiAssistance,
      ),
      ((localizedCopy ?? Copy.english).shippedOutputsLabel, type.outputs),
      ((localizedCopy ?? Copy.english).shippedReviewLabel, type.review),
    ])
      if (text.isNotEmpty)
        AppListTile(title: label, subtitle: text, dense: true),
  ];
}

/// [template]'s resolved fields under a heading per group, in stored order,
/// each with its type and suggested requiredness.
List<Widget> _fieldRows(TemplateDef template, {LocalizedCopy? localizedCopy}) {
  final List<Widget> rows = <Widget>[];
  String? group;
  for (final FieldDef field in template.fields) {
    if (field.group != null && field.group != group) {
      group = field.group;
      rows.add(
        AppSectionHeader(
          title: (localizedCopy ?? Copy.english).requiredColumnGroup(group!),
          dense: true,
        ),
      );
    }
    rows.add(
      AppListTile(
        title: (localizedCopy ?? Copy.english).shippedLabel(field.label),
        subtitle: (localizedCopy ?? Copy.english).shippedFieldSubtitle(
          field.type.name,
          _requiredness(field.requiredness, localizedCopy: localizedCopy),
        ),
        dense: true,
      ),
    );
  }
  return rows;
}

String _requiredness(
  Requiredness requiredness, {
  LocalizedCopy? localizedCopy,
}) {
  return switch (requiredness) {
    Requiredness.required => (localizedCopy ?? Copy.english).fieldRequired,
    Requiredness.recommended =>
      (localizedCopy ?? Copy.english).fieldRecommended,
    Requiredness.optional => (localizedCopy ?? Copy.english).fieldOptional,
  };
}

/// One line of the library list: an area heading, a category that opens and
/// closes, or a template.
sealed class _Row {
  const _Row();
}

final class _Saved extends _Row {
  const _Saved(this.template);
  final TemplateDef template;
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
List<_Row> _rows(
  List<ShippedTemplateEntry> shown,
  Set<String> expanded, {
  LocalizedCopy? localizedCopy,
}) {
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
          (localizedCopy ?? Copy.english).shippedAreaTitle(
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
          (localizedCopy ?? Copy.english).shippedCategoryHeading(
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

Widget _empty(BuildContext context) {
  final LocalizedCopy localCopy = Copy.of(context);

  return AppEmptyState(
    icon: AppIcons.template,
    headline: localCopy.templatesLibraryEmptyHeadline,
    message: localCopy.templatesLibraryEmptyMessage,
    actionLabel: localCopy.navTemplates,
    onAction: () => context.go(TemplateLocations.root(context)),
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
  LocalizedMessage? localizedNameError,
  String? saveError,
  LocalizedMessage? localizedSaveError,
});

class _ShippedPicker extends Notifier<_ShippedPickerView> {
  @override
  _ShippedPickerView build() {
    return (
      previewKey: null,
      nameError: null,
      localizedNameError: null,
      saveError: null,
      localizedSaveError: null,
    );
  }

  /// Opens the resolved field list for [templateKey].
  void preview(String templateKey) {
    state = (
      previewKey: templateKey,
      nameError: null,
      localizedNameError: null,
      saveError: null,
      localizedSaveError: null,
    );
  }

  /// Returns to the library list.
  void closePreview() {
    state = (
      previewKey: null,
      nameError: null,
      localizedNameError: null,
      saveError: null,
      localizedSaveError: null,
    );
  }

  /// Copies [templateKey] into the open project under [name].
  Future<TemplateDef?> add({
    required String name,
    required String templateKey,
    required String? projectId,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = (
        previewKey: state.previewKey,
        nameError: Copy.nameRequired,
        localizedNameError: Copy.messages.nameRequired,
        saveError: null,
        localizedSaveError: null,
      );
      return null;
    }
    final loader = ref.read(shippedTemplateLoaderProvider);
    final Result<TemplateDef> result = await (projectId == null
        ? loader.copyToLibrary(templateKey: templateKey, name: trimmed)
        : loader.copyToProject(
            templateKey: templateKey,
            projectId: projectId,
            name: trimmed,
          ));
    switch (result) {
      case Success<TemplateDef>(:final TemplateDef value):
        state = (
          previewKey: null,
          nameError: null,
          localizedNameError: null,
          saveError: null,
          localizedSaveError: null,
        );
        return value;
      case FailureResult<TemplateDef>(:final Failure failure):
        state = (
          previewKey: state.previewKey,
          nameError: null,
          localizedNameError: null,
          saveError: failure.message,
          localizedSaveError: failure.explanation,
        );
        return null;
    }
  }
}

/// Must match [AppRoutes.template]. This file cannot import `router.dart`.
