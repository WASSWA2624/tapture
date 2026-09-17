/// A fallible value the repository returns instead of throwing.
typedef Result<T> = Object;

/// The capture persistence port; every method is a Result (FE-CODE-06).
abstract class CaptureRepository {
  Future<Result<void>> save(String id);

  Result<String> pathOf(String id);
}
