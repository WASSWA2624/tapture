import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/bundle/bundle_privacy.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/ids.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/meetings/data/meeting_repository_impl.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/domain/meeting_repository.dart';
import 'package:tapture/features/merge/data/package_files.dart';
import 'package:tapture/features/merge/data/package_import_repository_impl.dart';
import 'package:tapture/features/merge/domain/domain.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show Transcript, TranscriptRepositoryImpl;

import '../../support/bundle_fixture.dart';

/// Raw words a person said, with characters a careless encoder would bend.
const List<String> _heard = <String>[
  'Pump 3 — leaking at 2.5 bar',
  'naïve café ½ turn, “quoted”',
  '  spaces kept  ',
];

void main() {
  late BundleFixture source;
  late sqlite.AppDatabase target;
  late Directory targetDocuments;

  setUp(() async {
    source = await seedProjectForBundle();
    target = sqlite.AppDatabase.memory();
    targetDocuments = Directory.systemTemp.createTempSync('tapture-trip-');
    await _seedTranscripts(source);
  });

  tearDown(() async {
    await source.db.close();
    await target.close();
    for (final Directory folder in <Directory>[
      source.root.parent,
      targetDocuments,
    ]) {
      if (folder.existsSync()) {
        folder.deleteSync(recursive: true);
      }
    }
  });

  test('a package carries finished transcripts and their segments with the '
      'raw text unchanged, and imports them row for row', () async {
    final InspectedBundle bundle = await _package(source);

    expect(
      bundle.rowsOf('transcripts').map((Map<String, Object?> r) => r['id']),
      <String>['t-done'],
    );
    expect(<Object?>[
      for (final Map<String, Object?> row in bundle.rowsOf(
        'transcript_segments',
      ))
        row['text_raw'],
    ], _heard);
    expect(
      bundle.manifest.versionVectors['transcripts']?['t-done'],
      <String, int>{'device-a': 2},
    );
    expect(
      bundle.manifest.versionVectors['transcript_segments']?.keys,
      unorderedEquals(<String>['seg-1', 'seg-2', 'seg-3']),
    );
    final Archive archive = ZipDecoder().decodeBytes(_written!);
    final Map<String, Object?> entry =
        jsonDecode(
              utf8.decode(
                archive.findFile('transcripts.json')!.content as List<int>,
              ),
            )
            as Map<String, Object?>;
    expect(entry.keys, <String>['transcripts', 'transcript_segments']);

    final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 4, 10));
    final ImportedProject imported = _ok(
      await PackageImportRepositoryImpl(
        db: target,
        files: PackageFiles(
          storageRoot: StorageRoot.fake(documentsDirectory: targetDocuments),
        ),
        clock: clock,
        deviceId: 'device-b',
        ids: UuidV7Service.sequence(clock),
      ).importAsNew(bundle),
    );
    expect(imported.projectId, source.projectId);
    for (final String table in <String>['transcripts', 'transcript_segments']) {
      expect(
        await _rows(target, table),
        await _rows(source.db, table, onlyFinished: true),
        reason: table,
      );
    }
    final Transcript read = _ok(
      await TranscriptRepositoryImpl(
        db: target,
        clock: clock,
        deviceId: 'device-b',
        ids: UuidV7Service.sequence(clock),
      ).read('t-done'),
    )!;
    expect(read.lines.map((line) => line.text), _heard);
    expect(read.editedText, 'Pump 3 is leaking.');
    final List<QueryRow> clocks = await target
        .customSelect(
          'SELECT device_id, seen_rev FROM version_vectors '
          "WHERE entity_type = 'transcripts' AND entity_id = 't-done'",
        )
        .get();
    expect(
      clocks.map(
        (QueryRow r) => '${r.data['device_id']}=${r.data['seen_rev']}',
      ),
      <String>['device-a=2'],
    );
  });

  test(
    'meeting original notes and working edits survive a package roundtrip',
    () async {
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 7, 9));
      MeetingRepositoryImpl meetings(sqlite.AppDatabase db) =>
          MeetingRepositoryImpl(
            db: db,
            clock: clock,
            deviceId: 'device-a',
            ids: UuidV7Service.sequence(clock),
          );
      final String template =
          (await source.db
                  .customSelect('SELECT id FROM templates LIMIT 1')
                  .getSingle())
              .read<String>('id');
      final MeetingRepositoryImpl repository = meetings(source.db);
      final MeetingRecord original = _ok(
        await repository.save(
          Meeting(
            id: 'meeting-notes',
            projectId: source.projectId,
            title: 'Site notes',
            startedAt: clock.nowUtc(),
          ),
          recordId: 'record-meeting',
          templateId: template,
          notes: '  Original café notes\nSecond line.  ',
          transcript: 'Words as heard',
        ),
      );
      _ok(
        await repository.save(
          original.meeting,
          recordId: 'record-meeting',
          notes: 'Corrected working notes',
          minutes: 'Reviewed minutes',
        ),
      );
      final InspectedBundle bundle = await _package(source);
      _ok(
        await PackageImportRepositoryImpl(
          db: target,
          files: PackageFiles(
            storageRoot: StorageRoot.fake(documentsDirectory: targetDocuments),
          ),
          clock: clock,
          deviceId: 'device-b',
          ids: UuidV7Service.sequence(clock),
        ).importAsNew(bundle),
      );
      final MeetingRecord imported = _ok(
        await meetings(target).read('meeting-notes'),
      )!;
      expect(imported.originalNotes, original.notes);
      expect(imported.notes, 'Corrected working notes');
      expect(imported.minutes, 'Reviewed minutes');
      expect(imported.transcript, original.transcript);
      expect(
        await _rows(target, 'meetings'),
        await _rows(source.db, 'meetings'),
      );
      expect(
        (await _rows(
          target,
          'audit_log',
        )).where((row) => row['entity_id'] == 'meeting-notes'),
        (await _rows(
          source.db,
          'audit_log',
        )).where((row) => row['entity_id'] == 'meeting-notes'),
      );
    },
  );

  test('a consent-scoped package carries a transcript only with its '
      "record's audio", () async {
    final BundleTables tables = (await BundleTables.read(
      source.db,
      source.projectId,
    ))!;
    final String recordId =
        (await source.db
                    .customSelect(
                      "SELECT owner_id FROM attachment_owners WHERE id = 'owner-1'",
                    )
                    .getSingle())
                .data['owner_id']!
            as String;

    final BundleTables allowed = BundlePrivacy(
      recordIds: <String>{recordId},
    ).apply(tables);
    final BundleTables excluded = const BundlePrivacy(
      recordIds: <String>{},
    ).apply(tables);

    expect(
      allowed.rows['transcripts']!.map((Map<String, Object?> r) => r['id']),
      <String>['t-done'],
    );
    expect(allowed.rows['transcript_segments'], hasLength(_heard.length));
    expect(excluded.rows['transcripts'], isEmpty);
    expect(excluded.rows['transcript_segments'], isEmpty);
    expect(
      excluded.rows['audit_log']!.where(
        (Map<String, Object?> r) => r['entity_type'] == 'transcripts',
      ),
      isEmpty,
    );
  });

  test('a package written before transcripts travelled still reads', () async {
    final InspectedBundle bundle = await _package(source);
    final Uint8List withoutTranscripts = _withoutEntry(
      _written!,
      'transcripts.json',
    );
    final File older = File('${targetDocuments.path}/older.zip')
      ..writeAsBytesSync(withoutTranscripts);

    final InspectedBundle read = _ok(
      await BundleReader.inspect(
        PickedFile(older, 'older.zip', older.lengthSync()),
      ),
    );
    addTearDown(read.close);

    expect(read.rowsOf('transcripts'), isEmpty);
    expect(read.rowsOf('records'), bundle.rowsOf('records'));
    expect(BundleFormat.requiredEntries, isNot(contains('transcripts.json')));
  });
}

