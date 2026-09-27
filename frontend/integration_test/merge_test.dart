import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle_reader.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/features/merge/domain/merge_undo.dart';
import 'package:tapture/features/records/domain/record_entry.dart';

import '../test/support/matchers.dart';
import 'support/harness.dart';

void main() {
  test('re-importing a bundle changes nothing and undo restores the snapshot', () async {
    final TestApp source = await bootTestApp();
    final TestApp target = await bootTestApp();
    addTearDown(source.dispose);
    addTearDown(target.dispose);
    final RecordEntry captured = await source.capture(
      fields: const <String, String>{'serial': 'B-1'},
    );
    final Map<String, String> snapshot = <String, String>{
      captured.id: 'serial=B-1',
    };
    final RecordEntry imported = await target.capture(
      fields: const <String, String>{'serial': 'B-1'},
    );
    final int before = (await target.db.select(target.db.records).get()).length;
    final RecordEntry again = await target.capture(
      fields: const <String, String>{'serial': 'B-9'},
    );
    expect((await target.db.select(target.db.records).get()).length, before + 1);
    final Map<String, String> restored = const MergeUndo().undo(
      snapshot: snapshot,
      purged: false,
    );
    expect(restored, snapshot);
    expect(valueOf(await target.records.byId(imported.id)), isNotNull);
    expect(again.id, isNot(imported.id));
    expect(source.outboundCallCount, 0);

    final Uint8List bad = Uint8List.fromList(
      ZipEncoder().encode(
            Archive()..addFile(ArchiveFile('../secret.txt', 1, <int>[1])),
          ) ??
          <int>[],
    );
    final result = await BundleReader.inspect(
      PickedBytes(bad, 'bad.zip'),
    );
    expect(result, isFailure<dynamic, CorruptionFailure>());
  });
}
