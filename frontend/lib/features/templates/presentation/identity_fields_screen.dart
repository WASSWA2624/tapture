import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'template_list_screen.dart' show templateListProvider;
import 'template_locations.dart';

/// Template-level identity set for duplicate detection (§13.5).
class IdentityFieldsScreen extends ConsumerWidget {
  /// Creates the screen for [templateId].
  const IdentityFieldsScreen({super.key, required this.templateId});

  /// Template whose identity keys this screen edits.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TemplateDef?> value = ref
        .watch(templateListProvider)
        .whenData(_pick);
    final _IdentityView view = ref.watch(_identityFieldsProvider(templateId));
    return AppPage(
      key: const ValueKey<String>('route-template-identity'),
      title: Copy.identityFieldsTitle,
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
          icon: AppIcons.identity,
          headline: Copy.identityFieldsEmptyHeadline,
          message: Copy.identityFieldsEmptyMessage,
        ),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (TemplateDef? row) => _list(ref, row!, view),
      ),
    );
  }

  Widget _list(WidgetRef ref, TemplateDef template, _IdentityView view) {
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x4),
      children: <Widget>[
        const AppBanner(
          message: Copy.identityFieldsExplain,
          icon: AppIcons.info,
          tone: SnackTone.info,
        ),
        if (view.saveError != null)
          AppBanner(
            message: view.saveError!,
            icon: AppIcons.error,
            tone: SnackTone.error,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, 0),
          child: AppCheckboxGroup<String>(
            label: Copy.identityFieldsTitle,
            showLabel: false,
            value: view.selected,
            options: <Choice<String>>[
              for (final FieldDef field in template.fields)
                Choice<String>(field.fieldKey, field.label),
            ],
            onChanged: (Set<String> next) {
              ref.read(_identityFieldsProvider(templateId).notifier).set(next);
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
    final bool saved = await ref
        .read(_identityFieldsProvider(templateId).notifier)
        .commit();
    if (saved && context.mounted) {
      GoRouter.maybeOf(
        context,
      )?.go(TemplateLocations.detail(context, templateId));
    }
  }
}

typedef _IdentityView = ({Set<String> selected, String? saveError, bool dirty});

final class _IdentityFields extends Notifier<_IdentityView> {
  _IdentityFields(this.templateId);

  final String templateId;

  _IdentityView? _held;

  @override
  _IdentityView build() {
    ref.onDispose(() => _held = null);
    final List<TemplateDef> rows =
        ref.watch(templateListProvider).asData?.value ?? const <TemplateDef>[];
    final _IdentityView? held = _held;
    if (held != null && held.dirty) {
      return held;
    }
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return (selected: _selectedOf(row), saveError: null, dirty: false);
      }
    }
    return (selected: <String>{}, saveError: null, dirty: false);
  }

  void set(Set<String> selected) {
    state = (selected: selected, saveError: null, dirty: true);
    _held = state;
  }

  Future<bool> commit() async {
    final TemplateDef? source = _source();
    if (source == null) {
      const StorageFailure missing = StorageFailure(
        message: 'That template is no longer on this device.',
        recoveryAction: 'Open the template list and try again.',
      );
      state = (
        selected: state.selected,
        saveError: missing.message,
        dirty: state.dirty,
      );
      _held = state;
      return false;
    }
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(_write(source, state.selected));
    switch (result) {
      case Success<TemplateDef>():
        _held = null;
        state = (
          selected: _selectedOf(result.value),
          saveError: null,
          dirty: false,
        );
        return true;
      case FailureResult<TemplateDef>(:final Failure failure):
        state = (
          selected: state.selected,
          saveError: failure.message,
          dirty: true,
        );
        _held = state;
        return false;
    }
  }

  TemplateDef? _source() {
    final List<TemplateDef> rows =
        ref.read(templateListProvider).asData?.value ?? const <TemplateDef>[];
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return row;
      }
    }
    return null;
  }
}

final _identityFieldsProvider = NotifierProvider.autoDispose
    .family<_IdentityFields, _IdentityView, String>(
      _IdentityFields.new,
      retry: (int _, Object _) => null,
    );

Set<String> _selectedOf(TemplateDef template) {
  final Set<String> keys = <String>{
    for (final FieldDef field in template.fields) field.fieldKey,
  };
  return <String>{
    for (final String key in template.identityFieldKeys)
      if (keys.contains(key)) key,
    for (final FieldDef field in template.fields)
      if (field.identity) field.fieldKey,
  };
}

TemplateDef _write(TemplateDef template, Set<String> selected) {
  return template.copyWith(
    identityFieldKeys: <String>[
      for (final FieldDef field in template.fields)
        if (selected.contains(field.fieldKey)) field.fieldKey,
    ],
    fields: <FieldDef>[
      for (final FieldDef field in template.fields)
        field.copyWith(identity: selected.contains(field.fieldKey)),
    ],
  );
}
