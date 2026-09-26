/// Keys capture sessions are stored and looked up under (D6).
///
/// A new capture is keyed by its project id, so a project keeps one
/// interrupted capture. Editing a saved record is keyed `edit:<recordId>`,
/// so an edit never overwrites the project's unsaved new capture.
abstract final class CaptureSessionKey {
  static const String _editPrefix = 'edit:';

  /// The key of the session that edits [recordId].
  static String edit(String recordId) => '$_editPrefix$recordId';

  /// Whether [key] belongs to a record edit.
  static bool isEdit(String key) => key.startsWith(_editPrefix);

  /// The record an edit [key] names, or null for a new-capture key.
  static String? recordOf(String key) {
    return isEdit(key) ? key.substring(_editPrefix.length) : null;
  }
}
