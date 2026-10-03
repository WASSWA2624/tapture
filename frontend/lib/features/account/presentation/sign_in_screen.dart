import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_email_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import 'sign_in_controller.dart';

/// The one sign-in the app asks for. There is no second step.
class SignInScreen extends ConsumerStatefulWidget {
  /// Creates the screen. [onSubmit] signs in through the session; [onLater]
  /// goes to work without signing in, so nothing blocks capture.
  const SignInScreen({super.key, required this.onSubmit, this.onLater});

  /// Called with the email and password. The screen does not store them.
  final Future<void> Function(String email, String password) onSubmit;

  /// Leaves sign-in for later. Null hides the action.
  final VoidCallback? onLater;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final SignInState view = ref.watch(signInControllerProvider);
    final String? error = view.errorMessage == null
        ? view.error
        : localCopy.resolve(view.errorMessage!);
    final VoidCallback? later = widget.onLater;
    return AppPage(
      title: localCopy.signInTitle,
      scrollable: false,
      body: AppForm(
        errors: <String>[?error],
        fields: <Widget>[
          AppEmailField(
            label: localCopy.signInEmail,
            controller: _email,
            requiredness: FieldRequiredness.required,
          ),
          AppTextField(
            label: localCopy.signInPassword,
            controller: _password,
            obscureText: true,
            requiredness: FieldRequiredness.required,
          ),
          if (later != null)
            AppButton(
              label: localCopy.signInLater,
              variant: AppButtonVariant.text,
              expand: true,
              onPressed: later,
            ),
        ],
        submitLabel: localCopy.signInAction,
        onSubmit: () => ref
            .read(signInControllerProvider.notifier)
            .submit(() => widget.onSubmit(_email.text, _password.text)),
      ),
    );
  }
}
