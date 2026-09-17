import '../domain/capture_repository.dart';

/// Throws a raw [Exception] across the data boundary.
class CaptureRepositoryImpl implements CaptureRepository {
  @override
  Future<void> save(String id) async {
    throw Exception(id);
  }
}
