import 'folder_picker.dart';

/// The browser cannot hold an app-chosen documents folder.
FolderPicker platformFolderPicker() => const FolderPicker.fake(canPick: false);
