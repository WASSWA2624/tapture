import 'photo_picker.dart';

/// Neither a plugin nor a browser: tests never open a camera (FE-TEST-03).
PhotoPicker platformPhotoPicker() {
  return const PhotoPicker.fake(canTakePhoto: false);
}
