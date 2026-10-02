import 'dart:typed_data';

import 'package:tapture/core/bundle/bundle_encryption.dart';
import 'package:tapture/core/bundle/bundle_output.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';

/// Rejects an oversized relay before reading a native ZIP or encrypting it.
/// Exported files remain available for direct sharing through the export flow.
Future<Result<Uint8List>> readRelayPackage(
  BundleOutput output,
  FileReader files,
) async {
  final ValidationFailure? failure = relayPackageSizeFailure(output.byteLength);
  if (failure != null) return FailureResult<Uint8List>(failure);
  switch (output) {
    case InMemoryBundle(:final Uint8List bytes):
      final ValidationFailure? actualFailure = relayPackageSizeFailure(
        bytes.length,
      );
      if (actualFailure != null) return FailureResult<Uint8List>(actualFailure);
      return Success<Uint8List>(bytes);
    case StoredBundle(:final String relativePath):
      // Check the actual durable file too, before read; stale output metadata
      // must not bypass the allocation ceiling.
      final Result<int?> size = await files.length(relativePath);
      if (size case FailureResult<int?>(:final Failure failure)) {
        return FailureResult<Uint8List>(failure);
      }
      final int? actual = (size as Success<int?>).value;
      if (actual == null) {
        return FailureResult<Uint8List>(FileReader.unreadable(relativePath));
      }
      final ValidationFailure? actualFailure = relayPackageSizeFailure(actual);
      if (actualFailure != null) return FailureResult<Uint8List>(actualFailure);
      return files.read(relativePath);
  }
}

/// The same ciphertext ceiling guards direct queue callers, before encryption.
ValidationFailure? relayPackageSizeFailure(int plainBytes) {
  return relayCiphertextSizeFailure(BundleEncryption.sealedLength(plainBytes));
}

/// Applies the same bounded envelope policy to downloaded ciphertext.
ValidationFailure? relayCiphertextSizeFailure(int encryptedBytes) {
  return encryptedBytes <= AppConstants.backend.relayMaxBytes
      ? null
      : ValidationFailure(
          message: Copy.relayPackageTooLarge(
            encryptedBytes,
            AppConstants.backend.relayMaxBytes,
          ),
          localizedMessage: Copy.messages.relayPackageTooLarge(
            encryptedBytes,
            AppConstants.backend.relayMaxBytes,
          ),
          recoveryAction: Copy.relayPackageTooLargeRecovery,
          localizedRecovery: Copy.messages.relayPackageTooLargeRecovery,
        );
}
