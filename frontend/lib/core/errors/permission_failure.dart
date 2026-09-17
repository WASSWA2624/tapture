part of 'failure.dart';

/// The device has not granted a permission this action needs.
final class PermissionFailure extends Failure {
  /// Creates a permission failure.
  const PermissionFailure({
    this.message = 'Tapture does not have permission to do that.',
    this.recoveryAction = 'Allow the permission in settings, then try again.',
  });

  @override
  final String message;

  @override
  final String recoveryAction;
}
