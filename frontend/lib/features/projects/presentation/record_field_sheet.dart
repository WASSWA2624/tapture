import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import '../domain/project_repository.dart';
import 'record_edit_controller.dart';
import 'record_edit_sheet.dart';
import 'record_field_draft.dart';
import 'record_field_input.dart';

/// Opens one field of [row] to type its value by hand, as a sheet, or a
/// side panel on expanded windows (FBK0000162, FE-CONS-05, FE-CONS-10).
Future<void> showRecordFieldSheet(
  BuildContext context,
  ProjectRecordRow row,
  RecordEditEntry entry,
) {
  return showAppSheet<void>(
    context,
    title: entry.label,
    builder: (BuildContext _) => RecordFieldSheet(row: row, entry: entry),
  );
}

/// One record field in the input its type names, and Save. The raw value
/// stays; the typed one is written beside it with an audit row, as the
/// all-fields sheet writes it (FE-SEC-08, FE-SEC-09).
class RecordFieldSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [entry] of [row].
  const RecordFieldSheet({required this.row, required this.entry, super.key});

  /// The record the field belongs to.
  final ProjectRecordRow row;

  /// The field being filled.
  final RecordEditEntry entry;

  @override
  ConsumerState<RecordFieldSheet> createState() => _RecordFieldSheetState();
}

class _RecordFieldSheetState extends ConsumerState<RecordFieldSheet> {
  late final TextEditingController _plain = TextEditingController(
    text: widget.entry.initial,
  );

  @override
  void dispose() {
    _plain.dispose();
    super.dispose();
  }

  String get _text =>
      ref.read(
        recordFieldDraftProvider(widget.row.id),
      )[widget.entry.fieldKey] ??
      widget.entry.initial;

  @override
  Widget build(BuildContext context) {
    final RecordEditState state = ref.watch(
      recordEditControllerProvider(widget.row.id),
    );
    ref.watch(recordFieldDraftProvider(widget.row.id));
    final Failure? failure = state.failure;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x3,
        Space.x0,
        Space.x3,
        Space.x3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RecordFieldInput(
            entry: widget.entry,
            text: _text,
            controller: widget.entry.field == null ? _plain : null,
            onChanged: (String text) => ref
                .read(recordFieldDraftProvider(widget.row.id).notifier)
                .set(widget.entry.fieldKey, text),
          ),
          if (failure != null) ...<Widget>[
            const SizedBox(height: Space.x2),
            AppBanner(
              message: failure.message,
              icon: AppIcons.error,
              tone: SnackTone.error,
            ),
          ],
          const SizedBox(height: Space.x3),
          AppPrimaryAction(
            key: const ValueKey<String>('record-field-save'),
            label: Copy.save,
            busy: state.saving,
            onPressed: () => unawaited(_save()),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final NavigatorState navigator = Navigator.of(context);
    final String text = _text;
    if (!recordFieldChanged(widget.entry, text)) {
      navigator.pop();
      return;
    }
    final Result<void> saved = await ref
        .read(recordEditControllerProvider(widget.row.id).notifier)
        .save(<RecordFieldEdit>[
          (
            fieldKey: widget.entry.fieldKey,
            value: text,
            stored: widget.entry.stored,
          ),
        ]);
    if (mounted && saved is Success<void>) {
      navigator.pop();
    }
  }
}
