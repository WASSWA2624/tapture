import 'dart:async';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/device/platform_facts.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/templates/domain/domain.dart';

import '../domain/capture_device_source.dart';
import '../domain/capture_session.dart';

/// Opted-in local interface readings through the existing core platform port.
final class CaptureDeviceSources implements CaptureDeviceSource {
  /// Creates a source without reading the platform until an eligible bind.
  CaptureDeviceSources({
    required Clock clock,
    required Future<PlatformFacts> Function() readFacts,
  }) : _clock = clock,
       _readFacts = readFacts;

  final Clock _clock;
  final Future<PlatformFacts> Function() _readFacts;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  CaptureSession? _owner;
  String? _address;
  DateTime? _completedAt;
  Timer? _expiry;
  int _generation = 0;
  bool _eligible = false;
  bool _disposed = false;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  void bind(CaptureSession session, Iterable<FieldDef> fields) {
    if (_disposed) return;
    final bool eligible =
        session.id.isNotEmpty &&
        session.projectId.isNotEmpty &&
        session.templateId.isNotEmpty &&
        session.templateVersion != 0 &&
        !session.editing &&
        session.recordId == null &&
        fields.any(
          (FieldDef field) =>
              field.type == FieldType.text &&
              field.autoFill == AutoFill.localAddress &&
              !_opaque(field),
        );
    if (_sameOwner(session) && eligible == _eligible) return;
    _generation += 1;
    _owner = session;
    _eligible = eligible;
    _clear();
    _changes.add(null);
    if (eligible) refresh();
  }

  @override
  void refresh() {
    if (_disposed || !_eligible) return;
    final int generation = ++_generation;
    // Only completed reads can be sampled; previous measurements are not
    // carried across an explicit refresh or a failed enumeration.
    _clear();
    _changes.add(null);
    unawaited(_read(generation));
  }

  Future<void> _read(int generation) async {
    String? address;
    try {
      final PlatformFacts facts = await _readFacts();
      if (facts.platform != 'web') address = _select(facts.addresses);
    } on Object {
      // Device capability failures are represented by an unavailable sample.
      address = null;
    }
    if (_disposed || generation != _generation || !_eligible) return;
    _address = address;
    _completedAt = address == null ? null : _clock.nowUtc();
    if (address != null) {
      _expiry = Timer(AppConstants.capture.deviceReadingFreshness, () {
        if (_disposed || generation != _generation) return;
        _clear();
        _changes.add(null);
      });
    }
    _changes.add(null);
  }

  @override
  String? snapshot(CaptureSession session) {
    if (_disposed || !_eligible || !_sameOwner(session)) return null;
    final DateTime? completed = _completedAt;
    if (completed == null) return null;
    final Duration age = _clock.nowUtc().difference(completed);
    if (age.isNegative || age >= AppConstants.capture.deviceReadingFreshness) {
      return null;
    }
    return _address;
  }

  bool _sameOwner(CaptureSession session) =>
      _owner?.id == session.id &&
      _owner?.projectId == session.projectId &&
      _owner?.storageKey == session.storageKey &&
      _owner?.templateId == session.templateId &&
      _owner?.templateVersion == session.templateVersion &&
      _owner?.recordId == session.recordId;

  void _clear() {
    _expiry?.cancel();
    _expiry = null;
    _address = null;
    _completedAt = null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation += 1;
    _clear();
    unawaited(_changes.close());
  }
}

bool _opaque(FieldDef field) => switch (field.validation['_tapture']) {
  final Map<Object?, Object?> metadata => metadata['autoFill'] != null,
  _ => false,
};

String? _select(List<String> addresses) {
  final List<String> ipv4 = <String>[];
  final List<String> ipv6 = <String>[];
  for (final String address in addresses) {
    // Preserve the scalar reported by the platform, without inventing an
    // address from malformed or whitespace-padded input.
    if (address != address.trim()) continue;
    final List<int>? four = _ipv4(address);
    if (four != null) {
      if (_eligible4(four)) ipv4.add(address);
      continue;
    }
    final List<int>? six = _ipv6(address);
    if (six != null && _eligible6(six)) ipv6.add(address);
  }
  ipv4.sort();
  ipv6.sort();
  return ipv4.firstOrNull ?? ipv6.firstOrNull;
}

List<int>? _ipv4(String address) {
  final List<String> pieces = address.split('.');
  if (pieces.length != 4) return null;
  final List<int> bytes = <int>[];
  for (final String piece in pieces) {
    if (!_decimalByte.hasMatch(piece)) return null;
    final int byte = int.parse(piece);
    if (byte > 255) return null;
    bytes.add(byte);
  }
  return bytes;
}

bool _eligible4(List<int> bytes) =>
    bytes.first != 0 &&
    bytes.first != 127 &&
    bytes.first < 224 &&
    !(bytes[0] == 169 && bytes[1] == 254);

List<int>? _ipv6(String address) {
  if (!address.contains(':') || address.contains('%')) return null;
  String value = address;
  if (value.contains('.')) {
    final int split = value.lastIndexOf(':');
    final List<int>? tail = _ipv4(value.substring(split + 1));
    if (tail == null) return null;
    value =
        '${value.substring(0, split + 1)}'
        '${((tail[0] << 8) | tail[1]).toRadixString(16)}:'
        '${((tail[2] << 8) | tail[3]).toRadixString(16)}';
  }
  final List<String> compressed = value.split('::');
  if (compressed.length > 2) return null;
  List<int>? groups(String part) {
    if (part.isEmpty) return <int>[];
    final List<int> found = <int>[];
    for (final String group in part.split(':')) {
      if (!_hexGroup.hasMatch(group)) return null;
      found.add(int.parse(group, radix: 16));
    }
    return found;
  }

  final List<int>? left = groups(compressed.first);
  final List<int>? right = compressed.length == 2
      ? groups(compressed.last)
      : <int>[];
  if (left == null || right == null) return null;
  final int count = left.length + right.length;
  if (compressed.length == 1 && count != 8) return null;
  if (compressed.length == 2 && count >= 8) return null;
  return <int>[...left, ...List<int>.filled(8 - count, 0), ...right];
}

bool _eligible6(List<int> groups) {
  if (groups.every((int value) => value == 0)) return false;
  if (groups.take(7).every((int value) => value == 0) && groups.last == 1) {
    return false;
  }
  if ((groups.first & 0xff00) == 0xff00 || (groups.first & 0xffc0) == 0xfe80) {
    return false;
  }
  if (groups.take(5).every((int value) => value == 0) && groups[5] == 0xffff) {
    return _eligible4(<int>[
      groups[6] >> 8,
      groups[6] & 0xff,
      groups[7] >> 8,
      groups[7] & 0xff,
    ]);
  }
  return true;
}

final RegExp _decimalByte = RegExp(r'^(0|[1-9][0-9]{0,2})$');
final RegExp _hexGroup = RegExp(r'^[0-9a-fA-F]{1,4}$');
