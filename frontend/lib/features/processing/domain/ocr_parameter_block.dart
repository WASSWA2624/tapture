/// One OCR region in source-pixel coordinates; domain has no platform types.
typedef OcrParameterBlock = ({
  String text,
  double left,
  double top,
  double right,
  double bottom,
  double confidence,
});
