part of 'uuid_service.dart';

/// Mints a new identifier. Implementations take a [Clock]; they never read
/// the system clock themselves (FE-STR-11).
abstract interface class IdService {
  /// A new identifier. Later calls do not repeat an earlier one.
  String newId();
}
