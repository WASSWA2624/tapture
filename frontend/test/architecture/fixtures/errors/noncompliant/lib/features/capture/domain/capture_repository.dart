/// A persistence port that returns a bare Future.
abstract class CaptureRepository {
  Future<void> save(String id);
}
