/// The templates feature: the templates a capture is shaped by.
library;

export 'data/shipped_template_loader.dart'
    show shippedTemplateLoaderProvider, ShippedTemplateLoader;
export 'data/template_json.dart' show TemplateJson;
export 'data/template_repository_impl.dart' show templateRepositoryProvider;
export 'data/xlsx_template_import.dart' show XlsxTemplateImport;
export 'domain/field_def.dart';
export 'domain/field_type_registry.dart';
export 'domain/template_def.dart';
export 'domain/template_row.dart';
export 'domain/template_version.dart';
export 'domain/template_versioning.dart';
export 'presentation/field_editor_bindings.dart'
    show fieldEditorField, templateFieldEditorBindings;
