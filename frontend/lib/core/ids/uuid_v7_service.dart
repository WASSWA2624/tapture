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
    final int ms = clock.nowUtc().millisecondsSinceEpoch % _timestampModulus;
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

/// 2^48: RFC 9562 keeps the low 48 bits of the Unix-millisecond timestamp.
const int _timestampModulus = 0x1000000000000;

/// Upper bound for the random tail drawn at the start of a millisecond.
const int _newMsSeqBound = 0x7fffffff;

/// 2^32. On the web an int is a JS number whose bitwise operators keep only
/// 32 bits, so wider values are split into words with `~/` and `%` (exact up
/// to 2^53) before any `&` or `>>`.
const int _word = 0x100000000;

String _format(int ms, int seq) {
  final int msHigh = ms ~/ _word;
  final int msLow = ms % _word;
  // rand_b is the low 62 bits of the tail: 30 in the high word, 32 in the low.
  final int randBHigh = (seq ~/ _word) & 0x3FFFFFFF;
  final int randBLow = seq % _word;
  final List<int> bytes = <int>[
    (msHigh >> 8) & 0xFF,
    msHigh & 0xFF,
    (msLow >> 24) & 0xFF,
    (msLow >> 16) & 0xFF,
    (msLow >> 8) & 0xFF,
    msLow & 0xFF,
    0x70,
    0x00,
    0x80 | (randBHigh >> 24),
    (randBHigh >> 16) & 0xFF,
    (randBHigh >> 8) & 0xFF,
    randBHigh & 0xFF,
    (randBLow >> 24) & 0xFF,
    (randBLow >> 16) & 0xFF,
    (randBLow >> 8) & 0xFF,
    randBLow & 0xFF,
  ];
  String hex(int index) => bytes[index].toRadixString(16).padLeft(2, '0');
  return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
      '${hex(4)}${hex(5)}-'
      '${hex(6)}${hex(7)}-'
      '${hex(8)}${hex(9)}-'
      '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
}
