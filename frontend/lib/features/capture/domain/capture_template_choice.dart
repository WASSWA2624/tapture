import 'package:tapture/features/templates/domain/domain.dart';

/// Which template a capture uses, from one rule shared by the capture page
/// and the project home (FE-STATE-06, FE-SIMP-05).
abstract final class CaptureTemplateChoice {
  /// The template id capture should use, or null while the person must pick.
  ///
  /// In order: the template picked for this session ([selection]), then the
  /// one pinned to the current context level ([contextPin], spec section
  /// 14), then the one already on the capture session, then the project's
  /// first template when its template choice setting is automatic ([choice]
  /// null, and also `'auto'`). A project set to `'manual'` or `'suggest'`
  /// waits for a pick. Ids that do not belong to [templateIds] never win, so
  /// another project's template is never applied.
  static String? resolve({
    required List<String> templateIds,
    required String selection,
    required String sessionTemplateId,
    required String? choice,
    String? contextPin,
  }) {
    if (templateIds.contains(selection)) {
      return selection;
    }
    if (contextPin != null && templateIds.contains(contextPin)) {
      return contextPin;
    }
    if (templateIds.contains(sessionTemplateId)) {
      return sessionTemplateId;
    }
    if (templateIds.isNotEmpty && (choice == null || choice == _auto)) {
      return templateIds.first;
    }
    return null;
  }

  /// [templates] in the order capture offers them: the ones in [recentIds]
  /// first, most recently used first, then the rest by name (task 012 step
  /// 22). Ids in [recentIds] that are not in [templates] are ignored.
  static List<TemplateDef> ordered(
    List<TemplateDef> templates, {
    required List<String> recentIds,
  }) {
    final Map<String, int> rank = <String, int>{
      for (int index = 0; index < recentIds.length; index++)
        recentIds[index]: index,
    };
    return List<TemplateDef>.of(templates)
      ..sort((TemplateDef a, TemplateDef b) {
        final int? left = rank[a.id];
        final int? right = rank[b.id];
        if (left != null && right != null) {
          return left.compareTo(right);
        }
        if (left != null) {
          return -1;
        }
        if (right != null) {
          return 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }
}

const String _auto = 'auto';
