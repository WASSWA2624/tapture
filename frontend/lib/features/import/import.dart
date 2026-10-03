/// The import feature: one entry for every file the app takes (task 020),
/// and the record import that turns a spreadsheet's rows into records.
library;

export 'data/record_import_store_impl.dart'
    show RecordImportStoreImpl, recordImportStoreProvider;
export 'domain/domain.dart';
export 'presentation/presentation.dart';
