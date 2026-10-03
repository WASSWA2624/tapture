import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/state_refresh.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_repository.dart';
import '../domain/context_state.dart';

/// Opens the sheet that saves the current context as a named preset.
Future<void> showContextPresetSave({
  required BuildContext context,
  required String projectId,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<void>(
    context,
    title: localCopy.contextPresetSave,
    contentSized: true,
    builder: (BuildContext context) => ContextPresetSave(projectId: projectId),
  );
}

/// Saves every level value and pin currently set under a name unique in the
/// project. A name already in use asks before it is replaced (spec §20.4).
class ContextPresetSave extends ConsumerStatefulWidget {
  /// Creates the save form.
  const ContextPresetSave({super.key, required this.projectId});

  /// Owning project.
  final String projectId;

  @override
  ConsumerState<ContextPresetSave> createState() => _ContextPresetSaveState();
}

class _ContextPresetSaveState extends ConsumerState<ContextPresetSave>
    with StateRefresh {
  final TextEditingController _name = TextEditingController();
  Failure? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? error = _error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x3,
        Space.x0,
        Space.x3,
        Space.x3,
      ),
      child: AppForm(
        compact: true,
        submitLabel: localCopy.contextPresetSave,
        errors: <String>[if (error != null) error.message],
        onSubmit: _save,
        fields: <Widget>[
          AppTextField(
            label: localCopy.contextPresetName,
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Future<bool> _save() async {
    final LocalizedCopy localCopy = Copy.of(context);

    final String name = _name.text.trim();
    final ContextRepository repo = ref.read(contextRepositoryProvider);
    final Result<ContextState> loaded = await repo.load(widget.projectId);
    final ContextState state;
    switch (loaded) {
      case FailureResult<ContextState>(:final Failure failure):
        return _fail(failure);
      case Success<ContextState>(:final ContextState value):
        state = value;
    }
    final List<ContextPreset> presets = await repo
        .watchPresets(widget.projectId)
        .first;
    bool overwrite = false;
    if (name.isNotEmpty &&
        presets.any((ContextPreset preset) => preset.name == name)) {
      if (!mounted) {
        return false;
      }
      overwrite = await showAppConfirm(
        context,
        title: localCopy.contextPresetOverwriteTitle,
        message: localCopy.contextPresetOverwriteMessage,
        confirmLabel: localCopy.contextPresetReplace,
      );
      if (!overwrite) {
        return false;
      }
    }
    final Result<ContextPreset> saved = await repo.savePreset(
      projectId: widget.projectId,
      name: name,
      values: state.values,
      pinned: state.pinned,
      overwrite: overwrite,
    );
    switch (saved) {
      case FailureResult<ContextPreset>(:final Failure failure):
        return _fail(failure);
      case Success<ContextPreset>(:final ContextPreset value):
        if (!mounted) {
          return true;
        }
        showAppSnack(
          context,
          localCopy.contextPresetSaved(value.name),
          tone: SnackTone.success,
        );
        unawaited(Navigator.of(context).maybePop());
        return true;
    }
  }

  bool _fail(Failure failure) {
    if (mounted) {
      refresh(() => _error = failure);
    }
    return false;
  }
}
