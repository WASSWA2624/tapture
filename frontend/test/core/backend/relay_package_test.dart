import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/relay_package.dart';
import 'package:tapture/core/bundle/bundle_encryption.dart';
import 'package:tapture/core/bundle/bundle_output.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';

void main() {
  test('cipher size preflight matches the actual authenticated envelope', () {
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
    expect(
      BundleEncryption().seal(bytes, 'a shared project password').length,
      BundleEncryption.sealedLength(bytes.length),
    );
    final int maxPlain =
        AppConstants.backend.relayMaxBytes - BundleEncryption.sealedLength(0);
    expect(relayPackageSizeFailure(maxPlain), isNull);
    expect(relayPackageSizeFailure(maxPlain + 1), isA<ValidationFailure>());
  });

  test(
    'an oversized native package is refused before stat or full read',
    () async {
      final _Reader reader = _Reader(fileSize: 3);
      final Result<Uint8List> result = await readRelayPackage(
        const StoredBundle(
          relativePath: 'exports/huge.zip',
          byteLength: 4000000000,
          sha256: 'sum',
        ),
        reader,
      );
      expect(result, isA<FailureResult<Uint8List>>());
      expect(reader.stats, 0);
      expect(reader.reads, 0);
    },
  );

  test(
    'durable file size prevents stale output metadata bypassing the cap',
    () async {
      final _Reader reader = _Reader(
        fileSize: AppConstants.backend.relayMaxBytes,
      );
      final Result<Uint8List> result = await readRelayPackage(
        const StoredBundle(
          relativePath: 'exports/a.zip',
          byteLength: 3,
          sha256: 'sum',
        ),
        reader,
      );
      expect(
        (result as FailureResult<Uint8List>).failure,
        isA<ValidationFailure>(),
      );
      expect(reader.stats, 1);
      expect(reader.reads, 0);
    },
  );

  test('a bounded native package uses the existing file reader', () async {
    final _Reader reader = _Reader(fileSize: 3);
    final Result<Uint8List> result = await readRelayPackage(
      const StoredBundle(
        relativePath: 'exports/a.zip',
        byteLength: 3,
        sha256: 'sum',
      ),
      reader,
    );
    expect((result as Success<Uint8List>).value, reader.bytes);
    expect(reader.stats, 1);
    expect(reader.reads, 1);
  });

  test('in-memory packages also check the actual bytes', () async {
    final Uint8List bytes = Uint8List(AppConstants.backend.relayMaxBytes);
    final _Reader reader = _Reader(fileSize: 0);
    final Result<Uint8List> result = await readRelayPackage(
      InMemoryBundle(bytes: bytes, byteLength: 1, sha256: 'sum'),
      reader,
    );
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<ValidationFailure>(),
    );
    expect(reader.stats, 0);
    expect(reader.reads, 0);
  });
}

final class _Reader implements FileReader {
  _Reader({required this.fileSize});
  final int fileSize;
  final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
  int stats = 0;
  int reads = 0;

  @override
  Future<Result<int?>> length(String relativePath) async {
    stats++;
    return Success<int?>(fileSize);
  }

  @override
  Future<Result<Uint8List>> read(String relativePath) async {
    reads++;
    return Success<Uint8List>(bytes);
  }
}
