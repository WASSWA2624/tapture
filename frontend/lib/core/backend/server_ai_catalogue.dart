import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Configured provider/model entries, including explicit base-model costs.
  List<Map<String, Object?>> get rows => _rows ?? _parse(readSnapshot?.call());

  /// The organisation's explicitly configured managed adapter.
  String? get managedProvider => rows
      .where((Map<String, Object?> row) => row['managed'] == true)
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
    final Set<AiOperation> operations = AiOperation.values.toSet();
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
        if (model != row?['model'])
          ModelDescriptor(id: model, label: model, operations: operations),
    ];
  }

  /// Refreshes capabilities, validating before updating any local metadata.
  Future<Result<void>> refresh() async {
    try {
      final response = await send(method: 'GET', path: '/api/v1/ai/providers');
      if (response.status != 200) throw const NetworkFailure();
      final List<Map<String, Object?>> parsed = _parse(
        response.body['providers'],
      );
      if (parsed.isEmpty) throw const FormatException();
      await writeSnapshot?.call(parsed);
      _rows = parsed;
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        error is Failure ? error : const NetworkFailure(),
      );
    }
  }

  List<Map<String, Object?>> _parse(Object? raw) {
    if (raw is! List<Object?>) return const <Map<String, Object?>>[];
    final List<Map<String, Object?>> parsed = <Map<String, Object?>>[];
    for (final Object? value in raw) {
      if (value is! Map<String, Object?> ||
          value['provider'] is! String ||
          value['model'] is! String ||
          value['models'] is! List<Object?> ||
          !(value['models']! as List<Object?>).every(
            (Object? model) => model is String,
          )) {
        continue;
      }
      // Allowlisted display metadata prevents a response adding secrets to cache.
      final List<Object?> models = value['models']! as List<Object?>;
      final Map<String, double> costs = <String, double>{};
      if (value['modelCostCeilings'] case final Map<String, Object?> rawCosts) {
        for (final MapEntry<String, Object?> entry in rawCosts.entries) {
          if (entry.value case final num amount
              when models.contains(entry.key)) {
            if (amount.isFinite && amount >= 0) {
              costs[entry.key] = amount.toDouble();
            }
          }
        }
      }
      if (value['requestCostCeiling'] case final num amount) {
        if (amount.isFinite && amount >= 0) {
          costs.putIfAbsent(value['model']! as String, () => amount.toDouble());
        }
      }
      parsed.add(
        Map<String, Object?>.unmodifiable(<String, Object?>{
          'provider': value['provider'],
          'model': value['model'],
          'models': List<Object?>.unmodifiable(
            value['models']! as List<Object?>,
          ),
          'managed': value['managed'] == true,
          'requestCostCeiling': value['requestCostCeiling'] is num
              ? value['requestCostCeiling']
              : null,
          'modelCostCeilings': Map<String, double>.unmodifiable(costs),
          'currency': value['currency'] is String
              ? value['currency']
              : 'configured',
        }),
      );
    }
    return List<Map<String, Object?>>.unmodifiable(parsed);
  }
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
