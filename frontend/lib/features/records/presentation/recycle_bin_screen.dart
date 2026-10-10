import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_list_viewport.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import 'record_providers.dart';
import 'recycle_bin_controller.dart';

/// One compact bin for deleted projects, records and managed files.
/// With no selection, bulk actions name all items; selecting narrows them.
final class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen>
    with StateRefresh {
  final Map<String, DeletedEntity> _selected = <String, DeletedEntity>{};
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy copy = Copy.of(context);
    final AsyncValue<List<DeletedEntity>> bin = ref.watch(
      deletedEntitiesProvider,
    );
    final RecycleBinActivity activity = ref.watch(recycleBinControllerProvider);
    final bool busy =
        _confirming || activity.emptying || activity.restoring.isNotEmpty;
    final bool canPurge = ref.watch(recyclePurgeProvider) != null;
    final List<DeletedEntity> rows =
        bin.asData?.value ?? const <DeletedEntity>[];
    final List<DeletedEntity> selected = rows.where(_isSelected).toList();
    final List<DeletedEntity> targets = selected.isEmpty ? rows : selected;
    final String restore = selected.isEmpty
        ? copy.recycleRestoreAll
        : copy.recycleRestoreSelected;
    final String remove = selected.isEmpty
        ? copy.recycleDeleteAll
        : copy.recycleDeleteSelected;
    return AppPage(
      key: const ValueKey<String>('route-recycle-bin'),
      title: copy.recycleBinTitle,
      scrollable: false,
      inset: false,
      footer: rows.isEmpty
          ? null
          : Row(
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    liveRegion: busy,
                    child: Text(
                      busy
                          ? copy.busyAction(copy.recycleBinTitle)
                          : copy.feedbackSelected(selected.length),
                    ),
                  ),
                ),
                _action(
                  'recycle-bin-select-all',
                  AppIcons.selectAll,
                  copy.selectAll,
                  busy
                      ? null
                      : () => refresh(() {
                          if (selected.length == rows.length) {
                            _selected.clear();
                          } else {
                            _selected
                              ..clear()
                              ..addEntries(
                                rows.map(
                                  (DeletedEntity row) =>
                                      MapEntry<String, DeletedEntity>(
                                        row.key,
                                        row,
                                      ),
                                ),
                              );
                          }
                        }),
                  selected: selected.length == rows.length,
                ),
                _action(
                  'recycle-bin-restore-selected',
                  AppIcons.restore,
                  restore,
                  busy
                      ? null
                      : () => unawaited(_apply(targets, permanently: false)),
                ),
                _action(
                  'recycle-bin-delete-selected',
                  AppIcons.delete,
                  remove,
                  busy || !canPurge
                      ? null
                      : () => unawaited(_apply(targets, permanently: true)),
                ),
              ],
            ),
      body: AsyncValueView<List<DeletedEntity>>(
        value: bin,
        onRetry: () =>
            ref.read(recycleBinControllerProvider.notifier).refresh(),
        isEmpty: (List<DeletedEntity> loaded) => loaded.isEmpty,
        empty: () => AppEmptyState(
          icon: AppIcons.recycleBin,
          headline: copy.recycleBinEmptyHeadline,
          message: copy.recycleBinEmptyMessage(
            ref.watch(recordRetentionDaysProvider),
          ),
          actionLabel: copy.navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
        data: (List<DeletedEntity> loaded) => AppListViewport(
          header:
              loaded.any(
                (DeletedEntity row) => row.kind == DeletedEntityKind.record,
              )
              ? Padding(
                  padding: const EdgeInsets.all(Space.x3),
                  child: Text(
                    copy.recycleBinKeptFor(
                      ref.watch(recordRetentionDaysProvider),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          body: ListView.builder(
            key: const ValueKey<String>('recycle-bin-list'),
            itemCount: loaded.length,
            itemBuilder: (BuildContext context, int index) {
              final DeletedEntity entity = loaded[index];
              final String type = switch (entity.kind) {
                DeletedEntityKind.project => copy.recycleTypeProject,
                DeletedEntityKind.record => copy.recycleTypeRecord,
                DeletedEntityKind.photo => copy.recycleTypePhoto,
                DeletedEntityKind.document => copy.recycleTypeDocument,
                DeletedEntityKind.audio => copy.recycleTypeAudio,
              };
              final String title = entity.name.isEmpty ? type : entity.name;
              return AppListTile(
                key: ValueKey<String>('recycle-bin-row-${entity.key}'),
                title: title,
                subtitle: copy.recycleEntitySubtitle(type, entity.projectName),
                wrapText: true,
                selected: _isSelected(entity),
                onTap: busy ? null : () => _toggle(entity),
                onLongPress: busy ? null : () => _toggle(entity),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _action(
                      'recycle-bin-restore-${entity.key}',
                      AppIcons.restore,
                      copy.recycleBinRestoreLabel(title),
                      busy
                          ? null
                          : () => unawaited(
                              _apply(<DeletedEntity>[
                                entity,
                              ], permanently: false),
                            ),
                    ),
                    _action(
                      'recycle-bin-delete-${entity.key}',
                      AppIcons.delete,
                      copy.recycleDeleteLabel(title),
                      busy || !canPurge
                          ? null
                          : () => unawaited(
                              _apply(<DeletedEntity>[
                                entity,
                              ], permanently: true),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isSelected(DeletedEntity entity) {
    final DeletedEntity? selected = _selected[entity.key];
    return selected != null &&
        selected.deletionId == entity.deletionId &&
        selected.deletedAt.isAtSameMomentAs(entity.deletedAt);
  }

  void _toggle(DeletedEntity entity) => refresh(() {
    if (_isSelected(entity)) {
      _selected.remove(entity.key);
    } else {
      _selected[entity.key] = entity;
    }
  });

  Widget _action(
    String key,
    IconData icon,
    String label,
    VoidCallback? onPressed, {
    bool? selected,
  }) => AppIconButton(
    key: ValueKey<String>(key),
    icon: icon,
    semanticLabel: label,
    tooltip: label,
    outlined: false,
    selected: selected,
    onPressed: onPressed,
  );

  Future<void> _apply(
    List<DeletedEntity> rows, {
    required bool permanently,
  }) async {
    final List<DeletedEntity> snapshot = List<DeletedEntity>.unmodifiable(rows);
    if (snapshot.isEmpty || _confirming) {
      return;
    }
    final RecycleBinController controller = ref.read(
      recycleBinControllerProvider.notifier,
    );
    final BuildContext host = Navigator.of(
      context,
      rootNavigator: true,
    ).context;
    if (permanently) {
      refresh(() => _confirming = true);
      final LocalizedCopy copy = Copy.of(context);
      final bool confirmed = await showAppConfirm(
        context,
        title: copy.recycleDeleteTitle,
        message: copy.recycleDeleteWarning(snapshot.length),
        confirmLabel: copy.recycleDeletePermanent,
        destructive: true,
      );
      if (!mounted) {
        return;
      }
      refresh(() => _confirming = false);
      if (!confirmed) {
        return;
      }
    }
    final RecycleBinResult result = await controller.apply(
      snapshot,
      permanently: permanently,
    );
    if (mounted) {
      refresh(() {
        for (final DeletedEntity entity in snapshot) {
          if (!result.failed.containsKey(entity.key)) {
            _selected.remove(entity.key);
          }
        }
      });
    }
    if (!host.mounted) {
      return;
    }
    final LocalizedCopy copy = Copy.of(host);
    final String message = permanently
        ? copy.recycleDeleteResult(result.succeeded, result.failed.length)
        : copy.recycleRestoreResult(result.succeeded, result.failed.length);
    showAppSnack(
      host,
      result.failed.isEmpty
          ? message
          : '$message ${copy.failureMessage(result.failed.values.first)}',
      tone: result.failed.isEmpty
          ? SnackTone.success
          : result.succeeded == 0
          ? SnackTone.error
          : SnackTone.warning,
    );
  }
}
