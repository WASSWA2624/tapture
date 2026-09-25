import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';
import 'package:tapture/features/capture/presentation/caption_scope_selector.dart';

/// Edit one photo caption.
final class PhotoCaptionSheet extends StatefulWidget {
  /// Creates a sheet.
  const PhotoCaptionSheet({
    required this.initial,
    required this.onSave,
    this.failureMessage,
    this.selectedCount = 0,
    this.allCount = 1,
    this.initialScope = CaptionScope.thisPhoto,
    this.showScope = true,
    this.audio,
    super.key,
  });

  /// Existing caption.
  final String initial;

  /// Persist; return false on failure.
  final Future<bool> Function(String text, CaptionScope scope) onSave;

  /// Optional failure banner.
  final String? failureMessage;

  /// Photos in the current selection.
  final int selectedCount;

  /// Photos in the session.
  final int allCount;

  /// Scope selected when the sheet opens.
  final CaptionScope initialScope;

  /// When false, the sheet edits only [initialScope] and hides the chooser.
  final bool showScope;

  /// Optional recorder, the same control the capture page uses.
  final Widget? audio;

  @override
  State<PhotoCaptionSheet> createState() => _PhotoCaptionSheetState();
}

class _PhotoCaptionSheetState extends State<PhotoCaptionSheet> {
  late final TextEditingController _controller;
  String? _error;
  CaptionScope _scope = CaptionScope.thisPhoto;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    _error = widget.failureMessage;
    _scope = widget.initialScope;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(Copy.capturePhotoCaption),
          if (widget.showScope)
            CaptionScopeSelector(
              scope: _scope,
              thisCount: 1,
              selectedCount: widget.selectedCount,
              allCount: widget.allCount,
              onChanged: (CaptionScope scope) => setState(() => _scope = scope),
            ),
          AppTextField(
            controller: _controller,
            label: Copy.capturePhotoCaption,
          ),
          if (_error != null) Text(_error!),
          ?widget.audio,
          AppButton(
            label: Copy.captureSaved,
            onPressed: () async {
              final bool ok = await widget.onSave(_controller.text, _scope);
              if (!ok) {
                setState(() => _error = Copy.captureSaveFailed);
              } else if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ],
      ),
    );
  }
}
