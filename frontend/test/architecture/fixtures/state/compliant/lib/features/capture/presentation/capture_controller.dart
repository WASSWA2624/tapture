/// Owns capture mutations; widgets call these, never the repository.
class CaptureController {
  Future<void> addPhoto(String id) async {
    // Persistence lives here, not in build (FE-STATE-04).
    await Future<void>.value();
    if (id.isEmpty) {
      return;
    }
  }
}
