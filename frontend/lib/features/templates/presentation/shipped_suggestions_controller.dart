import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/auxiliary_ai_usage.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/account/account.dart';
import 'package:tapture/features/processing/processing.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/shipped_template_entry.dart';
import '../domain/shipped_template_suggestions.dart';

/// AI availability is derived from offline, project and provider state together.
final shippedSuggestionServiceProvider = Provider.autoDispose<AiService?>((
  Ref ref,
) {
  ref.watch(backendConfigProvider);
  if (ref.watch(offlineNowProvider)) {
    return null;
  }
  final Project? project = ref.watch(currentProjectDetailsProvider);
  if (project == null) {
    return null;
  }
  final SettingsStore settings = ref.watch(projectSettingsStoreProvider);
  if (settings.read(SettingKeys.offlineByChoice) ||
      !project.settings
          .resolve(appProjectSettingsDefaults(settings))
          .aiEnabled) {
    return null;
  }
  final OperationChoice? choice =
      project.settings.providerSelection?[AiOperation.extractFields.name] ??
      OperationSelection.decode(
        settings.read(SettingKeys.aiProviderSelection),
      )[AiOperation.extractFields.name];
  final AiService service = ref
      .watch(providerRegistryProvider)
      .validateSelection(
        providerId: choice?.provider ?? settings.read(SettingKeys.aiProvider),
        modelId: choice?.model ?? settings.read(SettingKeys.aiModel),
        operation: AiOperation.extractFields,
        projectId: project.id,
      )
      .provider
      .service;
  return service.isAvailable ? service : null;
});

/// A proposal is ephemeral. Changing the description never changes selections.
final class ShippedSuggestionsController
    extends Notifier<ShippedSuggestionsState> {
  @override
  ShippedSuggestionsState build() =>
      (busy: false, query: '', keys: const <String>[], failure: null);

  /// Reserves a durable daily request before sending the catalogue-only request.
  Future<void> suggest(
    String query,
    List<ShippedTemplateEntry> candidates,
  ) async {
    if (state.busy) {
      return;
    }
    final AiService? service = ref.read(shippedSuggestionServiceProvider);
    final Project? project = ref.read(currentProjectDetailsProvider);
    if (service == null || project == null) {
      return;
    }
    state = (busy: true, query: query, keys: const <String>[], failure: null);
    try {
      final SettingsStore settings = ref.read(projectSettingsStoreProvider);
      final DateTime now = const SystemClock().nowUtc();
      final Result<({int requests, int images})> usage = await ref
          .read(processingRepositoryProvider)
          .usageOn(now, projectId: project.id);
      final int requests = switch (usage) {
        Success<({int requests, int images})>(:final value) => value.requests,
        FailureResult<({int requests, int images})>(:final failure) =>
          throw failure,
      };
      final int cap = project.settings
          .resolve(appProjectSettingsDefaults(settings))
          .dailyRequestCap;
      if (requests >= cap) {
        throw const ProviderFailure(
          message: 'The daily analysis limit is reached.',
          recoveryAction: 'Use the on-device suggestions or try tomorrow.',
          kind: ProviderFailureKind.rateLimited,
        );
      }
      if (!ref.mounted || ref.read(shippedSuggestionServiceProvider) == null) {
        return;
      }
      final Result<void> reserved = await settings.write(
        SettingKeys.aiAuxiliaryUsage,
        AuxiliaryAiUsage(
          settings.read(SettingKeys.aiAuxiliaryUsage),
        ).reserve(now, project.id),
      );
      if (reserved case FailureResult<void>(:final failure)) {
        throw failure;
      }
      final Result<List<String>> result =
          await ShippedTemplateSuggestions(service).suggest(
            query,
            candidates
                .take(AppConstants.aiTemplateCandidateLimit)
                .toList(growable: false),
          );
      if (!ref.mounted) {
        return;
      }
      state = switch (result) {
        Success<List<String>>(:final value) => (
          busy: false,
          query: query,
          keys: value,
          failure: null,
        ),
        FailureResult<List<String>>(:final failure) => (
          busy: false,
          query: query,
          keys: const <String>[],
          failure: failure,
        ),
      };
    } on Object catch (error) {
      if (ref.mounted) {
        state = (
          busy: false,
          query: query,
          keys: const <String>[],
          failure: Failure.from(error),
        );
      }
    }
  }

  /// Discards only the suggested order; picked templates remain untouched.
  void clear() => state = (
    busy: state.busy,
    query: '',
    keys: const <String>[],
    failure: null,
  );
}

/// Whether a suggestion request is running, the description it answered, the
/// suggested template keys in order, and why the last request failed.
typedef ShippedSuggestionsState = ({
  bool busy,
  String query,
  List<String> keys,
  Failure? failure,
});

/// Retained while the picker is open so resize never loses the proposal.
final shippedSuggestionsProvider =
    NotifierProvider.autoDispose<
      ShippedSuggestionsController,
      ShippedSuggestionsState
    >(ShippedSuggestionsController.new);
