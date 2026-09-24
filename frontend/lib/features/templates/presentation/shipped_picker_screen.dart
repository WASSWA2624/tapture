import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/presentation/template_locations.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../templates.dart' show shippedTemplateLoaderProvider;
import 'template_list_screen.dart';

/// Picker for the shipped library: list by kind, preview fields, then copy.
class ShippedPickerScreen extends ConsumerStatefulWidget {
  /// Creates the library picker.
  const ShippedPickerScreen({super.key});

  @override
  ConsumerState<ShippedPickerScreen> createState() =>
      _ShippedPickerScreenState();
}

class _ShippedPickerScreenState extends ConsumerState<ShippedPickerScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TemplateDef>> value = ref.watch(
      shippedLibraryProvider,
    );
    final _ShippedPickerView view = ref.watch(_shippedPickerProvider);
    final TemplateDef? preview = _selected(
      value.asData?.value,
      view.previewKey,
    );
    if (preview != null && _name.text.isEmpty) {
      _name.text = Copy.shippedTemplateName(preview.templateKey);
    }
    return AppPage(
      key: const ValueKey<String>('route-template-library'),
      title: preview == null
          ? Copy.templatesLibraryTitle
          : Copy.shippedTemplateName(preview.templateKey),
      scrollable: preview == null,
      leading: preview == null
          ? null
          : AppIconButton(
              icon: Icons.arrow_back,
              semanticLabel: Copy.close,
              tooltip: Copy.close,
              outlined: false,
              onPressed: () {
                _name.clear();
                ref.read(_shippedPickerProvider.notifier).closePreview();
              },
            ),
      body: AsyncValueView<List<TemplateDef>>(
        value: value,
        isEmpty: (List<TemplateDef> rows) => rows.isEmpty,
        empty: _empty,
        onRetry: () => ref.invalidate(shippedLibraryProvider),
        data: (List<TemplateDef> rows) {
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

  Widget _library(List<TemplateDef> rows, Set<String> attached) {
    String? lastKind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final TemplateDef template in rows) ...<Widget>[
          if (template.kind != lastKind)
            AppSectionHeader(
              title: Copy.shippedKindTitle(lastKind = template.kind),
              dense: true,
            ),
          AppListTile(
            title: Copy.shippedTemplateName(template.templateKey),
            subtitle: attached.contains(template.templateKey)
                ? Copy.shippedAddedToProject
                : Copy.fieldsCount(template.fields.length),
            trailing: attached.contains(template.templateKey)
                ? const Icon(Icons.check_circle_outline)
                : null,
            onTap: () => ref
                .read(_shippedPickerProvider.notifier)
                .preview(template.templateKey),
          ),
        ],
      ],
    );
  }

  Widget _preview(
    TemplateDef template,
    _ShippedPickerView view,
    bool attached,
  ) {
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
            leading: Icon(Icons.check_circle_outline),
            dense: true,
          ),
        for (final FieldDef field in template.fields)
          AppListTile(title: Copy.shippedLabel(field.label), dense: true),
      ],
      submitLabel: attached
          ? Copy.templatesCustomCopy
          : Copy.templatesAddToProject,
      onSubmit: () async {
        final GoRouter? router = GoRouter.maybeOf(context);
        final TemplateDef? created = await ref
            .read(_shippedPickerProvider.notifier)
            .add(name: _name.text, source: template);
        if (created == null || router == null || !mounted) {
          return;
        }
        router.go(TemplateLocations.detail(context, created.id));
      },
    );
  }
}

Widget _empty() {
  return const AppEmptyState(
    icon: Icons.article_outlined,
    headline: Copy.templatesLibraryEmptyHeadline,
    message: Copy.templatesLibraryEmptyMessage,
  );
}

TemplateDef? _selected(List<TemplateDef>? rows, String? key) {
  if (rows == null || key == null) {
    return null;
  }
  for (final TemplateDef row in rows) {
    if (row.templateKey == key) {
      return row;
    }
  }
  return null;
}

/// Live shipped library. Auto-dispose: the picker is the only reader.
final FutureProvider<List<TemplateDef>> shippedLibraryProvider =
    FutureProvider<List<TemplateDef>>((Ref ref) async {
      final Result<List<TemplateDef>> result = await ref
          .watch(shippedTemplateLoaderProvider)
          .library();
      return switch (result) {
        Success<List<TemplateDef>>(:final List<TemplateDef> value) => value,
        FailureResult<List<TemplateDef>>(:final Failure failure) =>
          throw failure,
      };
    });

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

  /// Returns to the kind list.
  void closePreview() {
    state = (previewKey: null, nameError: null, saveError: null);
  }

  /// Copies [source] into the open project under [name].
  Future<TemplateDef?> add({
    required String name,
    required TemplateDef source,
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
          templateKey: source.templateKey,
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
