import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Test connection. It never imports an HTTP client.
class ProviderTestAction extends StatelessWidget {
  /// Creates the action. [failure] is the load failure, distinct from a
  /// test outcome.
  const ProviderTestAction({
    super.key,
    this.view = ProviderTestView.empty,
    this.failure,
    this.onTest,
  });

  /// The last outcome.
  final ProviderTestView view;

  /// Set when the action itself cannot be shown.
  final Failure? failure;

  /// Runs the smallest request through the registry.
  final VoidCallback? onTest;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = this.failure;
    if (failure != null) {
      return AppErrorState(failure: failure, onRetry: onTest);
    }
    if (view == ProviderTestView.empty && onTest == null) {
      return const AppEmptyState(
        icon: AppIcons.key,
        headline: Copy.apiKeyTest,
        message: Copy.apiKeyCustody,
      );
    }
    final String? message = switch (view) {
      ProviderTestView.empty => null,
      ProviderTestView.success => Copy.apiKeySuccess,
      ProviderTestView.authentication => Copy.apiKeyAuthFailed,
      ProviderTestView.network => Copy.apiKeyNetworkFailed,
      ProviderTestView.unavailable => Copy.aiProviderUnavailable,
      ProviderTestView.validation => Copy.aiSelectionInvalid,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(label: Copy.apiKeyTest, onPressed: onTest),
        if (message != null) Text(message),
      ],
    );
  }
}

/// What a test connection is showing.
enum ProviderTestView {
  /// No test has been run.
  empty,

  /// The smallest call succeeded.
  success,

  /// The key was rejected.
  authentication,

  /// The network failed.
  network,

  /// Registered descriptor is not currently available.
  unavailable,

  /// Provider/model selection is invalid.
  validation,
}
