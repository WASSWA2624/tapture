import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/image_redaction.dart';
import 'package:tapture/core/files/photo_privacy_service.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/state_refresh.dart';

import 'redaction_editor.dart';

/// Edits normalized masks and confirms only after the audit write succeeds.
final class PhotoRedactionScreen extends StatefulWidget {
  /// Creates the editor for an upright preview of the original photo.
  const PhotoRedactionScreen({
    required this.photoId,
    required this.preview,
    required this.marks,
    required this.privacy,
    super.key,
  });

  /// Photo owning these masks, including derived versions.
  final String photoId;

  /// Bounded upright bitmap used only for display.
  final ({Uint8List bytes, int width, int height}) preview;

  /// Latest durable masks.
  final List<ImageRect> marks;

  /// Shared policy persistence and outbound resolver.
  final PhotoPrivacyService privacy;

  @override
  State<PhotoRedactionScreen> createState() => _PhotoRedactionScreenState();
}

final class _PhotoRedactionScreenState extends State<PhotoRedactionScreen>
    with StateRefresh<PhotoRedactionScreen> {
  late List<ImageRect> _marks = List<ImageRect>.of(widget.marks);
  bool _saving = false;

  @override
  Widget build(BuildContext context) => AppPage(
    title: Copy.of(context).redactionTitle,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(Copy.of(context).redactionHint),
        const SizedBox(height: Space.x3),
        RedactionEditor(
          bytes: widget.preview.bytes,
          imageWidth: widget.preview.width,
          imageHeight: widget.preview.height,
          marks: _marks,
          onChanged: (List<ImageRect> marks) => refresh(() => _marks = marks),
        ),
        const SizedBox(height: Space.x2),
        Text(Copy.of(context).redactionCount(_marks.length)),
        if (_marks.isNotEmpty)
          AppButton(
            label: Copy.of(context).clear,
            icon: AppIcons.clear,
            variant: AppButtonVariant.text,
            onPressed: _saving
                ? null
                : () => refresh(() => _marks = <ImageRect>[]),
          ),
      ],
    ),
    footer: AppPrimaryAction(
      label: Copy.of(context).redactionSave,
      busy: _saving,
      onPressed: () => unawaited(_save()),
    ),
  );

  Future<void> _save() async {
    if (_saving) return;
    refresh(() => _saving = true);
    final Result<void> result = await widget.privacy.setMarks(
      widget.photoId,
      _marks,
    );
    if (!mounted) return;
    refresh(() => _saving = false);
    switch (result) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      case Success<void>():
        Navigator.of(context).pop(true);
    }
  }
}
