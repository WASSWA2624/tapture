/// The reference feature: the reference data a capture is matched against.
library;

export 'data/dataset_export.dart' show DatasetExport;
export 'data/dataset_import.dart' show DatasetImport;
export 'data/lookup_search.dart' show LookupSearch, LookupSearchResult;
export 'data/reference_repository_impl.dart' show referenceRepositoryProvider;
export 'domain/domain.dart' hide DatasetDraft;
export 'presentation/dataset_add_row_sheet.dart' show showDatasetAddRowSheet;
export 'presentation/dataset_browser_screen.dart' show DatasetBrowserScreen;
export 'presentation/dataset_key_screen.dart' show DatasetKeyScreen;
export 'presentation/dataset_list_screen.dart'
    show DatasetListScreen, datasetListProvider;
export 'presentation/dataset_row_edit_screen.dart' show DatasetRowEditScreen;
export 'presentation/lookup_picker_sheet.dart' show showLookupPickerSheet;
