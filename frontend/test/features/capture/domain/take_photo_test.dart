import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/take_photo.dart';

import '../../../support/fakes/fake_file_writer.dart';
import '../../../support/fakes/fake_id_service.dart';
import '../../../support/matchers.dart';

/// Task 012 budget: shutter to ready is under 400 ms (FE-PERF-01,
/// FE-TEST-09).
const Duration _shutterBudget = Duration(milliseconds: 400);

/// [length] bytes that differ from every other [seed].
Uint8List _frame(int seed, {int length = 64}) {
  return Uint8List.fromList(<int>[
    for (var i = 0; i < length; i++) (i * 7 + seed) & 0xFF,
  ]);
}

Future<Result<PhotoDraft>> _shoot(
  FakeFileWriter writer,
  FakeIdService ids, {
  Uint8List? bytes,
  String relativePath = 'projects/site/photos/img-1.jpg',
  String photoType = 'other',
  int sortOrder = 0,
  String originalFilename = '',
}) {
  return TakePhoto.write(
    bytes: bytes ?? _frame(1),
    relativePath: relativePath,
    projectId: 'p1',
    sessionId: 's1',
    writer: writer,
    ids: ids,
    photoType: photoType,
    sortOrder: sortOrder,
    originalFilename: originalFilename,
  );
}

void main() {
  test('a shutter press writes the bytes and hashes what landed', () async {
    final FakeFileWriter writer = FakeFileWriter();
    final Uint8List bytes = _frame(1);

    final PhotoDraft draft = valueOf(
      await _shoot(writer, FakeIdService(), bytes: bytes),
    );

    expect(writer.files['projects/site/photos/img-1.jpg'], bytes);
    expect(draft.sha256, sha256.convert(bytes).toString());
    expect(draft.relativePath, 'projects/site/photos/img-1.jpg');
    expect(draft.fileSize, bytes.length);
    expect(draft.mimeType, 'image/jpeg');
    expect(draft.projectId, 'p1');
  });

  test('the draft takes its id from the id service', () async {
    final PhotoDraft draft = valueOf(
      await _shoot(FakeFileWriter(), FakeIdService(prefix: 'photo')),
    );

    expect(draft.id, 'photo-1');
  });

  test('the original filename defaults to the last path segment', () async {
    final PhotoDraft draft = valueOf(
      await _shoot(FakeFileWriter(), FakeIdService()),
    );

    expect(draft.originalFilename, 'img-1.jpg');
  });

  test('an explicit filename, type and order are kept on the draft', () async {
    final PhotoDraft draft = valueOf(
      await _shoot(
        FakeFileWriter(),
        FakeIdService(),
        originalFilename: 'IMG_0042.jpg',
        photoType: 'serial',
        sortOrder: 4,
      ),
    );

    expect(draft.originalFilename, 'IMG_0042.jpg');
    expect(draft.photoType, 'serial');
    expect(draft.sortOrder, 4);
  });

  test('a failed write returns the storage failure and mints no id', () async {
    final FakeFileWriter writer = FakeFileWriter()
      ..failure = const StorageFailure(
        message: 'There is not enough space.',
        recoveryAction: 'Free up space.',
      );
    final FakeIdService ids = FakeIdService();

    final Result<PhotoDraft> result = await _shoot(writer, ids);

    expect(result, isFailure<PhotoDraft, StorageFailure>());
    expect(writer.files, isEmpty);
    expect(ids.minted, 0);
  });

  test(
    'ten rapid shots produce ten files and ten drafts with distinct hashes '
    'in shutter order',
    () async {
      final FakeFileWriter writer = FakeFileWriter();
      final FakeIdService ids = FakeIdService();

      final List<PhotoDraft> drafts = <PhotoDraft>[];
      for (var shot = 1; shot <= 10; shot++) {
        drafts.add(
          valueOf(
            await _shoot(
              writer,
              ids,
              bytes: _frame(shot),
              relativePath: 'photos/img-$shot.jpg',
              sortOrder: shot - 1,
            ),
          ),
        );
      }

      expect(writer.files, hasLength(10));
      expect(writer.writes, <String>[
        for (var shot = 1; shot <= 10; shot++) 'photos/img-$shot.jpg',
      ]);
      expect(drafts.map((PhotoDraft d) => d.sha256).toSet(), hasLength(10));
      expect(drafts.map((PhotoDraft d) => d.id), <String>[
        for (var shot = 1; shot <= 10; shot++) 'id-$shot',
      ]);
      expect(drafts.map((PhotoDraft d) => d.sortOrder), <int>[
        for (var shot = 0; shot < 10; shot++) shot,
      ]);
    },
  );

  test('a one-megabyte frame is written and hashed inside the 400 ms shutter '
      'budget', () async {
    final Uint8List frame = _frame(3, length: 1 << 20);
    final Stopwatch clock = Stopwatch()..start();

    final PhotoDraft draft = valueOf(
      await _shoot(FakeFileWriter(), FakeIdService(), bytes: frame),
    );
    clock.stop();

    expect(draft.fileSize, 1 << 20);
    expect(clock.elapsed, lessThan(_shutterBudget));
  });
}
