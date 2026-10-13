import 'ocr_mapped_field.dart';

/// Labelled keys prevent an invalid labelled value taking an unrelated fallback.
typedef OcrMappingOutcome = ({
  List<OcrMappedField> candidates,
  Set<String> labelledKeys,
  List<String> findings,
});
