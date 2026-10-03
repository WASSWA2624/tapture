import 'dart:convert';

import 'package:tapture/core/ai/ai_operation.dart';

/// Explicit outbound permissions. New and legacy implicit paths stay off.
final class EgressSwitches {
  /// Creates the switches from the ids of the paths that are off.
  const EgressSwitches(this.off, {this.on = const <String>{}});

  /// Reads saved permissions without treating missing data as consent.
  factory EgressSwitches.decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const EgressSwitches(<String>{});
    }
    if (decoded is Map<String, Object?>) {
      return EgressSwitches(_paths(decoded['off']), on: _paths(decoded['on']));
    }
    return EgressSwitches(_paths(decoded));
  }

  /// Ids of the outbound paths that are switched off.
  final Set<String> off;

  /// Paths enabled by an explicit privacy-page choice.
  final Set<String> on;

  /// The path id of an analysis [operation].
  static String ai(AiOperation operation) => 'ai.${operation.name}';

  /// The path id of uploads to one destination.
  static String upload(String destinationId) => 'upload.$destinationId';

  /// Whether [path] may send.
  bool allows(String path) => on.contains(path) && !off.contains(path);

  /// The same switches with [path] turned [on] or off.
  EgressSwitches toggled(String path, {required bool on}) {
    final Set<String> next = Set<String>.of(off);
    final Set<String> allowed = Set<String>.of(this.on);
    if (on) {
      next.remove(path);
      allowed.add(path);
    } else {
      next.add(path);
      allowed.remove(path);
    }
    return EgressSwitches(next, on: allowed);
  }

  /// The stored JSON, ids in a stable order.
  String encode() => jsonEncode(<String, Object?>{
    'off': off.toList()..sort(),
    'on': on.toList()..sort(),
  });

  static Set<String> _paths(Object? raw) => <String>{
    if (raw is List<Object?>)
      for (final Object? path in raw)
        if (path is String && path.isNotEmpty) path,
  };
}
