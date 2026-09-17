/// A disk failure with copy the user can act on (FE-CODE-06).
class StorageFailure {
  const StorageFailure({required this.message, this.recoveryAction});

  final String message;
  final String? recoveryAction;
}