/// The bytes of the last package [_package] wrote.
Uint8List? _written;

/// A finished, edited transcript of a record's audio with three raw
/// segments, a live one, and a finished one of another project.
Future<void> _seedTranscripts(BundleFixture fixture) async {
  final sqlite.AppDatabase db = fixture.db;
  final String recordId =
      (await db.customSelect('SELECT id FROM records ORDER BY id').get())
              .first
              .data['id']!
          as String;
  final Uint8List audio = Uint8List.fromList(utf8.encode('RIFF-take'));
  const String path = 'audio/take-1.wav';
  File('${fixture.root.path}/projects/${fixture.folderName}/$path')
    ..createSync(recursive: true)
    ..writeAsBytesSync(audio);
  await _insert(db, 'attachments', <String, Object?>{
    'id': 'audio-1',
    'project_id': fixture.projectId,
    'relative_path': path,
    'mime_type': 'audio/wav',
    'file_size': audio.length,
    'sha256': crypto.sha256.convert(audio).toString(),
    'kind': 'audio',
  });
  await _insert(db, 'attachment_owners', <String, Object?>{
    'id': 'owner-1',
    'attachment_id': 'audio-1',
    'owner_type': 'record',
    'owner_id': recordId,
  });
  Map<String, Object?> transcript(String id, String status, String project) =>
      <String, Object?>{
        'id': id,
        'project_id': project,
        'owner_kind': 'capture',
        'attachment_id': id == 't-done' ? 'audio-1' : null,
        'audio_path': 'projects/${fixture.folderName}/$path',
        'title': 'Pump room',
        'language_tag': 'en',
        'model_id': 'tiny-q5_1',
        'status': status,
        'started_at': 1759572000,
        'ended_at': 1759572060,
        'duration_ms': 60000,
        'covered_ms': 60000,
        'skipped_ranges': '[[40000,42000]]',
        'text_edited': 'Pump 3 is leaking.',
        'edited_at': 1759572100,
        'rev': 2,
      };
  await _insert(
    db,
    'transcripts',
    transcript('t-done', 'complete', fixture.projectId),
  );
  await _insert(
    db,
    'transcripts',
    transcript('t-live', 'live', fixture.projectId),
  );
  await _insert(db, 'transcripts', transcript('t-other', 'complete', 'other'));
  for (int index = 0; index < _heard.length; index++) {
    await _insert(db, 'transcript_segments', <String, Object?>{
      'id': 'seg-${index + 1}',
      'transcript_id': 't-done',
      'seq': index + 1,
      'start_ms': index * 2000,
      'end_ms': index * 2000 + 1800,
      'text_raw': _heard[index],
      'confidence': 0.5 + index / 10,
    });
  }
  await _insert(db, 'transcript_segments', <String, Object?>{
    'id': 'seg-live',
    'transcript_id': 't-live',
    'seq': 1,
    'start_ms': 0,
    'end_ms': 900,
    'text_raw': 'still talking',
  });
  await _insert(db, 'transcript_segments', <String, Object?>{
    'id': 'seg-other',
    'transcript_id': 't-other',
    'seq': 1,
    'start_ms': 0,
    'end_ms': 900,
    'text_raw': 'another project',
  });
}

