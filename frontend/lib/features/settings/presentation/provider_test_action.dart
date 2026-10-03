import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
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
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failure = this.failure;
    if (failure != null) {
      return AppErrorState(failure: failure, onRetry: onTest);
    }
    if (view == ProviderTestView.empty && onTest == null) {
      return AppEmptyState(
        icon: AppIcons.key,
        headline: localCopy.apiKeyTest,
        message: localCopy.apiKeyCustody,
      );
    }
    final String? message = switch (view) {
      ProviderTestView.empty => null,
      ProviderTestView.success => localCopy.apiKeySuccess,
      ProviderTestView.authentication => localCopy.apiKeyAuthFailed,
      ProviderTestView.network => localCopy.apiKeyNetworkFailed,
      ProviderTestView.unavailable => localCopy.aiProviderUnavailable,
      ProviderTestView.validation => localCopy.aiSelectionInvalid,
      ProviderTestView.failed => localCopy.apiKeyTestFailed,
    };
    // Secondary: Save is the page's one primary action (FE-SIMP-01). The
    // outcome carries an icon and a tone, never plain text (FE-THEME-05).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(
          label: localCopy.apiKeyTest,
          variant: AppButtonVariant.secondary,
          onPressed: onTest,
        ),
        if (message != null) ...<Widget>[
          const SizedBox(height: Space.x2),
          AppBanner(
            key: const ValueKey<String>('provider-test-outcome'),
            message: message,
            icon: view == ProviderTestView.success
                ? AppIcons.success
                : AppIcons.warning,
            tone: view == ProviderTestView.success
                ? SnackTone.success
                : SnackTone.warning,
          ),
        ],
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

  /// The provider answered with an error that is neither a rejected key nor
  /// a network fault.
  failed,
}
