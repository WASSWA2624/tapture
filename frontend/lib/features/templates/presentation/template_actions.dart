import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/state_refresh.dart';

import '../domain/template_def.dart';
import 'template_duplicate_action.dart';
import 'template_library_controller.dart';
import 'template_locations.dart';

/// Shared commands for saved project and global-library templates.
abstract final class TemplateActions {
  /// Opens the editable saved template in its current navigation branch.
  static void open(BuildContext context, String id) => _open(context, id);

  /// Commands for a saved template. Shipped assets never call this.
  static List<AppOverflowAction> items(
    BuildContext context,
    WidgetRef ref,
    TemplateDef template,
    int recordCount,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    return <AppOverflowAction>[
      AppOverflowAction(
        label: localCopy.templatesEdit,
        icon: AppIcons.edit,
        onTap: () => unawaited(_rename(context, ref, template)),
      ),
      AppOverflowAction(
        label: localCopy.templatesOpen,
        icon: AppIcons.template,
        onTap: () => _open(context, template.id),
      ),
      AppOverflowAction(
        label: localCopy.projectsDuplicate,
        icon: AppIcons.duplicate,
        onTap: () => unawaited(_duplicate(context, ref, template)),
      ),
      if (template.projectId != null)
        AppOverflowAction(
          label: localCopy.templatesExport,
          icon: AppIcons.export,
          onTap: () => context.go(
            TemplateLocations.child(context, template.id, 'export'),
          ),
        ),
      if (template.projectId != null)
        AppOverflowAction(
          label: localCopy.templatesImport,
          icon: AppIcons.import,
          onTap: () => context.go(TemplateLocations.import(context)),
        ),
      if (recordCount == 0)
        AppOverflowAction(
          label: localCopy.templatesDelete,
          icon: AppIcons.delete,
          onTap: () => unawaited(_delete(context, ref, template, recordCount)),
        ),
    ];
  }
}

Future<void> _duplicate(
  BuildContext context,
  WidgetRef ref,
  TemplateDef template,
) async {
  final TemplateDef? copy = await TemplateDuplicateAction.apply(
    ref,
    template,
    localizedCopy: Copy.of(context),
  );
  if (copy == null || !context.mounted) {
    return;
  }
  _open(context, copy.id);
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  TemplateDef template,
  int recordCount,
) async {
  final LocalizedCopy localCopy = Copy.of(context);

  final bool confirmed = await showAppConfirm(
    context,
    title: localCopy.templatesDeleteTitle(template.name),
    message: localCopy.templatesDeleteMessage(
      fields: template.fields.length,
      records: recordCount,
    ),
    confirmLabel: localCopy.templatesDelete,
    destructive: true,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  final TemplateLibraryController controller = ref.read(
    templateLibraryControllerProvider,
  );
  final Result<void> result = await controller.delete(template.id);
  if (!context.mounted) return;
  switch (result) {
    case FailureResult<void>(:final failure):
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
    case Success<void>():
      showAppSnack(
        context,
        localCopy.templatesDeleted,
        undoLabel: localCopy.undo,
        onUndo: () => unawaited(() async {
          final Result<void> restored = await controller.restore(template.id);
          if (!context.mounted) return;
          if (restored case FailureResult<void>(:final failure)) {
            showAppSnack(
              context,
              failure.message,
              tone: SnackTone.error,
              localizedMessage: failure.explanation,
            );
          }
        }()),
      );
  }
}

void _open(BuildContext context, String id) {
  context.go(TemplateLocations.detail(context, id));
}

Future<void> _rename(
  BuildContext context,
  WidgetRef ref,
  TemplateDef template,
) async {
  final LocalizedCopy localCopy = Copy.of(context);

  final TemplateLibraryController controller = ref.read(
    templateLibraryControllerProvider,
  );
  await showAppSheet<void>(
    context,
    title: localCopy.templatesEdit,
    contentSized: true,
    builder: (BuildContext sheetContext) {
      return _RenameTemplate(
        initial: template.name,
        onSave: (String name) => controller.rename(template.id, name),
      );
    },
  );
}

class _RenameTemplate extends StatefulWidget {
  const _RenameTemplate({required this.initial, required this.onSave});

  final String initial;
  final Future<Result<void>> Function(String name) onSave;

  @override
  State<_RenameTemplate> createState() => _RenameTemplateState();
}

class _RenameTemplateState extends State<_RenameTemplate> with StateRefresh {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppForm(
      compact: true,
      fields: <Widget>[
        AppTextField(
          label: localCopy.projectName,
          controller: _name,
          errorText: _error,
          onChanged: (_) {
            if (_error != null) refresh(() => _error = null);
          },
        ),
      ],
      submitLabel: localCopy.save,
      onSubmit: () async {
        final String trimmed = _name.text.trim();
        if (trimmed.isEmpty) {
          refresh(() => _error = localCopy.nameRequired);
          return false;
        }
        final Result<void> result = await widget.onSave(trimmed);
        if (!context.mounted) return false;
        switch (result) {
          case FailureResult<void>(:final failure):
            refresh(() => _error = localCopy.failureMessage(failure));
            return false;
          case Success<void>():
            Navigator.of(context).pop();
            return true;
        }
      },
    );
  }
}
