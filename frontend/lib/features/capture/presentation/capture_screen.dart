import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/inline_fields_section.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/templates/domain/field_def.dart';

/// Capture surface: context, tray, caption, identifier, inline fields, saves.
final class CaptureScreen extends ConsumerWidget {
  /// Creates the screen for [projectId].
  const CaptureScreen({
    required this.projectId,
    this.fields = const <FieldDef>[],
    this.onAddPhoto,
    this.onSaveRaw,
    this.onSaveAndAnalyse,
    this.headroom,
    super.key,
  });

  /// Open project.
  final String projectId;

  /// Template fields for the inline section.
  final List<FieldDef> fields;

  /// Opens camera / import.
  final VoidCallback? onAddPhoto;

  /// Raw save.
  final VoidCallback? onSaveRaw;

  /// Analyse save.
  final VoidCallback? onSaveAndAnalyse;

  /// Optional storage banner.
  final Widget? headroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CaptureSession session = ref.watch(
      captureControllerProvider(projectId),
    );
    final CaptureController controller = ref.read(
      captureControllerProvider(projectId).notifier,
    );

    final Widget tray = PhotoTray(
      photos: session.photos,
      captions: session.captions,
      onAdd: onAddPhoto ?? () {},
    );

    final Widget form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RecordCaptionField(
          value: session.recordCaption,
          onChanged: (String text) async {
            final result = await controller.setCaption(null, text);
            return result.fold((Failure _) => false, (_) => true);
          },
          onWriteFailed: (String _) {
            showAppSnack(
              context,
              Copy.captureSaveFailed,
              tone: SnackTone.error,
            );
          },
        ),
        const SizedBox(height: 8),
        InlineFieldsSection(
          fields: fields,
          values: session.values,
          onChanged: (String key, Object? value) {
            controller.setValue(key, value);
          },
        ),
      ],
    );

    final Widget saves = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: Copy.captureSaveRaw,
                variant: AppButtonVariant.secondary,
                onPressed: onSaveRaw,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: Copy.captureSaveAndAnalyse,
                onPressed: onSaveAndAnalyse,
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text(Copy.captureTitle)),
      body: Column(
        children: <Widget>[
          ?headroom,
          const ContextBar(),
          Expanded(
            child: ResponsiveBuilder(
              compact: (BuildContext _) => ListView(
                padding: const EdgeInsets.all(12),
                children: <Widget>[tray, const SizedBox(height: 12), form],
              ),
              medium: (BuildContext _) => Row(
                children: <Widget>[
                  Expanded(child: tray),
                  Expanded(child: SingleChildScrollView(child: form)),
                ],
              ),
              expanded: (BuildContext _) => Row(
                children: <Widget>[
                  Expanded(child: tray),
                  Expanded(child: SingleChildScrollView(child: form)),
                ],
              ),
            ),
          ),
          saves,
        ],
      ),
    );
  }
}
