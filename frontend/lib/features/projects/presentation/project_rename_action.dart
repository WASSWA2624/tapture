import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;

/// Renames a project without moving its folder.
class ProjectRenameAction {
  /// Opens the rename dialog for [project]. Cancel leaves the name.
  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final String? next = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext _) {
        return _RenameDialog(initialName: project.name);
      },
    );
    if (next == null || next.isEmpty || next == project.name) {
      return;
    }
    await ref
        .read(projectRepositoryProvider)
        .update(project.copyWith(name: next));
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (BuildContext context, TextEditingValue value, Widget? _) {
        final bool canSave = value.text.trim().isNotEmpty;
        return AppDialog.confirm(
          title: Copy.projectRenameTitle,
          message: Copy.projectRenameMessage,
          confirmLabel: Copy.save,
          confirmEnabled: canSave,
          extra: AppTextField(
            label: Copy.projectName,
            controller: _controller,
            requiredness: FieldRequiredness.required,
            dictation: false,
          ),
          onConfirm: () {
            Navigator.of(context).pop(_controller.text.trim());
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
