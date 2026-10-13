import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

/// Advanced file options use the same request as the visible export controls.
final class ExportRequestExtras extends StatelessWidget {
  const ExportRequestExtras({
    required this.request,
    required this.onChanged,
    super.key,
  });

  final ExportRequest request;
  final ValueChanged<ExportRequest> onChanged;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy copy = Copy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.x3,
      children: <Widget>[
        AppSwitchTile(
          title: copy.exportDictionary,
          value: request.extras.dictionary,
          onChanged: (bool value) => _change(dictionary: value),
        ),
        AppChoiceField<String>(
          label: copy.exportPhotoMode,
          options: <Choice<String>>[
            Choice<String>('filename', copy.exportPhotoFilename),
            Choice<String>('relative', copy.exportPhotoRelative),
            Choice<String>('embed', copy.exportPhotoEmbed),
          ],
          value: request.extras.photoMode,
          onChanged: (String? value) => _change(photoMode: value),
        ),
        AppChoiceField<String>(
          label: copy.exportPdfPhotos,
          options: <Choice<String>>[
            Choice<String>(PdfPhotoLayout.thumbnail, copy.exportPdfThumbnails),
            Choice<String>(PdfPhotoLayout.full, copy.exportPdfFull),
          ],
          value: request.extras.pdfPhotos,
          onChanged: (String? value) => _change(pdfPhotos: value),
        ),
        AppChoiceField<String>(
          label: copy.exportDelimiter,
          options: <Choice<String>>[
            Choice<String>(',', copy.exportDelimiterComma),
            Choice<String>(';', copy.exportDelimiterSemicolon),
            Choice<String>('\t', copy.exportDelimiterTab),
          ],
          value: request.extras.delimiter,
          onChanged: (String? value) => _change(delimiter: value),
        ),
      ],
    );
  }

  void _change({
    bool? dictionary,
    String? photoMode,
    String? pdfPhotos,
    String? delimiter,
  }) {
    onChanged(
      request.copyWith(
        extras: (
          dictionary: dictionary ?? request.extras.dictionary,
          photoIndex: request.extras.photoIndex,
          photoMode: photoMode ?? request.extras.photoMode,
          pdfPhotos: pdfPhotos ?? request.extras.pdfPhotos,
          delimiter: delimiter ?? request.extras.delimiter,
        ),
      ),
    );
  }
}
