/// The processing feature: turning a raw capture into a record.
library;

export 'data/processing_repository_impl.dart' show ProcessingRepositoryImpl;
export 'domain/processing_repository.dart';
export 'presentation/queue_providers.dart' show processingRepositoryProvider;
export 'presentation/unattended_processing.dart'
    show unattendedProcessingProvider;
