import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/settings/settings.dart';

import 'provider_test_action.dart';

/// The device-held key, the exception an administrator may allow.
///
/// The key is stored only in platform secure storage. The screen says, in
/// one line, that the usual arrangement is for the organisation's backend
/// to hold it.
class ApiKeyScreen extends StatefulWidget {
  /// Creates the screen. Tests pass [storage] and [settings].
  const ApiKeyScreen({super.key, this.storage, this.settings, this.onTest});

  /// Secure store. Production uses the platform keystore.
  final SecureStorage? storage;

  /// Provider selection. Removing the key resets this to the backend.
  final SettingsStore? settings;

  /// Runs the registry's smallest call.
  final Future<ProviderTestView> Function()? onTest;

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final TextEditingController _key = TextEditingController();
  bool _saved = false;
  ProviderTestView _test = ProviderTestView.empty;
  Failure? _failure;

  SecureStorage get _storage => widget.storage ?? SecureStorage();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final Result<String?> stored = await _storage.readSecret(
      SecretKey.providerCredential,
    );
    if (!mounted) {
      return;
    }
    switch (stored) {
      case FailureResult<String?>(:final Failure failure):
        setState(() => _failure = failure);
      case Success<String?>(:final String? value):
        setState(() {
          _failure = null;
          _saved = value != null && value.isNotEmpty;
          _key.text = '';
        });
    }
  }

  Future<void> _save() async {
    final String value = _key.text.trim();
    if (value.isEmpty) {
      return;
    }
    final Result<void> stored = await _storage.putSecret(
      SecretKey.providerCredential,
      value,
    );
    if (stored case FailureResult<void>(:final Failure failure)) {
      if (mounted) {
        setState(() => _failure = failure);
      }
      return;
    }
    final SettingsStore? settings = widget.settings;
    if (settings != null) {
      final Result<void> selected = await settings.write(
        SettingKeys.aiProvider,
        'device',
      );
      if (selected case FailureResult<void>(:final Failure failure)) {
        await _storage.deleteSecret(SecretKey.providerCredential);
        if (mounted) {
          setState(() => _failure = failure);
        }
        return;
      }
    }
    _key.text = '';
    if (!mounted) {
      return;
    }
    setState(() {
      _failure = null;
      _saved = true;
    });
  }

  Future<void> _remove() async {
    final SettingsStore? settings = widget.settings;
    if (settings != null) {
      final Result<void> selected = await settings.write(
        SettingKeys.aiProvider,
        'backend',
      );
      if (selected case FailureResult<void>(:final Failure failure)) {
        if (mounted) {
          setState(() => _failure = failure);
        }
        return;
      }
    }
    final Result<void> removed = await _storage.deleteSecret(
      SecretKey.providerCredential,
    );
    if (removed case FailureResult<void>(:final Failure failure)) {
      if (mounted) {
        setState(() => _failure = failure);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _saved = false;
      _failure = null;
      _key.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: Copy.apiKeyTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(Copy.apiKeyCustody),
          if (_failure case final Failure failure)
            AppErrorState(failure: failure, onRetry: _load),
          AppTextField(
            label: Copy.apiKeyLabel,
            controller: _key,
            obscureText: _saved,
            dictation: false,
          ),
          if (_saved) const Text(Copy.apiKeySaved),
          AppButton(label: Copy.apiKeySave, onPressed: _save),
          AppButton(
            label: Copy.apiKeyRemove,
            variant: AppButtonVariant.secondary,
            onPressed: _saved ? _remove : null,
          ),
          ProviderTestAction(
            view: _test,
            onTest: widget.onTest == null
                ? null
                : () async {
                    final ProviderTestView next = await widget.onTest!();
                    if (mounted) {
                      setState(() => _test = next);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
