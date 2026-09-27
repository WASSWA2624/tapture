/// The processing feature: turning a raw capture into a record.
library;

export 'data/processing_repository_impl.dart' show ProcessingRepositoryImpl;
export 'domain/confidence.dart';
export 'domain/processing_repository.dart';
export 'presentation/egress_preview_dialog.dart' show showEgressPreview;
export 'presentation/processing_controller.dart'
    show processingControllerProvider, processingEgressSummaryProvider;
export 'presentation/queue_providers.dart' show processingRepositoryProvider;
export 'presentation/unattended_processing.dart'
    show unattendedProcessingProvider;
