import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/volume_stats.dart';

/// Ample browser-safe volume port for production Capture composition tests.
final class FakeCaptureStorageGuard implements StorageGuard {
  @override
  Stream<HeadroomState> watch() =>
      Stream<HeadroomState>.value(HeadroomState.ample);

  @override
  Future<Result<VolumeStats>> volume() async => const Success<VolumeStats>(
    VolumeStats(totalBytes: 2000000000, usedBytes: 0, freeBytes: 2000000000),
  );

  @override
  Future<Result<HeadroomState>> check() async =>
      const Success<HeadroomState>(HeadroomState.ample);

  @override
  Future<Result<HeadroomState>> beginSession() => check();

  @override
  bool takeLowWarning() => false;

  @override
  Future<Result<HeadroomState>> admitCapture() => check();

  @override
  Future<Result<T>> completeSave<T>(Future<Result<T>> Function() save) =>
      save();

  @override
  Future<void> dispose() async {}
}
