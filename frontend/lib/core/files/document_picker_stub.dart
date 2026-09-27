import 'document_picker.dart';

/// Used when neither `dart:io` nor the web library is available.
DocumentPicker platformDocumentPicker() =>
    const DocumentPicker.fake(canPick: false);
