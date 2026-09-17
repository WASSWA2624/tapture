/// The one allowed type name per specification concept (FE-CONS-07).
///
/// Near-synonyms — `RecordModel`, `PhotoItem`, `TemplateData` and the rest —
/// fail `frontend/test/architecture/naming_test.dart`.
abstract final class DomainNames {
  /// The container that owns templates, records and context.
  static const String project = 'Project';

  /// The shape of a record: its fields, requiredness and identity.
  static const String templateDef = 'TemplateDef';

  /// One column on a [templateDef].
  static const String fieldDef = 'FieldDef';

  /// One captured thing, with its evidence and field values.
  static const String recordEntry = 'RecordEntry';

  /// One value written onto a [recordEntry] for a [fieldDef].
  static const String fieldValue = 'FieldValue';

  /// The in-progress capture of one [recordEntry].
  static const String captureSession = 'CaptureSession';

  /// A photograph kept as evidence on a [recordEntry].
  static const String photoAsset = 'PhotoAsset';

  /// The values that apply to every new [recordEntry] until they change.
  static const String contextState = 'ContextState';

  /// An imported table used to prefill a [recordEntry].
  static const String referenceDataset = 'ReferenceDataset';

  /// One unit of on-device or online processing work.
  static const String processingJob = 'ProcessingJob';

  /// A project packaged to leave the device by hand.
  static const String bundle = 'Bundle';

  /// The work of joining a [bundle] back into a [project].
  static const String mergeSession = 'MergeSession';
}
