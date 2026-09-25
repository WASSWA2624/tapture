/// Which template a capture uses, from one rule shared by the capture page
/// and the project home (FE-STATE-06, FE-SIMP-05).
abstract final class CaptureTemplateChoice {
  /// The template id capture should use, or null while the person must pick.
  ///
  /// In order: the template chosen on the home, then the one already on the
  /// capture session, then the project's first template when its template
  /// choice setting is automatic ([choice] null, and also `'auto'`). A
  /// project set to `'manual'` or `'suggest'` waits for a pick. Ids that do
  /// not belong to [templateIds] never win, so another project's template is
  /// never applied.
  static String? resolve({
    required List<String> templateIds,
    required String selection,
    required String sessionTemplateId,
    required String? choice,
  }) {
    if (templateIds.contains(selection)) {
      return selection;
    }
    if (templateIds.contains(sessionTemplateId)) {
      return sessionTemplateId;
    }
    if (templateIds.isNotEmpty && (choice == null || choice == _auto)) {
      return templateIds.first;
    }
    return null;
  }
}

const String _auto = 'auto';
