import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/download_service_io.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

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
    'an Exports subfolder is nested under Tapture and stays off the default save',
    () async {
      final Directory folder = _tempFolder();
      final DownloadService downloads = folderDownloads(() async => folder);
      final Uint8List bytes = Uint8List.fromList(<int>[9]);

      final String? plain = _ok(
        await downloads.save(
          fileName: 'note.zip',
          bytes: bytes,
          mimeType: 'application/zip',
        ),
      );
      final String? nested = _ok(
        await downloads.save(
          fileName: 'book.xlsx',
          bytes: bytes,
          mimeType: 'application/vnd.ms-excel',
          subfolder: 'Exports',
        ),
      );

      expect(_slash(plain), _slash('${folder.path}/Tapture/note.zip'));
      expect(
        _slash(nested),
        _slash('${folder.path}/Tapture/Exports/book.xlsx'),
      );
      expect(File(nested!).readAsBytesSync(), bytes);

      const MethodChannel channel = MethodChannel('com.tapture.app/files');
      _onChannel(channel, (MethodCall call) async {
        expect(call.method, 'saveToDownloads');
        final Map<Object?, Object?> args =
            call.arguments as Map<Object?, Object?>;
        expect(args['subfolder'], 'Exports');
        return 'Download/Tapture/Exports/book.xlsx';
      });
      final DownloadService android = androidDownloads(
        channel: channel,
        fallback: folderDownloads(() async => folder),
      );
      final String? viaChannel = _ok(
        await android.save(
          fileName: 'book.xlsx',
          bytes: bytes,
          mimeType: 'application/vnd.ms-excel',
          subfolder: 'Exports',
        ),
      );
      expect(viaChannel, 'Download/Tapture/Exports/book.xlsx');
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

  test(
    'desktop openFolder runs the platform command with the folder argument',
    () async {
      final Directory folder = _tempFolder();
      String? executable;
      List<String>? arguments;
      final DownloadService downloads = folderDownloads(
        () async => folder,
        open: (String command, List<String> args) async {
          executable = command;
          arguments = args;
        },
      );

      _okVoid(await downloads.openFolder());

      expect(executable, _desktopOpenCommand);
      expect(arguments!.map(_slash).toList(), <String>[
        _slash('${folder.path}/Tapture'),
      ]);
      expect(Directory('${folder.path}/Tapture').existsSync(), isTrue);
    },
  );

  test('a failing desktop runner returns openFolderFailure', () async {
    final Directory folder = _tempFolder();
    final DownloadService downloads = folderDownloads(
      () async => folder,
      open: (String _, List<String> _) async {
        throw const FileSystemException('blocked');
      },
    );

    final Result<void> result = await downloads.openFolder();
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<StorageFailure>());
    expect(
      failure?.message,
      openFolderFailure(Copy.downloadsTaptureFolder).message,
    );
    expect(failure?.recoveryAction, isNotEmpty);
  });

  test('Android openFolder invokes openDownloads', () async {
    final Directory folder = _tempFolder();
    const MethodChannel channel = MethodChannel('com.tapture.app/files');
    String? method;
    _onChannel(channel, (MethodCall call) async {
      method = call.method;
      return null;
    });

    final DownloadService downloads = androidDownloads(
      channel: channel,
      fallback: folderDownloads(() async => folder),
    );
    _okVoid(await downloads.openFolder());

    expect(method, 'openDownloads');
    expect(downloads.destination, Copy.downloadsTaptureFolder);
    expect(downloads.canOpenFolder, isTrue);
  });

  test('a failing Android channel returns openFolderFailure', () async {
    final Directory folder = _tempFolder();
    const MethodChannel channel = MethodChannel('com.tapture.app/files');
    _onChannel(channel, (MethodCall call) async {
      expect(call.method, 'openDownloads');
      throw PlatformException(code: 'open_failed');
    });

    final DownloadService downloads = androidDownloads(
      channel: channel,
      fallback: folderDownloads(() async => folder),
    );
    final Result<void> result = await downloads.openFolder();
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<StorageFailure>());
    expect(
      failure?.message,
      openFolderFailure(Copy.downloadsTaptureFolder).message,
    );
  });

  test('saveAs returns the name the handler replies with', () async {
    final Directory folder = _tempFolder();
    const MethodChannel channel = MethodChannel('com.tapture.app/files');
    _onChannel(channel, (MethodCall call) async {
      expect(call.method, 'saveAs');
      final Object? args = call.arguments;
      expect(args, isA<Map<Object?, Object?>>());
      return 'TAPTURE-18092026-1002.zip';
    });

    final DownloadService downloads = androidDownloads(
      channel: channel,
      fallback: folderDownloads(() async => folder),
    );
    final String? name = _ok(
      await downloads.saveAs(
        fileName: 'note.zip',
        bytes: Uint8List.fromList(<int>[1, 2]),
        mimeType: 'application/zip',
      ),
    );

    expect(name, 'TAPTURE-18092026-1002.zip');
    expect(downloads.canChooseLocation, isTrue);
    expect(Directory('${folder.path}/Tapture').existsSync(), isFalse);
  });

  test('a cancelled saveAs reply is CancelledFailure', () async {
    final Directory folder = _tempFolder();
    const MethodChannel channel = MethodChannel('com.tapture.app/files');
    _onChannel(channel, (MethodCall call) async {
      expect(call.method, 'saveAs');
      throw PlatformException(code: 'cancelled');
    });

    final DownloadService downloads = androidDownloads(
      channel: channel,
      fallback: folderDownloads(() async => folder),
    );
    final Result<String?> result = await downloads.saveAs(
      fileName: 'note.zip',
      bytes: Uint8List.fromList(<int>[3]),
      mimeType: 'application/zip',
    );
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<CancelledFailure>());
    expect(Directory('${folder.path}/Tapture').existsSync(), isFalse);
  });

  test('a saveAs error is downloadFailure', () async {
    final Directory folder = _tempFolder();
    const MethodChannel channel = MethodChannel('com.tapture.app/files');
    _onChannel(channel, (MethodCall call) async {
      expect(call.method, 'saveAs');
      throw PlatformException(code: 'write_failed');
    });

    final DownloadService downloads = androidDownloads(
      channel: channel,
      fallback: folderDownloads(() async => folder),
    );
    final Result<String?> result = await downloads.saveAs(
      fileName: 'note.zip',
      bytes: Uint8List.fromList(<int>[4]),
      mimeType: 'application/zip',
    );
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<StorageFailure>());
    expect(failure?.message, downloadFailure('note.zip').message);
    expect(Directory('${folder.path}/Tapture').existsSync(), isFalse);
  });

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

  test('the fake reports Open with and never receives a stored path', () async {
    String? seenName;
    Uint8List? seenBytes;
    String? seenMime;
    final DownloadService downloads = DownloadService.fake(
      canOpenExternally: true,
      onOpenExternally: (String fileName, Uint8List bytes, String mimeType) {
        seenName = fileName;
        seenBytes = bytes;
        seenMime = mimeType;
      },
    );
    final Uint8List bytes = Uint8List.fromList(<int>[9, 8, 7]);

    expect(downloads.canOpenExternally, isTrue);
    expect(downloads.canDownloadCopy, isFalse);
    _okVoid(
      await downloads.openExternally(
        fileName: 'book.xlsx',
        bytes: bytes,
        mimeType: 'application/vnd.ms-excel',
      ),
    );

    expect(seenName, 'book.xlsx');
    expect(seenName, isNot(contains('/')));
    expect(seenName, isNot(contains(r'\')));
    expect(seenBytes, bytes);
    expect(seenMime, 'application/vnd.ms-excel');
  });

  test(
    'a cancelled fake chooser is CancelledFailure and writes nothing',
    () async {
      final DownloadService downloads = DownloadService.fake(
        canOpenExternally: true,
        openCancel: true,
      );

      final Result<void> result = await downloads.openExternally(
        fileName: 'book.xlsx',
        bytes: Uint8List.fromList(<int>[1]),
        mimeType: 'application/pdf',
      );
      final Failure? failure = result.fold(
        (Failure value) => value,
        (_) => null,
      );

      expect(failure, isA<CancelledFailure>());
      expect(failure?.recoveryAction, isNotEmpty);
    },
  );

  test('a missing-handler fake is a typed storage failure', () async {
    final DownloadService downloads = DownloadService.fake(
      canOpenExternally: true,
      openNoHandler: true,
    );

    final Result<void> result = await downloads.openExternally(
      fileName: 'book.xlsx',
      bytes: Uint8List.fromList(<int>[1]),
      mimeType: 'application/pdf',
    );
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<StorageFailure>());
    expect(failure?.message, openExternallyNoHandlerFailure().message);
    expect(failure?.recoveryAction, isNotEmpty);
  });

  test(
    'desktop openExternally opens a cache copy and leaves the original',
    () async {
      final Directory folder = _tempFolder();
      final File original = File('${folder.path}/original.xlsx')
        ..writeAsBytesSync(<int>[1, 2, 3]);
      final DateTime modified = original.lastModifiedSync();
      final Directory cache = Directory('${folder.path}/cache')..createSync();
      String? executable;
      List<String>? arguments;
      final DownloadService downloads = folderDownloads(
        () async => folder,
        cacheDir: () async => cache,
        open: (String command, List<String> args) async {
          executable = command;
          arguments = args;
        },
      );
      final Uint8List bytes = original.readAsBytesSync();

      _okVoid(
        await downloads.openExternally(
          fileName: 'book.xlsx',
          bytes: bytes,
          mimeType: 'application/vnd.ms-excel',
        ),
      );

      expect(original.readAsBytesSync(), <int>[1, 2, 3]);
      expect(original.lastModifiedSync(), modified);
      expect(executable, _desktopOpenCommand);
      expect(arguments, isNotNull);
      expect(_slash(arguments!.single), isNot(_slash(original.path)));
      expect(_slash(arguments!.single), contains('/cache/open-'));
      expect(File(arguments!.single).readAsBytesSync(), bytes);
      expect(downloads.canOpenExternally, isTrue);
      expect(downloads.canDownloadCopy, isFalse);
    },
  );

  test('a cancelled share deletes the copy and leaves the original', () async {
    final Directory folder = _tempFolder();
    final File original = File('${folder.path}/original.xlsx')
      ..writeAsBytesSync(<int>[4, 5, 6]);
    final DateTime modified = original.lastModifiedSync();
    final Directory cache = Directory('${folder.path}/cache')..createSync();
    final DownloadService downloads = folderDownloads(
      () async => folder,
      cacheDir: () async => cache,
      useShare: true,
      share:
          ({
            required String path,
            required String mimeType,
            required String fileName,
          }) async {
            expect(File(path).existsSync(), isTrue);
            expect(_slash(path), isNot(_slash(original.path)));
            return ExternalOpenOutcome.dismissed;
          },
    );

    final Result<void> result = await downloads.openExternally(
      fileName: 'book.xlsx',
      bytes: original.readAsBytesSync(),
      mimeType: 'application/vnd.ms-excel',
    );
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<CancelledFailure>());
    expect(original.readAsBytesSync(), <int>[4, 5, 6]);
    expect(original.lastModifiedSync(), modified);
    expect(_openCopies(cache), isEmpty);
  });

  test('a missing share handler deletes the copy', () async {
    final Directory folder = _tempFolder();
    final Directory cache = Directory('${folder.path}/cache')..createSync();
    final DownloadService downloads = folderDownloads(
      () async => folder,
      cacheDir: () async => cache,
      useShare: true,
      share:
          ({
            required String path,
            required String mimeType,
            required String fileName,
          }) async {
            return ExternalOpenOutcome.unavailable;
          },
    );

    final Result<void> result = await downloads.openExternally(
      fileName: 'book.xlsx',
      bytes: Uint8List.fromList(<int>[1]),
      mimeType: 'application/pdf',
    );
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<StorageFailure>());
    expect(failure?.message, openExternallyNoHandlerFailure().message);
    expect(_openCopies(cache), isEmpty);
  });

  test('denied storage permission writes no copy', () async {
    final Directory folder = _tempFolder();
    final Directory cache = Directory('${folder.path}/cache')..createSync();
    final DownloadService downloads = folderDownloads(
      () async => folder,
      cacheDir: () async => cache,
      checkStorage: true,
      permissions: PermissionsService.fake(),
      open: (String _, List<String> _) async {},
    );

    final Result<void> result = await downloads.openExternally(
      fileName: 'book.xlsx',
      bytes: Uint8List.fromList(<int>[1]),
      mimeType: 'application/pdf',
    );
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<PermissionFailure>());
    expect(failure?.recoveryAction, isNotEmpty);
    expect(_openCopies(cache), isEmpty);
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

void _okVoid(Result<void> result) {
  result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (_) {});
}

String get _desktopOpenCommand {
  if (Platform.isWindows) {
    return 'explorer';
  }
  if (Platform.isMacOS) {
    return 'open';
  }
  return 'xdg-open';
}

String _slash(String? path) => (path ?? '').replaceAll(r'\', '/');

List<File> _openCopies(Directory cache) {
  return cache.listSync().whereType<File>().where((File file) {
    final String name = file.uri.pathSegments.isEmpty
        ? ''
        : file.uri.pathSegments.last;
    return name.startsWith('open-');
  }).toList();
}
