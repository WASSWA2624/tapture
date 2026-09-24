import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
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
import 'template_list_screen.dart' show templateListProvider;

/// Shows added, removed and retyped fields before any record moves (§18).
class TemplateMigrationScreen extends ConsumerWidget {
  /// Creates the screen for [templateId].
  const TemplateMigrationScreen({super.key, required this.templateId});

  /// Template whose older records this screen can move.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TemplateDef?> value = ref
        .watch(templateListProvider)
        .whenData(_pick);
    final List<CapturedTemplateRecord> records = ref.watch(
      templateCapturedRecordsProvider,
    );
    final _MigrationView view = ref.watch(_migrationProvider(templateId));
    final TemplateDef? template = value.asData?.value;
    final TemplateVersioning preview = template == null
        ? const TemplateVersioning(
            added: <({String fieldKey, String label, int records})>[],
            removed: <({String fieldKey, String label, int records})>[],
            retyped: <({String fieldKey, String label, int records})>[],
            behindCount: 0,
          )
        : TemplateVersioning.preview(current: template, records: records);
    return AppPage(
      key: const ValueKey<String>('route-template-migrate'),
      title: Copy.templateMigrationTitle,
      scrollable: false,
      footer: preview.isEmpty
          ? null
          : AppPrimaryAction(
              label: Copy.templateMigrationAction,
              onPressed: () => _commit(context, ref, template!),
            ),
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) =>
            row == null ||
            TemplateVersioning.preview(current: row, records: records).isEmpty,
        empty: () => const AppEmptyState(
          icon: Icons.upgrade,
          headline: Copy.templateMigrationEmptyHeadline,
          message: Copy.templateMigrationEmptyMessage,
        ),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (TemplateDef? _) => _list(view, preview),
      ),
    );
  }

  Widget _list(_MigrationView view, TemplateVersioning preview) {
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x4),
      children: <Widget>[
        const AppBanner(
          message: Copy.templateMigrationExplain,
          icon: Icons.info_outline,
          tone: SnackTone.info,
        ),
        if (view.saveError != null)
          AppBanner(
            message: view.saveError!,
            icon: Icons.error_outline,
            tone: SnackTone.error,
          ),
        ..._section(Copy.templateMigrationAdded, preview.added),
        ..._section(Copy.templateMigrationRemoved, preview.removed),
        ..._section(Copy.templateMigrationRetyped, preview.retyped),
      ],
    );
  }

  List<Widget> _section(
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
          subtitle: Copy.recordsCount(row.records),
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
  ) async {
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.templateMigrationConfirmTitle,
      message: Copy.templateMigrationConfirm,
      confirmLabel: Copy.templateMigrationAction,
    );
    if (!confirmed) {
      return;
    }
    final bool saved = await ref
        .read(_migrationProvider(templateId).notifier)
        .commit(template);
    if (saved && context.mounted) {
      GoRouter.maybeOf(
        context,
      )?.go(TemplateLocations.detail(context, templateId));
    }
  }
}

/// Captured records the migration screen can move. Defaults to none until
/// the records feature watches captures; tests override this list.
final Provider<List<CapturedTemplateRecord>> templateCapturedRecordsProvider =
    Provider<List<CapturedTemplateRecord>>((Ref _) {
      return const <CapturedTemplateRecord>[];
    });

/// Writes every migrated record in one call. Defaults to a no-op until
/// records persist a captured version; tests override this to fail or store.
final Provider<Future<Result<void>> Function(List<CapturedTemplateRecord> next)>
templateMigrationPersistProvider =
    Provider<Future<Result<void>> Function(List<CapturedTemplateRecord> next)>((
      Ref _,
    ) {
      return (List<CapturedTemplateRecord> _) async {
        return const Success<void>(null);
      };
    });

typedef _MigrationView = ({String? saveError});

final class _Migration extends Notifier<_MigrationView> {
  _Migration(this.templateId);

  final String templateId;

  @override
  _MigrationView build() {
    return (saveError: null);
  }

  Future<bool> commit(TemplateDef template) async {
    final Result<List<CapturedTemplateRecord>> result =
        await TemplateVersioning.apply(
          current: template,
          records: ref.read(templateCapturedRecordsProvider),
          persist: ref.read(templateMigrationPersistProvider),
        );
    switch (result) {
      case Success<List<CapturedTemplateRecord>>():
        state = (saveError: null);
        return true;
      case FailureResult<List<CapturedTemplateRecord>>(:final Failure failure):
        state = (saveError: failure.message);
        return false;
    }
  }
}

final _migrationProvider = NotifierProvider.autoDispose
    .family<_Migration, _MigrationView, String>(
      _Migration.new,
      retry: (int _, Object _) => null,
    );
