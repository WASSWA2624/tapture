/// The existing project-name rule, shared by forms and persistence.
abstract final class ProjectNameValidation {
  /// Names need non-whitespace text; spelling and punctuation stay user-owned.
  static bool isValid(String name) => name.trim().isNotEmpty;
}
