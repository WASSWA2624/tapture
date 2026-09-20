import 'template_def.dart';

/// A template after one structural bump from [TemplateRepository.save].
final class TemplateVersion {
  /// Creates a version pointing at the stored [template].
  const TemplateVersion({required this.template});

  /// The template at this version.
  final TemplateDef template;

  /// Structural version number captured records keep.
  int get number => template.version;
}
