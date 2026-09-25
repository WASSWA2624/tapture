/// The context feature: the ambient context a capture is recorded against.
library;

export 'data/context_repository_impl.dart' show contextRepositoryProvider;
export 'domain/domain.dart';
export 'presentation/context_providers.dart'
    show contextStatusLabel, openProjectContextProvider, projectContextProvider;
export 'presentation/pinned_fields_sheet.dart' show showPinnedFieldsSheet;
