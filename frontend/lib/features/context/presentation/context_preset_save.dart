import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_state.dart';
import 'context_providers.dart';

/// Saves the current context as a named preset.
class ContextPresetSave extends ConsumerStatefulWidget {
  /// Creates the save control.
  const ContextPresetSave({super.key, required this.projectId, this.failure});

  /// Owning project.
  final String projectId;

  /// Injected failure for tests.
  final Failure? failure;

  @override
  ConsumerState<ContextPresetSave> createState() => _ContextPresetSaveState();
}

class _ContextPresetSaveState extends ConsumerState<ContextPresetSave> {
  final TextEditingController _name = TextEditingController();
  Failure? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure ?? _error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (failure != null)
          Text(
            failure.message,
            key: const ValueKey<String>('preset-save-error'),
          ),
        AppTextField(label: Copy.contextPresetSave, controller: _name),
        const SizedBox(height: 8),
        AppButton(
          label: Copy.contextPresetSave,
          busy: _busy,
          onPressed: _busy ? null : () => unawaited(_save()),
        ),
      ],
    );
  }

  Future<void> _save({bool overwrite = false}) async {
    final ContextState state =
        ref.read(projectContextProvider(widget.projectId)).asData?.value ??
        const ContextState();
    setState(() => _busy = true);
    final Result<ContextPreset> result = await ref
        .read(contextRepositoryProvider)
        .savePreset(
          projectId: widget.projectId,
          name: _name.text,
          values: state.values,
          pinned: state.pinned,
          overwrite: overwrite,
        );
    if (!mounted) {
      return;
    }
    switch (result) {
      case FailureResult<ContextPreset>(:final Failure failure):
        if (!overwrite &&
            failure.message.contains('already exists') &&
            mounted) {
          final bool ok = await showAppConfirm(
            context,
            title: Copy.contextPresetOverwriteTitle,
            message: Copy.contextPresetOverwriteMessage,
            confirmLabel: Copy.contextPresetOverwriteTitle,
          );
          if (ok) {
            await _save(overwrite: true);
            return;
          }
        }
        setState(() {
          _busy = false;
          _error = failure;
        });
      case Success<ContextPreset>():
        setState(() => _busy = false);
        if (mounted) {
          Navigator.of(context).maybePop();
        }
    }
  }
}
