import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';

/// Keeps one submission in flight and exposes a recoverable error beside input.
final class SignInController extends Notifier<SignInState> {
  @override
  SignInState build() => (busy: false, error: null);

  /// Executes an account action without discarding the caller's entered values.
  Future<bool> submit(Future<void> Function() action) async {
    if (state.busy) return false;
    state = (busy: true, error: null);
    try {
      await action();
      if (ref.mounted) state = (busy: false, error: null);
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = (busy: false, error: Failure.from(error).message);
      }
      return false;
    }
  }
}

/// Whether a submission is in flight, and the error shown beside the input.
typedef SignInState = ({bool busy, String? error});

/// Form state is discarded when the account route is left.
final signInControllerProvider =
    NotifierProvider.autoDispose<SignInController, SignInState>(
      SignInController.new,
    );
