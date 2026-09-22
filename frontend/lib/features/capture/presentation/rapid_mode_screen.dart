import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// High-speed loop: save raw, reset, live preview; list of recent items.
final class RapidModeScreen extends StatelessWidget {
  /// Creates rapid mode.
  const RapidModeScreen({
    required this.items,
    required this.onCapture,
    required this.onReopen,
    required this.preview,
    super.key,
  });

  /// Recent items with photo counts.
  final List<({String recordId, int photoCount})> items;

  /// One-tap save raw + reset.
  final VoidCallback onCapture;

  /// Reopen last item for correction.
  final ValueChanged<String> onReopen;

  /// Live preview.
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.captureRapidMode)),
      body: Column(
        children: <Widget>[
          Expanded(flex: 2, child: preview),
          AppButton(label: Copy.captureSaveRaw, onPressed: onCapture),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.recordId),
                  subtitle: Text('${item.photoCount}'),
                  onTap: () => onReopen(item.recordId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
