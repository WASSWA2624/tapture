import 'screen_capture.dart';

/// Neither a display picker nor a plugin: tests never open one (FE-TEST-03).
ScreenCapture platformScreenCapture() => const ScreenCapture.fake();
