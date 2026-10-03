import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/templates/presentation/template_locations.dart';

import '../domain/template_def.dart';
import '../domain/template_versioning.dart';
import '../templates.dart' show templateMigrationRepositoryProvider;
import 'template_list_screen.dart' show templateListProvider;

/// Shows added, removed and retyped fields before any record moves (§18).
class TemplateMigrationScreen extends ConsumerWidget {
  /// Creates the screen for [templateId].
  const TemplateMigrationScreen({super.key, required this.templateId});

  /// Template whose older records this screen can move.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<TemplateDef?> value = ref
        .watch(templateListProvider)
        .whenData(_pick);
    final AsyncValue<List<CapturedTemplateRecord>> captured = ref.watch(
      templateCapturedRecordsProvider(templateId),
    );
    final List<CapturedTemplateRecord> records =
        captured.asData?.value ?? const <CapturedTemplateRecord>[];
    final _MigrationView view = ref.watch(_migrationProvider(templateId));
    final TemplateDef? template = value.asData?.value;
    final TemplateVersioning preview = template == null
        ? const TemplateVersioning.none()
        : TemplateVersioning.preview(current: template, records: records);
    return AppPage(
      key: const ValueKey<String>('route-template-migrate'),
      title: localCopy.templateMigrationTitle,
      scrollable: false,
      footer: preview.isEmpty
          ? null
          : AppPrimaryAction(
              label: localCopy.templateMigrationAction,
              busy: view.busy,
              onPressed: () =>
                  _commit(context, ref, template!, records, preview),
            ),
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) => row == null,
        empty: () => AppEmptyState(
          icon: AppIcons.migrate,
          headline: Copy.of(context).templatesEmptyHeadline,
          message: Copy.of(context).templatesEmptyMessage,
          actionLabel: Copy.of(context).navTemplates,
          onAction: () => context.go(TemplateLocations.root(context)),
        ),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (TemplateDef? _) => AsyncValueView<List<CapturedTemplateRecord>>(
          value: captured,
          onRetry: () =>
              ref.invalidate(templateCapturedRecordsProvider(templateId)),
          isEmpty: (_) => preview.isEmpty,
          empty: () => AppEmptyState(
            icon: AppIcons.migrate,
            headline: Copy.of(context).templateMigrationEmptyHeadline,
            message: Copy.of(context).templateMigrationEmptyMessage,
            actionLabel: Copy.of(context).templateFieldsTitle,
            onAction: () =>
                context.go(TemplateLocations.detail(context, templateId)),
          ),
          data: (_) => _list(context, view, preview),
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    _MigrationView view,
    TemplateVersioning preview,
  ) {
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x4),
      children: <Widget>[
        AppBanner(
          message: Copy.of(context).templateMigrationExplain,
          icon: AppIcons.info,
          tone: SnackTone.info,
        ),
        if (Copy.of(
              context,
            ).stateText(view.localizedSaveError, view.saveError) !=
            null)
          AppBanner(
            message: Copy.of(
              context,
            ).stateText(view.localizedSaveError, view.saveError)!,
            icon: AppIcons.error,
            tone: SnackTone.error,
          ),
        if (preview.unresolved > 0)
          AppBanner(
            key: const ValueKey<String>('migration-unresolved'),
            message: Copy.of(
              context,
            ).templateMigrationUnresolved(preview.unresolved),
            icon: AppIcons.warning,
            tone: SnackTone.warning,
          ),
        AppListTile(
          key: const ValueKey<String>('migration-behind'),
          title: Copy.of(context).templateMigrationBehind(preview.behindCount),
          dense: true,
        ),
        ..._section(
          context,
          Copy.of(context).templateMigrationAdded,
          preview.added,
        ),
        ..._section(
          context,
          Copy.of(context).templateMigrationRemoved,
          preview.removed,
        ),
        ..._section(
          context,
          Copy.of(context).templateMigrationRetyped,
          preview.retyped,
        ),
        ..._section(
          context,
          Copy.of(context).templateMigrationRetiring,
          preview.retiring,
        ),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<({String fieldKey, String label, int records})> rows,
  ) {
    if (rows.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      AppSectionHeader(title: title, dense: true),
      for (final ({String fieldKey, String label, int records}) row in rows)
        AppListTile(
          title: row.label,
          subtitle: Copy.of(context).recordsCount(row.records),
          dense: true,
        ),
    ];
  }

  TemplateDef? _pick(List<TemplateDef> rows) {
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return row;
      }
    }
    return null;
  }

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref,
    TemplateDef template,
    List<CapturedTemplateRecord> reviewed,
    TemplateVersioning preview,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.templateMigrationConfirmTitle,
      message: localCopy.templateMigrationConfirm(preview.behindCount),
      confirmLabel: localCopy.templateMigrationAction,
    );
    if (!confirmed) {
      return;
    }
    final bool saved = await ref
        .read(_migrationProvider(templateId).notifier)
        .commit(template, reviewed);
    if (saved && context.mounted) {
      GoRouter.maybeOf(
        context,
      )?.go(TemplateLocations.detail(context, templateId));
    }
  }
}

/// Only this template's durable captured records enter the preview.
final templateCapturedRecordsProvider = StreamProvider.autoDispose
    .family<List<CapturedTemplateRecord>, String>(
      (Ref ref, String templateId) =>
          ref.watch(templateMigrationRepositoryProvider).watch(templateId),
    );

typedef _MigrationView = ({
  String? saveError,
  LocalizedMessage? localizedSaveError,
  bool busy,
});

final class _Migration extends Notifier<_MigrationView> {
  _Migration(this.templateId);

  final String templateId;

  @override
  _MigrationView build() {
    return (saveError: null, localizedSaveError: null, busy: false);
  }

  Future<bool> commit(
    TemplateDef template,
    List<CapturedTemplateRecord> reviewed,
  ) async {
    if (state.busy) {
      return false;
    }
    state = (saveError: null, localizedSaveError: null, busy: true);
    final Result<void> result = await ref
        .read(templateMigrationRepositoryProvider)
        .migrate(template: template, reviewed: reviewed);
    if (!ref.mounted) {
      return false;
    }
    switch (result) {
      case Success<void>():
        state = (saveError: null, localizedSaveError: null, busy: false);
        return true;
      case FailureResult<void>(:final Failure failure):
        state = (
          saveError: failure.message,
          localizedSaveError: failure.explanation,
          busy: false,
        );
        return false;
    }
  }
}

final _migrationProvider = NotifierProvider.autoDispose
    .family<_Migration, _MigrationView, String>(
      _Migration.new,
      retry: (int _, Object _) => null,
    );
