import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import 'account_session.dart';
import 'sign_in_controller.dart';

/// The server address an administrator sets once for a self-hosted install.
/// A build that names its server never shows it.
class ServerAddressForm extends ConsumerStatefulWidget {
  /// Creates the form over the session's cached configuration.
  const ServerAddressForm({super.key});

  @override
  ConsumerState<ServerAddressForm> createState() => _ServerAddressFormState();
}

class _ServerAddressFormState extends ConsumerState<ServerAddressForm> {
  final TextEditingController _server = TextEditingController();
  final TextEditingController _organisation = TextEditingController();

  @override
  void initState() {
    super.initState();
    final BackendConfig? config = ref.read(backendSessionProvider)?.config;
    _server.text = config?.baseUrl ?? '';
    _organisation.text = config?.organisationId ?? '';
  }

  @override
  void dispose() {
    _server.dispose();
    _organisation.dispose();
    super.dispose();
  }

  Future<bool> _save() {
    return ref.read(signInControllerProvider.notifier).submit(() async {
      final BackendSession? session = ref.read(backendSessionProvider);
      if (session == null) {
        throw const NetworkFailure();
      }
      final Result<void> result = await session.configure(
        _server.text,
        _organisation.text,
      );
      if (result case FailureResult<void>(:final Failure failure)) {
        throw failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final SignInState view = ref.watch(signInControllerProvider);
    final String? error = view.errorMessage == null
        ? view.error
        : localCopy.resolve(view.errorMessage!);
    return AppPage(
      title: localCopy.backendSettingsTitle,
      scrollable: false,
      body: AppForm(
        errors: <String>[?error],
        fields: <Widget>[
          Text(
            localCopy.backendConfigurationHelp,
            style: AppText.body.copyWith(color: context.colors.onSurfaceMuted),
          ),
          AppTextField(
            label: localCopy.backendServerAddress,
            controller: _server,
            keyboardType: TextInputType.url,
            requiredness: FieldRequiredness.required,
          ),
          AppTextField(
            label: localCopy.signInOrganisation,
            controller: _organisation,
            requiredness: FieldRequiredness.optional,
          ),
        ],
        submitLabel: localCopy.save,
        onSubmit: _save,
      ),
    );
  }
}