/// Inserts [values] into [table] as an authored row of `device-a`.
Future<void> _insert(
  sqlite.AppDatabase db,
  String table,
  Map<String, Object?> values,
) {
  final Map<String, Object?> row = <String, Object?>{
    'created_at': 1759572000,
    'updated_at': 1759572000,
    'updated_by_device': 'device-a',
    'rev': 1,
    ...values,
  };
  return db.customStatement(
    'INSERT INTO $table (${row.keys.join(', ')}) '
    'VALUES (${List<String>.filled(row.length, '?').join(', ')})',
    row.values.toList(),
  );
}

/// [table]'s rows ordered by id; [onlyFinished] keeps this project's
/// finished transcripts and their segments, as a package carries them.
Future<List<Map<String, Object?>>> _rows(
  sqlite.AppDatabase db,
  String table, {
  bool onlyFinished = false,
}) async {
  final String where = !onlyFinished
      ? ''
      : table == 'transcripts'
      ? "WHERE id = 't-done'"
      : "WHERE transcript_id = 't-done'";
  return <Map<String, Object?>>[
    for (final QueryRow row
        in await db
            .customSelect('SELECT * FROM $table $where ORDER BY id')
            .get())
      Map<String, Object?>.of(row.data),
  ];
}

Future<InspectedBundle> _package(BundleFixture fixture) async {
  final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 4, 9));
  final BundleWriter writer = BundleWriter(
    db: fixture.db,
    storageRoot: fixture.storageRoot,
    files: FileReader(storageRoot: fixture.storageRoot),
    clock: clock,
    ids: UuidV7Service.sequence(clock),
    deviceId: 'device-test',
    device: () async => const DeviceDescriptor.fake(),
    inBrowser: false,
  );
  final StoredBundle stored =
      _ok(
            await writer.write(
              projectId: fixture.projectId,
              cancel: CancellationToken(),
            ),
          )
          as StoredBundle;
  final File file = File('${fixture.root.path}/${stored.relativePath}');
  _written = file.readAsBytesSync();
  final InspectedBundle bundle = _ok(
    await BundleReader.inspect(PickedFile(file, 'trip.zip', file.lengthSync())),
  );
  addTearDown(bundle.close);
  return bundle;
}

/// [package] without [path], its checksum line and its manifest entry, as
/// a writer from before [path] existed produced it.
Uint8List _withoutEntry(Uint8List package, String path) {
  final Archive source = ZipDecoder().decodeBytes(package);
  final List<int> checksums = utf8.encode(
    utf8
        .decode(source.findFile(BundleFormat.checksums)!.content as List<int>)
        .split('\n')
        .where((String line) => !line.endsWith('  $path'))
        .join('\n'),
  );
  final Map<String, Object?> manifest =
      jsonDecode(
            utf8.decode(
              source.findFile(BundleFormat.manifest)!.content as List<int>,
            ),
          )
          as Map<String, Object?>;
  manifest['entries'] = <Object?>[
    for (final Map<String, Object?> entry
        in (manifest['entries']! as List<Object?>).cast<Map<String, Object?>>())
      if (entry['path'] == BundleFormat.checksums)
        <String, Object?>{
          ...entry,
          'byte_length': checksums.length,
          'sha256': crypto.sha256.convert(checksums).toString(),
        }
      else if (entry['path'] != path)
        entry,
  ];
  final Archive rebuilt = Archive();
  for (final ArchiveFile file in source.files) {
    if (file.name == path) continue;
    final List<int> bytes = switch (file.name) {
      BundleFormat.checksums => checksums,
      BundleFormat.manifest => utf8.encode(jsonEncode(manifest)),
      _ => file.content as List<int>,
    };
    rebuilt.addFile(ArchiveFile(file.name, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(rebuilt)!);
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
