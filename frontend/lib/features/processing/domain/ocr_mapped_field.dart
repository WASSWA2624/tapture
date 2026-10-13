/// A supported raw value, its typed derivative and its exact photo region.
typedef OcrMappedField = ({
  String fieldKey,
  String value,
  String normalised,
  int? blockIndex,
  String snippet,
  double confidence,
});
