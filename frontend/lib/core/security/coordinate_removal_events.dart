import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coordinate_policy.dart';

/// Announces a committed location removal to live project drafts.
final class CoordinateRemovalEvents extends Notifier<CoordinateRemoval?> {
  @override
  CoordinateRemoval? build() => null;

  /// Publishes synchronously after the database transaction has committed.
  void publish(String projectId, Map<String, Set<String>> keysByTemplate) {
    publishRemoval((
      projectId: projectId,
      keysByTemplate: keysByTemplate,
      currentFields: const <String, Set<String>>{},
      fieldHistory: const <String, Map<int, Set<String>>>{},
      currentVersions: const <String, int>{},
      recordPriorVersions: const <String, Set<int>>{},
    ));
  }

  /// Keeps captured-version policies immutable across asynchronous draft writes.
  void publishRemoval(CoordinateRemoval removal) {
    state = (
      projectId: removal.projectId,
      keysByTemplate: _immutableFields(removal.keysByTemplate),
      currentFields: _immutableFields(removal.currentFields),
      fieldHistory: Map<String, Map<int, Set<String>>>.unmodifiable({
        for (final MapEntry<String, Map<int, Set<String>>> template
            in removal.fieldHistory.entries)
          template.key: Map<int, Set<String>>.unmodifiable({
            for (final MapEntry<int, Set<String>> version
                in template.value.entries)
              version.key: Set<String>.unmodifiable(version.value),
          }),
      }),
      currentVersions: Map<String, int>.unmodifiable(removal.currentVersions),
      recordPriorVersions: Map<String, Set<int>>.unmodifiable({
        for (final MapEntry<String, Set<int>> entry
            in removal.recordPriorVersions.entries)
          entry.key: Set<int>.unmodifiable(entry.value),
      }),
    );
  }
}

/// Classified coordinate fields in the project whose stored GPS was removed.
typedef CoordinateRemoval = ({
  String projectId,
  Map<String, Set<String>> keysByTemplate,
  Map<String, Set<String>> currentFields,
  Map<String, Map<int, Set<String>>> fieldHistory,
  Map<String, int> currentVersions,
  Map<String, Set<int>> recordPriorVersions,
});

/// Resolves live and restored drafts with the same policy as durable records.
extension CoordinateRemovalFields on CoordinateRemoval {
  /// Keeps newer ordinary names while clearing the draft's captured GPS shape.
  Set<String> keysFor(
    String templateId,
    int? capturedVersion, {
    String? recordId,
  }) {
    if (!currentVersions.containsKey(templateId)) {
      return keysByTemplate[templateId] ?? const <String>{};
    }
    return CoordinatePolicy.withMigrationHistory(
      current: CoordinatePolicy.forVersion(
        current: currentFields[templateId] ?? const <String>{},
        history: fieldHistory[templateId] ?? const <int, Set<String>>{},
        currentVersion: currentVersions[templateId]!,
        capturedVersion: capturedVersion,
      ),
      history: fieldHistory[templateId] ?? const <int, Set<String>>{},
      currentVersion: currentVersions[templateId]!,
      previousVersions: recordPriorVersions[recordId] ?? const <int>{},
    );
  }
}

Map<String, Set<String>> _immutableFields(Map<String, Set<String>> fields) =>
    Map<String, Set<String>>.unmodifiable({
      for (final MapEntry<String, Set<String>> entry in fields.entries)
        entry.key: Set<String>.unmodifiable(entry.value),
    });

/// Live capture listens without replacing or losing unrelated draft contents.
final coordinateRemovalEventsProvider =
    NotifierProvider<CoordinateRemovalEvents, CoordinateRemoval?>(
      CoordinateRemovalEvents.new,
    );
