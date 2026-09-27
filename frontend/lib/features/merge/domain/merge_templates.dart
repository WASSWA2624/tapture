/// Template versions merge without rewriting a record's captured version.
final class MergeTemplates {
  /// Same version is no action. Different versions offer choose one or keep
  /// both. [capturedVersion] is returned unchanged either way.
  static TemplateMerge resolve({
    required int localVersion,
    required int incomingVersion,
    required int capturedVersion,
    required bool keepBoth,
  }) {
    if (localVersion == incomingVersion) {
      return (action: TemplateAction.same, recordVersion: capturedVersion);
    }
    return (
      action: keepBoth ? TemplateAction.keepBoth : TemplateAction.chooseOne,
      recordVersion: capturedVersion,
    );
  }
}

/// What to do with two template versions.
enum TemplateAction { same, chooseOne, keepBoth }

/// The decision and the version the record keeps.
typedef TemplateMerge = ({TemplateAction action, int recordVersion});
