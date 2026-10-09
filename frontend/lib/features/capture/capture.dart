/// The capture feature: capturing field evidence.
library;

export 'data/data.dart';
export 'domain/domain.dart';
export 'presentation/capture_controller.dart'
    show
        captureControllerProvider,
        captureClockProvider,
        captureDeviceIdProvider,
        capturePersistenceProvider,
        captureRecordWriterProvider,
        captureDocumentRepositoryProvider,
        photoRepositoryProvider;
export 'presentation/capture_device_providers.dart'
    show captureDeviceSourceProvider;
export 'presentation/capture_field_providers.dart' show captureDateFillProvider;
export 'presentation/capture_screen.dart';
