import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/backend/server_ai_catalogue.dart';
import 'package:tapture/core/backend/server_credential_client.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart';

import 'provider_test_action.dart';
import 'settings_disclosure.dart';

part 'ai_provider_settings_controller.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Registry-driven provider and model settings. No provider id is hardcoded in
/// presentation code; adding a descriptor updates this screen automatically.
///
/// The screen owns only the key field's controller; the choice, the saved-key
/// flag and every outcome live in [aiProviderSettingsProvider].
final class AiProviderSettingsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AiProviderSettingsScreen({super.key});

  @override
  ConsumerState<AiProviderSettingsScreen> createState() =>
      _AiProviderSettingsScreenState();
}

class _AiProviderSettingsScreenState
    extends ConsumerState<AiProviderSettingsScreen> {
  final TextEditingController _credential = TextEditingController();
  final TextEditingController _approvedCost = TextEditingController();

  @override
  void initState() {
    super.initState();
    final double cost = ref
        .read(projectSettingsStoreProvider)
        .read(SettingKeys.aiRequestMaxCost);
    if (cost > 0) _approvedCost.text = cost.toString();
  }

  @override
  void dispose() {
    _credential.dispose();
    _approvedCost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final _AiView view = ref.watch(aiProviderSettingsProvider);
    final _AiSettings controller = ref.read(
      aiProviderSettingsProvider.notifier,
    );
    final ProviderDescriptor provider = controller.provider;
    final List<ModelDescriptor> models = controller.models;
    final cost = ref
        .read(serverAiCatalogueProvider)
        .cost(
          provider.serverProvider ?? provider.serverCredentialProvider,
          controller.model.id,
        );
    final double savedLimit = ref.read(projectSettingsStoreProvider)
        .read(SettingKeys.aiRequestMaxCost);
    return AppPage(
      title: localCopy.settingsAiTitle,
      footer: AppPrimaryAction(
        key: const ValueKey<String>('ai-save'),
        label: localCopy.save,
        busy: view.busy,
        onPressed: view.busy ? null : () => unawaited(_save()),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppChoiceField<String>(
            label: localCopy.aiSupportedProviders,
            alwaysSheet: true,
            enabled: !view.busy,
            value: provider.id,
            options: <Choice<String>>[
              for (final ProviderDescriptor value in controller.providers)
                Choice<String>(value.id, value.label),
            ],
            onChanged: (String? value) {
              if (value != null) {
                _credential.clear();
                controller.selectProvider(value);
              }
            },
          ),
          const SizedBox(height: Space.x3),
          AppBanner(
            key: const ValueKey<String>('ai-custody'),
            message: provider.serverCredentialProvider != null
                ? localCopy.serverApiKeyCustody
                : localCopy.aiCustody(
                    provider.keyCustody.name,
                    provider.available,
                  ),
            icon: provider.available ? AppIcons.key : AppIcons.warning,
            tone: provider.available ? SnackTone.info : SnackTone.warning,
          ),
          if (view.fellBack) ...<Widget>[
            const SizedBox(height: Space.x2),
            AppBanner(
              key: const ValueKey<String>('ai-fell-back'),
              message: localCopy.aiSelectionFallback,
              icon: AppIcons.warning,
              tone: SnackTone.warning,
            ),
          ],
          if (provider.serverCredentialProvider != null ||
              (provider.deviceKeyAllowed &&
                  provider.keyCustody ==
                      ProviderKeyCustody.device)) ...<Widget>[
            const SizedBox(height: Space.x3),
            AppTextField(
              label: localCopy.apiKeyLabel,
              helper: view.keyStored
                  ? provider.serverCredentialProvider != null
                        ? localCopy.serverApiKeySaved
                        : localCopy.apiKeySaved
                  : null,
              controller: _credential,
              obscureText: true,
              dictation: false,
            ),
            if (view.keyStored) ...<Widget>[
              const SizedBox(height: Space.x2),
              AppButton(
                key: const ValueKey<String>('ai-remove-key'),
                label: localCopy.apiKeyRemove,
                variant: AppButtonVariant.destructive,
                onPressed: view.busy
                    ? null
                    : () => unawaited(_confirmRemoveCredential()),
              ),
            ],
          ],
          const SizedBox(height: Space.x3),
          AppChoiceField<String>(
            label: localCopy.aiModel,
            alwaysSheet: true,
            enabled: !view.busy,
            value: controller.model.id,
            options: <Choice<String>>[
              for (final ModelDescriptor value in models)
                Choice<String>(value.id, value.label),
            ],
            onChanged: (String? value) {
              if (value != null) controller.selectModel(value);
            },
          ),
          const SizedBox(height: Space.x3),
          SettingsDisclosure(
            id: 'ai-cost',
            title: localCopy.aiCostControls,
            summary: savedLimit > 0
                ? localCopy.aiRequestLimitSummary(savedLimit.toString())
                : localCopy.processingEgressLimitDefault,
            children: <Widget>[
              if (cost != null) AppBanner(
                message: localCopy.aiModelCostCeiling(cost.amount.toString(), cost.unit),
                icon: AppIcons.info, tone: SnackTone.info,
              ),
              AppTextField(
                label: localCopy.aiSpendingLimit,
                helper: localCopy.aiSpendingLimitHint,
                controller: _approvedCost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                dictation: false,
              ),
            ],
          ),
          if (view.failure case final Failure failure) ...<Widget>[
            AppBanner(
              message: <String>[
                localCopy.failureMessage(failure),
                if (localCopy.failureRecovery(failure)
                    case final String recovery)
                  recovery,
              ].join(' '),
              icon: AppIcons.warning,
              tone: SnackTone.warning,
            ),
            AppButton(
              label: localCopy.tryAgain,
              variant: AppButtonVariant.secondary,
              onPressed: view.busy
                  ? null
                  : () => unawaited(controller.retryStatus()),
            ),
          ],
          const SizedBox(height: Space.x3),
          ProviderTestAction(
            view: provider.available ? view.test : ProviderTestView.unavailable,
            onTest: provider.available
                ? () => unawaited(controller.testConnection())
                : null,
          ),
          const SizedBox(height: Space.x3),
          AppButton(
            key: const ValueKey<String>('ai-server-account'),
            label: localCopy.aiServerAndAccount,
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                unawaited(context.push(RoutePaths.settingsAccount)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final SettingsStore settings = ref.read(projectSettingsStoreProvider);
    final double previous = settings.read(SettingKeys.aiRequestMaxCost);
    final double? proposed = double.tryParse(_approvedCost.text.trim());
    if (proposed != null && proposed.isFinite && proposed > previous) {
      final LocalizedCopy copy = Copy.of(context);
      final bool approved = await showAppConfirm(
        context,
        title: copy.aiSpendingLimit,
        message: copy.aiModelCostCeiling(proposed.toString(), 'configured'),
        confirmLabel: copy.save,
      );
      if (!approved || !mounted) return;
    }
    final bool saved = await ref
        .read(aiProviderSettingsProvider.notifier)
        .save(_credential.text, approvedCost: _approvedCost.text);
    if (saved && mounted) {
      _credential.clear();
    }
  }

  /// Asks first, then removes the key and the selection that needed it in
  /// one action, so nothing is left pointing at a key that is gone.
  Future<void> _confirmRemoveCredential() async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.apiKeyRemoveTitle,
      message:
          ref
                  .read(aiProviderSettingsProvider.notifier)
                  .provider
                  .serverCredentialProvider !=
              null
          ? localCopy.serverCredentialRemoveMessage
          : localCopy.apiKeyRemoveMessage,
      confirmLabel: localCopy.apiKeyRemove,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await ref.read(aiProviderSettingsProvider.notifier).removeCredential();
  }
}
