import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import 'account_session.dart';
import 'sign_in_controller.dart';

/// The server address an administrator sets once for a self-hosted install.
/// A build that names its server never shows it.
class ServerAddressForm extends ConsumerStatefulWidget {
  /// Creates the form over the session's cached configuration.
  const ServerAddressForm({super.key, this.inline = false});

  /// Presents secondary setup controls inside an existing page.
  final bool inline;

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
    final List<Widget> fields = <Widget>[
      Text(
        localCopy.backendConfigurationHelp,
        style: AppText.body.copyWith(color: context.colors.onSurfaceMuted),
      ),
      AppTextField(
        label: localCopy.backendServerAddress,
        wrapLabel: true,
        controller: _server,
        keyboardType: TextInputType.url,
        requiredness: FieldRequiredness.required,
      ),
      AppTextField(
        label: localCopy.signInOrganisation,
        wrapLabel: true,
        controller: _organisation,
        requiredness: FieldRequiredness.optional,
      ),
    ];
    if (widget.inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (error != null) ...<Widget>[
            AppBanner(
              message: error,
              icon: AppIcons.warning,
              tone: SnackTone.warning,
            ),
            const SizedBox(height: Space.x3),
          ],
          for (int index = 0; index < fields.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(height: Space.x3),
            fields[index],
          ],
          const SizedBox(height: Space.x3),
          AppButton(
            label: localCopy.backendConfigure,
            variant: AppButtonVariant.secondary,
            busy: view.busy,
            onPressed: view.busy ? null : () => unawaited(_save()),
          ),
        ],
      );
    }
    return AppPage(
      title: localCopy.backendSettingsTitle,
      scrollable: false,
      body: AppForm(
        errors: <String>[?error],
        fields: fields,
        submitLabel: localCopy.save,
        onSubmit: _save,
      ),
    );
  }
}
