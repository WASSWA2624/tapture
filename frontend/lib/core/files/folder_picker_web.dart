import 'folder_picker.dart';

/// The browser cannot hold an app-chosen documents folder.
FolderPicker platformFolderPicker() => const FolderPicker.fake(canPick: false);

/// Browser directory grants are not available through the native writer.
FolderPicker platformDestinationFolderPicker() => platformFolderPicker();
