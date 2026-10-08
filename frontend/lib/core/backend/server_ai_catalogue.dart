import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'backend_api_client.dart';

/// Nonsecret provider/model capabilities refreshed from the authenticated server.
final class ServerAiCatalogue {
  /// Reads the last metadata snapshot immediately; refresh never blocks capture.
  ServerAiCatalogue({
    required this.send,
    this.readSnapshot,
    this.writeSnapshot,
  });

  /// Authenticated sender; no API key or project evidence enters the catalogue.
  final BackendSend send;

  /// Optional local metadata cache; user credentials are never included.
  final Object? Function()? readSnapshot;

  /// Persists validated metadata for model choices while offline.
  final Future<void> Function(List<Map<String, Object?>>)? writeSnapshot;

  List<Map<String, Object?>>? _rows;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Signals a durable validated catalogue refresh to Settings and other readers.
  Stream<void> get changes => _changes.stream;

  /// Releases catalogue listeners when the application scope closes.
  Future<void> dispose() => _changes.close();

  /// Display metadata for one exact configured provider.
  Map<String, Object?>? row(String? provider) => rows
      .where((Map<String, Object?> value) => value['provider'] == provider)
      .firstOrNull;

  /// Capabilities use the existing wire-to-domain operation mapping.
  Set<AiOperation> operations(String? provider) => <AiOperation>{
    for (final Object? operation
        in row(provider)?['operations'] as List<Object?>? ?? const <Object?>[])
      _operations[operation]!,
  };

  /// Configured provider/model entries, including explicit base-model costs.
  List<Map<String, Object?>> get rows =>
      _rows ??= _parse(readSnapshot?.call()) ?? const <Map<String, Object?>>[];

  /// The organisation's explicitly configured managed adapter.
  String? get managedProvider => rows
      .where(
        (Map<String, Object?> row) =>
            row['managed'] == true && row['authMode'] != 'none',
      )
      .map((Map<String, Object?> row) => row['provider']! as String)
      .firstOrNull;

  /// The deployment's conservative reservation for the selected account/model.
  ({double amount, String unit})? cost(String? provider, String model) {
    final String? id = provider ?? managedProvider;
    final Map<String, Object?>? row = rows
        .where((Map<String, Object?> row) => row['provider'] == id)
        .firstOrNull;
    if (row == null) return null;
    final String selected = model == 'default'
        ? row['model']! as String
        : model;
    final Map<String, double> costs =
        row['modelCostCeilings']! as Map<String, double>;
    final double? amount = costs[selected];
    return amount == null
        ? null
        : (amount: amount, unit: row['currency']! as String);
  }

  /// Models accepted for this account, always offering its configured default.
  List<ModelDescriptor> models(String? provider) {
    final String? id = provider ?? managedProvider;
    final Map<String, Object?>? row = rows
        .where((Map<String, Object?> row) => row['provider'] == id)
        .firstOrNull;
    final Set<AiOperation> operations = this.operations(id);
    final List<String> enabled = row == null
        ? const <String>[]
        : (row['models']! as List<Object?>).cast<String>();
    return <ModelDescriptor>[
      ModelDescriptor(
        id: 'default',
        label: row == null ? 'Configured default' : 'Default: ${row['model']}',
        operations: operations,
      ),
      for (final String model in enabled)
        if (model != 'default')
          ModelDescriptor(id: model, label: model, operations: operations),
    ];
  }

