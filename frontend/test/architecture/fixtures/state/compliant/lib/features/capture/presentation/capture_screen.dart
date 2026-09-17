import 'capture_controller.dart';

/// A screen that talks to the controller, not the repository.
class CaptureScreen {
  CaptureScreen(this.controller);

  final CaptureController controller;

  void onAdd() => controller.addPhoto('p1');
}
