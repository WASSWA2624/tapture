import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/settings/settings.dart';

import 'api_key_controller.dart';
import 'provider_test_action.dart';

/// The device-held key, the exception an administrator may allow.
///
/// The key is stored only in platform secure storage. The screen says, in
/// one line, that the usual arrangement is for the organisation's backend
/// to hold it.
class ApiKeyScreen extends ConsumerStatefulWidget {
  /// Creates the screen. Tests pass [storage] and [settings].
  const ApiKeyScreen({super.key, this.storage, this.settings, this.onTest});

  /// Secure store. Production uses the platform keystore.
  final SecureStorage? storage;

  /// Provider selection. Removing the key resets this to the backend.
  final SettingsStore? settings;

  /// Runs the registry's smallest call.
  final Future<ProviderTestView> Function()? onTest;

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final TextEditingController _key = TextEditingController();

  /// Resolved once, so the controller's family key stays the same across
  /// rebuilds.
  late final ApiKeyStores _stores = (
    storage: widget.storage ?? SecureStorage(),
    settings: widget.settings,
  );

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  ApiKeyController get _controller =>
      ref.read(apiKeyControllerProvider(_stores).notifier);

  Future<void> _save() async {
    if (await _controller.save(_key.text)) {
      _key.clear();
    }
  }

  Future<void> _remove() async {
    await _controller.remove();
    _key.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ApiKeyView view = ref.watch(apiKeyControllerProvider(_stores));
    final Future<ProviderTestView> Function()? onTest = widget.onTest;
    return AppPage(
      title: Copy.apiKeyTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(Copy.apiKeyCustody),
          if (view.failure case final Failure failure)
            AppErrorState(failure: failure, onRetry: _controller.load),
          AppTextField(
            label: Copy.apiKeyLabel,
            controller: _key,
            obscureText: view.saved,
            dictation: false,
          ),
          if (view.saved) const Text(Copy.apiKeySaved),
          AppButton(label: Copy.apiKeySave, onPressed: _save),
          AppButton(
            label: Copy.apiKeyRemove,
            variant: AppButtonVariant.secondary,
            onPressed: view.saved ? _remove : null,
          ),
          ProviderTestAction(
            view: view.test,
            onTest: onTest == null ? null : () => _controller.runTest(onTest),
          ),
        ],
      ),
    );
  }
}