  /// Refreshes capabilities, validating before updating any local metadata.
  Future<Result<void>> refresh() async {
    try {
      final response = await send(method: 'GET', path: '/api/v1/ai/providers');
      if (response.status != 200) throw const NetworkFailure();
      final List<Map<String, Object?>>? parsed = _parse(
        response.body['providers'],
      );
      if (parsed == null) throw const FormatException();
      await writeSnapshot?.call(parsed);
      _rows = parsed;
      _changes.add(null);
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        error is Failure ? error : const NetworkFailure(),
      );
    }
  }

  List<Map<String, Object?>>? _parse(Object? raw) {
    if (raw is! List<Object?>) return null;
    final List<Map<String, Object?>> parsed = <Map<String, Object?>>[];
    final Set<String> ids = <String>{};
    for (final Object? value in raw) {
      if (value is! Map<String, Object?>) return null;
      final Object? id = value['provider'];
      final Object? model = value['model'];
      final Object? models = value['models'];
      final bool builtin = id == 'gemini' || id == 'openai';
      final bool legacy =
          builtin &&
          !value.containsKey('protocol') &&
          !value.containsKey('authMode');
      final Object? label = value['label'] ?? (legacy ? id : null);
      final Object? protocol =
          value['protocol'] ??
          (legacy
              ? id == 'gemini'
                    ? 'gemini-generate-content'
                    : 'openai-responses'
              : null);
      final Object? auth = value['authMode'] ?? (legacy ? 'required' : null);
      final Object? operations =
          value['operations'] ?? (legacy ? _operations.keys.toList() : null);
      if (id is! String ||
          !_providerId.hasMatch(id) ||
          !ids.add(id) ||
          label is! String ||
          label.trim().isEmpty ||
          !const [
            'gemini-generate-content',
            'openai-responses',
          ].contains(protocol) ||
          !const ['required', 'none'].contains(auth) ||
          model is! String ||
          model.isEmpty ||
          models is! List<Object?> ||
          models.isEmpty ||
          !models.contains(model) ||
          !models.every(
            (Object? model) => model is String && model.isNotEmpty,
          ) ||
          models.toSet().length != models.length ||
          operations is! List<Object?> ||
          operations.isEmpty ||
          operations.toSet().length != operations.length ||
          !operations.every(_operations.containsKey) ||
          (value['currency'] ?? (legacy ? 'configured' : null)) !=
              'configured') {
        return null;
      }
      final Map<String, double> costs = <String, double>{};
      if (value['modelCostCeilings'] case final Map<String, Object?> rawCosts) {
        for (final Object? entry in models) {
          final Object? amount = rawCosts[entry];
          if (amount is num &&
              amount.isFinite &&
              (amount > 0 || (builtin && amount == 0))) {
            costs[entry! as String] = amount.toDouble();
          }
        }
      }
      if (value['requestCostCeiling'] case final num amount when legacy) {
        if (amount.isFinite && amount > 0) {
          costs.putIfAbsent(model, () => amount.toDouble());
        }
      }
      if (!legacy && costs.length != models.length) return null;
      // Only these nonsecret fields may enter the durable cache.
      parsed.add(
        Map<String, Object?>.unmodifiable(<String, Object?>{
          'provider': id,
          'label': label,
          'protocol': protocol,
          'authMode': auth,
          'operations': List<Object?>.unmodifiable(operations),
          'model': model,
          'models': List<Object?>.unmodifiable(models),
          'managed': value['managed'] == true,
          'personalConfigured':
              auth == 'required' && value['personalConfigured'] == true,
          'requestCostCeiling': costs[model],
          'modelCostCeilings': Map<String, double>.unmodifiable(costs),
          'currency': 'configured',
        }),
      );
    }
    if (parsed
            .where(
              (Map<String, Object?> row) =>
                  row['managed'] == true && row['authMode'] == 'required',
            )
            .length >
        1) {
      return null;
    }
    return List<Map<String, Object?>>.unmodifiable(parsed);
  }
}

final RegExp _providerId = RegExp(r'^[a-z][a-z0-9-]{0,63}$');
const Map<String, AiOperation> _operations = <String, AiOperation>{
  'ocr': AiOperation.readText,
  'extract': AiOperation.extractFields,
  'refine': AiOperation.refineText,
  'transcribe': AiOperation.transcribe,
};

/// Invalidates registry consumers after metadata has been durably refreshed.
final ProviderListenable<AsyncValue<void>> serverAiCatalogueChangesProvider =
    StreamNotifierProvider<_CatalogueChanges, void>(_CatalogueChanges.new);

final class _CatalogueChanges extends StreamNotifier<void> {
  @override
  Stream<void> build() => ref.watch(serverAiCatalogueProvider).changes;

  // Every event signals a newly persisted snapshot, even though its value is void.
  @override
  bool updateShouldNotify(AsyncValue<void> previous, AsyncValue<void> next) =>
      true;
}

/// Bootstrap injects the signed-in catalogue; the default has no network.
final Provider<ServerAiCatalogue> serverAiCatalogueProvider =
    Provider<ServerAiCatalogue>(
      (Ref _) => ServerAiCatalogue(send: _unavailable),
    );

Future<({int status, Map<String, Object?> body})> _unavailable({
  required String method,
  required String path,
  Map<String, Object?>? body,
  String? token,
}) async => (status: 503, body: <String, Object?>{});
