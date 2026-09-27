import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/local_destination.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test(
    'a folder copy finishes offline and a cancel leaves no partial file',
    () async {
      final Directory root = Directory.systemTemp.createTempSync(
        'tapture-local',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final LocalDestination local = LocalDestination(
        rootPath: root.path,
        partBytes: 4,
      );
      const Destination destination = (
        id: 'dest',
        kind: DestinationKind.localFolder,
        label: 'Card',
        folder: 'sd',
        credentialRef: 'ref',
        lastCheck: null,
      );
      final Result<Uri> sent = await local.send(destination, (
        length: 6,
        read: (int _, int length) async => List<int>.filled(length, 7),
      ), remoteName: 'notes.txt');
      expect(sent, isA<Success<Uri>>());
      final File finished = File(
        '${root.path}${Platform.pathSeparator}sd${Platform.pathSeparator}notes.txt',
      );
      expect(finished.existsSync(), isTrue);
      expect(finished.readAsBytesSync(), <int>[7, 7, 7, 7, 7, 7]);
      expect(File('${finished.path}.partial').existsSync(), isFalse);

      final CancellationToken token = CancellationToken()..cancel();
      final Result<Uri> stopped = await local.send(
        destination,
        (
          length: 6,
          read: (int _, int _) async => throw StateError('should not read'),
        ),
        remoteName: 'other.txt',
        cancel: token,
      );
      expect(stopped, isA<FailureResult<Uri>>());
      expect((stopped as FailureResult<Uri>).failure, isA<CancelledFailure>());
      expect(
        File(
          '${root.path}${Platform.pathSeparator}sd${Platform.pathSeparator}other.txt',
        ).existsSync(),
        isFalse,
      );
      expect(
        Directory('${root.path}${Platform.pathSeparator}sd').listSync().length,
        1,
      );
    },
  );
}
