import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

/// Edit one photo caption.
final class PhotoCaptionSheet extends StatefulWidget {
  /// Creates a sheet.
  const PhotoCaptionSheet({
    required this.initial,
    required this.onSave,
    this.failureMessage,
    super.key,
  });

  /// Existing caption.
  final String initial;

  /// Persist; return false on failure.
  final Future<bool> Function(String text) onSave;

  /// Optional failure banner.
  final String? failureMessage;

  @override
  State<PhotoCaptionSheet> createState() => _PhotoCaptionSheetState();
}

class _PhotoCaptionSheetState extends State<PhotoCaptionSheet> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    _error = widget.failureMessage;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(Copy.capturePhotoCaption),
          AppTextField(
            controller: _controller,
            label: Copy.capturePhotoCaption,
          ),
          if (_error != null) Text(_error!),
          AppButton(
            label: Copy.captureSaved,
            onPressed: () async {
              final bool ok = await widget.onSave(_controller.text);
              if (!ok) {
                setState(() => _error = 'write failed');
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
