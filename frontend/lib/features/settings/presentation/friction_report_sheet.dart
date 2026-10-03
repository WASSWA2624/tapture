import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/feedback/feedback.dart'
    show FeedbackContext, FeedbackEntry;

import 'friction_report_controller.dart';

/// A local report sheet leaves the underlying route and capture providers mounted.
final class FrictionReportSheet extends ConsumerWidget {
  /// Context is frozen before the sheet's own controls are used.
  const FrictionReportSheet({
    super.key,
    required this.origin,
    required this.capture,
  });

  /// The operator, project, screen and last action when reporting began.
  final FeedbackContext origin;

  /// Captures the app layer only when the tester asks for an image.
  final Future<Uint8List?> Function() capture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final TextEditingController note = ref.watch(_noteProvider);
    final ({bool saving, bool screenshot, Failure? error}) view = ref.watch(
      frictionReportControllerProvider,
    );
    final FrictionReportController controller = ref.read(
      frictionReportControllerProvider.notifier,
    );
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            label: localCopy.frictionNote,
            controller: note,
            maxLines: null,
            minLines: 2,
          ),
          const SizedBox(height: Space.x2),
          AppSwitchTile.checkbox(
            title: localCopy.frictionScreenshot,
            value: view.screenshot,
            enabled: !view.saving,
            onChanged: controller.includeScreenshot,
          ),
          if (view.error != null)
            AppBanner(
              message: <String>[
                localCopy.failureMessage(view.error!),
                ?localCopy.failureRecovery(view.error!),
              ].join(' '),
              icon: AppIcons.warning,
              tone: SnackTone.error,
            ),
          const SizedBox(height: Space.x2),
          AppButton(
            label: localCopy.frictionSave,
            busy: view.saving,
            expand: true,
            onPressed: () async {
              final Result<FeedbackEntry> result = await controller.save(
                context: origin,
                note: note.text,
                capture: capture,
              );
              if (context.mounted && result is Success<FeedbackEntry>) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
    );
  }
}

final Provider<TextEditingController> _noteProvider =
    Provider.autoDispose<TextEditingController>((Ref ref) {
      final TextEditingController controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });
