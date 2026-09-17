part of 'uuid_service.dart';

/// Time-ordered UUIDv7 identifiers, built from a [Clock] plus a random tail.
final class UuidV7Service implements IdService {
  /// Creates a generator that draws the tail from [random], or from
  /// [Random] when none is given.
  UuidV7Service(this.clock, {Random? random})
    : _random = random ?? Random(),
      _sequence = false;

  /// A deterministic incrementing tail, for tests (FE-TEST-03).
  UuidV7Service.sequence(this.clock) : _random = null, _sequence = true;

  /// The clock the timestamp half is read from.
  final Clock clock;

  final Random? _random;
  final bool _sequence;

  int _lastMs = -1;
  int _seq = -1;

  @override
  String newId() {
    final int ms = clock.nowUtc().millisecondsSinceEpoch & _timestampMask;
    if (_sequence) {
      _seq++;
      _lastMs = ms;
      return _format(ms, _seq);
    }
    if (ms != _lastMs) {
      _lastMs = ms;
      _seq = _random!.nextInt(_newMsSeqBound);
    } else {
      _seq++;
    }
    return _format(ms, _seq);
  }
}

/// 48-bit Unix-millisecond mask from RFC 9562.
const int _timestampMask = 0xFFFFFFFFFFFF;

/// Upper bound for the random tail drawn at the start of a millisecond.
const int _newMsSeqBound = 0x7fffffff;

String _format(int ms, int seq) {
  final int randB = seq & _randBMask;
  final List<int> bytes = <int>[
    (ms >> 40) & 0xFF,
    (ms >> 32) & 0xFF,
    (ms >> 24) & 0xFF,
    (ms >> 16) & 0xFF,
    (ms >> 8) & 0xFF,
    ms & 0xFF,
    0x70,
    0x00,
    0x80 | ((randB >> 56) & 0x3F),
    (randB >> 48) & 0xFF,
    (randB >> 40) & 0xFF,
    (randB >> 32) & 0xFF,
    (randB >> 24) & 0xFF,
    (randB >> 16) & 0xFF,
    (randB >> 8) & 0xFF,
    randB & 0xFF,
  ];
  String hex(int index) => bytes[index].toRadixString(16).padLeft(2, '0');
  return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
      '${hex(4)}${hex(5)}-'
      '${hex(6)}${hex(7)}-'
      '${hex(8)}${hex(9)}-'
      '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
}

/// 62-bit rand_b mask from RFC 9562.
const int _randBMask = 0x3FFFFFFFFFFFFFFF;
