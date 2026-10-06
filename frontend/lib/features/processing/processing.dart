/// The processing feature: turning a raw capture into a record.
library;

export 'data/processing_findings.dart' show ProcessingFindings;
export 'data/processing_repository_impl.dart' show ProcessingRepositoryImpl;
export 'data/processing_usage.dart' show ProcessingUsage;
export 'data/proposal_preview.dart'
    show PreviewedValue, ProposalPreview, proposalPreviewProvider;
export 'domain/confidence.dart';
export 'domain/processing_repository.dart';
export 'presentation/confidence_indicator.dart';
export 'presentation/egress_preview_dialog.dart' show showEgressPreview;
export 'presentation/processing_controller.dart'
    show
        processingControllerProvider,
        processingEgressIdentityProvider,
        processingEgressSummaryProvider;
export 'presentation/processing_findings_providers.dart'
    show
        processingFindingsProvider,
        processingFindingsStoreProvider,
        processingUsageStoreProvider,
        queueSpendProvider;
export 'presentation/queue_providers.dart' show processingRepositoryProvider;
export 'presentation/unattended_processing.dart'
    show unattendedProcessingProvider;
