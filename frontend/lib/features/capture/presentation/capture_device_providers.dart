import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/features/templates/domain/domain.dart';

import '../domain/capture_device_source.dart';
import '../domain/capture_session.dart';

/// One source lifetime per Capture session key; bootstrap supplies native reads.
final captureDeviceSourceProvider = Provider.autoDispose
    .family<CaptureDeviceSource, String>((Ref ref, String key) {
      final CaptureDeviceSource source = _UnavailableDeviceSource();
      ref.onDispose(source.dispose);
      return source;
    });

final class _UnavailableDeviceSource implements CaptureDeviceSource {
  @override
  void bind(CaptureSession session, Iterable<FieldDef> fields) {}

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  void dispose() {}

  @override
  void refresh() {}

  @override
  String? snapshot(CaptureSession session) => null;
}
