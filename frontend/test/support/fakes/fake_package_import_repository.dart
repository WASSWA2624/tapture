import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/merge/domain/domain.dart';
import 'package:tapture/features/quality/quality.dart'
    hide ConflictChoice, FieldConflict;

/// In-memory [PackageImportRepository] for screen tests that must not open
/// a database: [local] is every project's rows by project id, and each
/// merge is recorded in [merges] instead of written.
final class FakePackageImportRepository implements PackageImportRepository {
  /// Creates the fake over [local].
  FakePackageImportRepository({
    Map<String, Map<String, List<Map<String, Object?>>>>? local,
    this.presence = PackagePresence.absent,
  }) : local = local ?? <String, Map<String, List<Map<String, Object?>>>>{};

  /// Each project's rows, by SQL table.
  final Map<String, Map<String, List<Map<String, Object?>>>> local;

  /// What [presenceOf] answers.
  PackagePresence presence;

  /// Every merge applied, with its choices.
  final List<
    ({
      String projectId,
      MergePlan plan,
      Map<String, ConflictChoice> choices,
      List<PossibleDuplicate> duplicates,
      Set<String> skipped,
      String chooser,
    })
  >
  merges =
      <
        ({
          String projectId,
          MergePlan plan,
          Map<String, ConflictChoice> choices,
          List<PossibleDuplicate> duplicates,
          Set<String> skipped,
          String chooser,
        })
      >[];

  /// Packages imported as new projects.
  final List<String> imported = <String>[];

  @override
  Future<Result<PackagePresence>> presenceOf(String projectId) async {
    return Success<PackagePresence>(presence);
  }

  @override
  Future<Result<MergeGround>> groundFor({
    required String projectId,
    required Map<String, List<Map<String, Object?>>> incoming,
  }) async {
    return Success<MergeGround>((
      local: local[projectId] ?? <String, List<Map<String, Object?>>>{},
      elsewhere: const <String, Set<String>>{},
      decided: const <String>{},
    ));
  }

  @override
  Future<Result<Map<String, List<Map<String, Object?>>>>> templatesOf(
    String projectId,
  ) async {
    final Map<String, List<Map<String, Object?>>> tables =
        local[projectId] ?? <String, List<Map<String, Object?>>>{};
    return Success<Map<String, List<Map<String, Object?>>>>(<
      String,
      List<Map<String, Object?>>
    >{
      'templates': tables['templates'] ?? <Map<String, Object?>>[],
      'template_fields': tables['template_fields'] ?? <Map<String, Object?>>[],
    });
  }

  @override
  Future<Result<ImportedProject>> importAsNew(
    InspectedBundle bundle, {
    void Function(double progress)? onProgress,
  }) async {
    imported.add(bundle.manifest.projectId);
    return Success<ImportedProject>((
      projectId: bundle.manifest.projectId,
      records: bundle.rowsOf('records').length,
    ));
  }

  @override
  Future<Result<MergeOutcome>> merge({
    required InspectedBundle bundle,
    required String projectId,
    required MergePlan plan,
    required Map<String, ConflictChoice> choices,
    required List<PossibleDuplicate> duplicates,
    required Set<String> skipped,
    required String chooser,
    void Function(double progress)? onProgress,
  }) async {
    for (final FieldConflict conflict in plan.conflicts) {
      if (!choices.containsKey(conflict.id)) {
        return const FailureResult<MergeOutcome>(
          ValidationFailure(message: 'unsettled', recoveryAction: 'settle'),
        );
      }
    }
    merges.add((
      projectId: projectId,
      plan: plan,
      choices: choices,
      duplicates: duplicates,
      skipped: skipped,
      chooser: chooser,
    ));
    return Success<MergeOutcome>((
      sessionId: 'session-${merges.length}',
      records: plan.counts.newRecords,
    ));
  }
}

/// An opened package holding [tables], as [BundleReader] would hand it
/// over, for project [projectId].
InspectedBundle openedPackage(
  Map<String, List<Map<String, Object?>>> tables, {
  String projectId = 'p1',
  String projectName = 'Pumps',
}) {
  return InspectedBundle(
    manifest: BundleManifest(
      formatVersion: BundleFormat.version,
      appVersion: '1.0.0',
      schemaVersion: 1,
      bundleId: 'bundle-1',
      projectId: projectId,
      projectName: projectName,
      folderName: 'pumps',
      exportedAt: DateTime.utc(2026, 9, 27, 9),
      sourceDeviceId: 'device-b',
      operatorName: 'Ben',
      counts: <String, int>{
        'records': tables['records']?.length ?? 0,
        'photos': tables['photos']?.length ?? 0,
      },
      lineage: const <({String device, DateTime at})>[],
      templates: const <BundleTemplateSummary>[],
      entries: const <BundleEntry>[],
    ),
    tables: tables,
    name: 'pumps.zip',
    readEntry: (String path) async =>
        Success<Uint8List>(Uint8List.fromList(utf8.encode(path))),
    close: () async {},
  );
}
