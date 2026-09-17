import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/compressed_copy.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/hash/hashing_service.dart';

void main() {
  test(
    'reduce leaves the original hash unchanged and writes a smaller copy',
    () async {
      final Directory documents = Directory.systemTemp.createTempSync(
        'tapture-upload-',
      );
      addTearDown(() {
        if (documents.existsSync()) {
          documents.deleteSync(recursive: true);
        }
      });
      final StorageRoot storage = StorageRoot.fake(
        documentsDirectory: documents,
      );
      _ok(await storage.resolve());
      final File source = File('${documents.path}/original.bin')
        ..writeAsBytesSync(Uint8List(2048));
      final String before = _ok(await sha256OfFile(source));
      var decodes = 0;
      final CompressedCopy copies = CompressedCopy(
        storageRoot: storage,
        decode:
            (String path, {required int longEdge, required int quality}) async {
              decodes += 1;
              expect(path, source.path);
              expect(longEdge, AppConstants.images.longEdge);
              expect(quality, AppConstants.images.quality);
              File(path).readAsBytesSync();
              return Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
            },
      );

      final WrittenFile reduced = _ok(await copies.reduce(source.path));
      final String after = _ok(await sha256OfFile(source));
      final File onDisk = File(
        '${documents.path}/Tapture/${reduced.relativePath}',
      );

      expect(after, before);
      expect(source.lengthSync(), 2048);
      expect(reduced.byteLength, 5);
      expect(reduced.byteLength, lessThan(source.lengthSync()));
      expect(_slash(reduced.relativePath), contains('.cache/upload/'));
      expect(onDisk.existsSync(), isTrue);
      expect(onDisk.lengthSync(), 5);
      expect(decodes, 1);

      final WrittenFile again = _ok(await copies.reduce(source.path));
      expect(decodes, 1);
      expect(again.byteLength, reduced.byteLength);
    },
  );
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}

String _slash(String path) => path.replaceAll(r'\', '/');
