import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/download_service_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the folder writer saves into Tapture and numbers a second file',
    () async {
      final Directory folder = _tempFolder();
      final DownloadService downloads = folderDownloads(() async => folder);
      final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);

      final String? first = _ok(
        await downloads.save(
          fileName: 'note.zip',
          bytes: bytes,
          mimeType: 'application/zip',
        ),
      );
      final String? second = _ok(
        await downloads.save(
          fileName: 'note.zip',
          bytes: bytes,
          mimeType: 'application/zip',
        ),
      );

      expect(_slash(first), _slash('${folder.path}/Tapture/note.zip'));
      expect(_slash(second), _slash('${folder.path}/Tapture/note (2).zip'));
      expect(File(first!).readAsBytesSync(), bytes);
      expect(File(second!).readAsBytesSync(), bytes);
      expect(File('$first.part').existsSync(), isFalse);
    },
  );

  test(
    'the channel path returns the location the handler replies with',
    () async {
      final Directory folder = _tempFolder();
      const MethodChannel channel = MethodChannel('com.tapture.app/files');
      _onChannel(channel, (MethodCall call) async {
        expect(call.method, 'saveToDownloads');
        final Object? args = call.arguments;
        expect(args, isA<Map<Object?, Object?>>());
        return 'Download/Tapture/note.zip';
      });

      final DownloadService downloads = androidDownloads(
        channel: channel,
        fallback: folderDownloads(() async => folder),
      );
      final String? location = _ok(
        await downloads.save(
          fileName: 'note.zip',
          bytes: Uint8List.fromList(<int>[4, 5]),
          mimeType: 'application/zip',
        ),
      );

      expect(location, 'Download/Tapture/note.zip');
      expect(Directory('${folder.path}/Tapture').existsSync(), isFalse);
    },
  );

  test(
    'an unsupported reply and a thrown PlatformException both fall back',
    () async {
      final Directory folder = _tempFolder();
      const MethodChannel channel = MethodChannel('com.tapture.app/files');
      final DownloadService downloads = androidDownloads(
        channel: channel,
        fallback: folderDownloads(() async => folder),
      );
      final Uint8List bytes = Uint8List.fromList(<int>[6, 7, 8]);

      _onChannel(channel, (MethodCall call) async {
        expect(call.method, 'saveToDownloads');
        throw PlatformException(code: 'unsupported');
      });
      final String? first = _ok(
        await downloads.save(
          fileName: 'one.zip',
          bytes: bytes,
          mimeType: 'application/zip',
        ),
      );

      _onChannel(channel, (MethodCall call) async {
        expect(call.method, 'saveToDownloads');
        throw PlatformException(code: 'write_failed');
      });
      final String? second = _ok(
        await downloads.save(
          fileName: 'two.zip',
          bytes: bytes,
          mimeType: 'application/zip',
        ),
      );

      expect(_slash(first), _slash('${folder.path}/Tapture/one.zip'));
      expect(_slash(second), _slash('${folder.path}/Tapture/two.zip'));
      expect(File(first!).readAsBytesSync(), bytes);
      expect(File(second!).readAsBytesSync(), bytes);
    },
  );

  test('a write failure returns downloadFailure', () async {
    final Directory folder = _tempFolder();
    File('${folder.path}/Tapture').writeAsStringSync('blocked');
    final DownloadService downloads = folderDownloads(() async => folder);

    final Result<String?> result = await downloads.save(
      fileName: 'note.zip',
      bytes: Uint8List.fromList(<int>[9]),
      mimeType: 'application/zip',
    );
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<StorageFailure>());
    expect(failure?.message, downloadFailure('note.zip').message);
    expect(failure?.recoveryAction, isNotEmpty);
    expect(File('${folder.path}/Tapture/note.zip').existsSync(), isFalse);
  });
}

Directory _tempFolder() {
  final Directory directory = Directory.systemTemp.createTempSync(
    'tapture-dl-',
  );
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  return directory;
}

void _onChannel(
  MethodChannel channel,
  Future<Object?>? Function(MethodCall call) handler,
) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, handler);
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}

String? _ok(Result<String?> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (String? location) => location);
}

String _slash(String? path) => (path ?? '').replaceAll(r'\', '/');
