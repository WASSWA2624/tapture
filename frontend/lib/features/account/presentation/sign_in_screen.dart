import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

/// The one sign-in the app asks for. There is no second step.
class SignInScreen extends StatefulWidget {
  /// Creates the screen. [onSubmit] talks to [BackendApiClient].
  const SignInScreen({super.key, required this.onSubmit, this.errorText});

  /// Called with the email and password. The screen does not store them.
  final Future<void> Function(String email, String password) onSubmit;

  /// A previous failure, shown on the password field.
  final String? errorText;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
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
    return AppPage(
      title: Copy.signInTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(label: Copy.signInEmail, controller: _email),
          AppTextField(
            label: Copy.signInPassword,
            controller: _password,
            obscureText: true,
            errorText: widget.errorText,
          ),
          AppButton(
            label: Copy.signInAction,
            expand: true,
            onPressed: () =>
                unawaited(widget.onSubmit(_email.text, _password.text)),
          ),
        ],
      ),
    );
  }
}
