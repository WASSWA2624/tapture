import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';

/// Offers Take a photo, where the device has a camera, and Choose from this
/// device in one sheet, then runs the chosen pick through [picker]. Returns
/// null when the sheet is closed without a choice.
///
/// Capture and the project photo share this sheet (FBK0000154).
Future<Result<List<Uint8List>>?> showPhotoSourceSheet(
  BuildContext context, {
  required PhotoPicker picker,
  required int limit,
  required int longEdge,
}) async {
  final _Source? source = await showAppSheet<_Source>(
    context,
    title: Copy.captureAddSheetTitle,
    contentSized: true,
    builder: (BuildContext sheetContext) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (picker.canTakePhoto) ...<Widget>[
            AppButton(
              label: Copy.captureTakePhoto,
              icon: AppIcons.camera,
              expand: true,
              onPressed: () => Navigator.of(sheetContext).pop(_Source.camera),
            ),
            const SizedBox(height: Space.x2),
          ],
          AppButton(
            label: Copy.captureChoosePhoto,
            icon: AppIcons.photoLibrary,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(_Source.library),
          ),
        ],
      );
    },
  );
  return switch (source) {
    null => null,
    _Source.camera => picker.take(longEdge: longEdge),
    _Source.library => picker.choose(limit: limit, longEdge: longEdge),
  };
}

enum _Source { camera, library }
