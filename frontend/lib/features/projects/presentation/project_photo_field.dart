import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/photo_source_sheet.dart';

import '../domain/project_repository.dart';
import 'record_thumb.dart';

/// The optional project photo on the create and edit screens: a preview,
/// Add or Change, and Remove (FBK0000154). Not built on the web, which
/// stores no files (D7).
class ProjectPhotoField extends ConsumerWidget {
  /// Creates the field. [stored] is the saved photo; [pending] is one chosen
  /// before the project exists.
  const ProjectPhotoField({
    required this.onPicked,
    this.stored,
    this.pending,
    this.onRemove,
    this.busy = false,
    super.key,
  });

  /// The project's saved photo, if it has one.
  final ProjectCoverPhoto? stored;

  /// A photo chosen but not stored yet.
  final Uint8List? pending;

  /// Called with the picked photo.
  final ValueChanged<Uint8List> onPicked;

  /// Takes the photo off. Null hides Remove.
  final VoidCallback? onRemove;

  /// While a photo is being stored, the actions wait.
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    final double edge = AppConstants.images.thumbnailEdge.toDouble();
    final Uint8List? chosen = pending;
    final ProjectCoverPhoto? saved = stored;
    final Widget? preview = chosen != null
        ? ClipRRect(
            key: const ValueKey<String>('project-photo-pending'),
            borderRadius: BorderRadius.circular(Radii.sm),
            child: Image.memory(
              chosen,
              width: edge,
              height: edge,
              fit: BoxFit.cover,
              cacheWidth: AppConstants.images.previewEdge,
              semanticLabel: Copy.projectPhoto,
            ),
          )
        : saved != null
        ? RecordThumb(
            key: const ValueKey<String>('project-photo-stored'),
            photo: (
              sha256: saved.sha256,
              storagePath: saved.path,
              quarterTurns: 0,
            ),
            size: edge,
          )
        : null;
    final bool has = preview != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(Copy.projectPhoto, style: AppText.label),
        const SizedBox(height: Space.x1),
        if (preview != null) ...<Widget>[
          preview,
          const SizedBox(height: Space.x2),
        ],
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x1,
          children: <Widget>[
            AppButton(
              label: has ? Copy.projectPhotoChange : Copy.projectPhotoAdd,
              icon: AppIcons.addPhoto,
              variant: AppButtonVariant.secondary,
              busy: busy,
              onPressed: busy ? null : () => unawaited(_pick(context, ref)),
            ),
            if (has && onRemove != null)
              AppButton(
                label: Copy.projectPhotoRemove,
                icon: AppIcons.delete,
                variant: AppButtonVariant.text,
                onPressed: busy ? null : onRemove,
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final Result<List<Uint8List>>? picked = await showPhotoSourceSheet(
      context,
      picker: ref.read(photoPickerProvider),
      limit: 1,
      longEdge: AppConstants.images.longEdge,
    );
    if (picked == null || !context.mounted) {
      return;
    }
    switch (picked) {
      case FailureResult<List<Uint8List>>(:final Failure failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
      case Success<List<Uint8List>>(:final List<Uint8List> value):
        if (value.isNotEmpty) {
          onPicked(value.first);
        }
    }
  }
}
