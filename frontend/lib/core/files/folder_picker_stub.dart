import 'folder_picker.dart';

/// Used when neither `dart:io` nor the web library is available.
FolderPicker platformFolderPicker() => const FolderPicker.fake(canPick: false);
