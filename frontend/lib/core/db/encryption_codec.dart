part of 'encryption.dart';

const String _plainName = 'tapture.sqlite';
const String _encName = 'tapture.sqlite.enc';
const String _partialName = 'tapture.sqlite.enc.partial';
const String _bakName = 'tapture.sqlite.bak';
const String _stateName = 'tapture.encryption';

const int _nonceLength = 16;
const int _macLength = 32;
const int _blockLength = 32;
const List<int> _magic = <int>[84, 65, 80, 69, 78, 67, 48, 49];
const List<int> _encLabel = <int>[101, 110, 99];
const List<int> _macLabel = <int>[109, 97, 99];

void _configureSqlite(sqlite3_raw.Database database) {
  database.execute('PRAGMA journal_mode = WAL;');
  database.execute('PRAGMA foreign_keys = ON;');
}

Future<Result<void>> _cryptFile({
  required File source,
  required File dest,
  required String key,
  required bool encrypt,
  void Function(double)? onProgress,
}) {
  return runIsolate(_cryptInIsolate, <Object>[
    source.path,
    dest.path,
    key,
    encrypt,
  ], onProgress: onProgress);
}

Future<void> _cryptInIsolate(List<Object> job) async {
  final String source = job[0] as String;
  final String dest = job[1] as String;
  final Uint8List keyBytes = _fromHex(job[2] as String);
  final bool encrypt = job[3] as bool;
  final List<int> encKey = Hmac(sha256, keyBytes).convert(_encLabel).bytes;
  final List<int> macKey = Hmac(sha256, keyBytes).convert(_macLabel).bytes;
  if (encrypt) {
    _encryptPath(source, dest, encKey, macKey);
  } else {
    _decryptPath(source, dest, encKey, macKey);
  }
}

void _encryptPath(
  String source,
  String dest,
  List<int> encKey,
  List<int> macKey,
) {
  final File inFile = File(source);
  final int length = inFile.lengthSync();
  final Uint8List nonce = _randomBytes(_nonceLength);
  final Uint8List header = Uint8List(_magic.length + _nonceLength + 8);
  header.setAll(0, _magic);
  header.setAll(_magic.length, nonce);
  _putUint64(header, _magic.length + _nonceLength, length);
  final RandomAccessFile input = inFile.openSync();
  final RandomAccessFile output = File(dest).openSync(mode: FileMode.write);
  final _DigestSink macOut = _DigestSink();
  final ByteConversionSink mac = Hmac(
    sha256,
    macKey,
  ).startChunkedConversion(macOut);
  final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes);
  var offset = 0;
  try {
    output.writeFromSync(header);
    mac.add(header);
    while (true) {
      final int n = input.readIntoSync(buffer);
      if (n == 0) {
        break;
      }
      final Uint8List chunk = n == buffer.length
          ? buffer
          : Uint8List.fromList(buffer.sublist(0, n));
      _xor(chunk, encKey, nonce, offset);
      output.writeFromSync(chunk);
      mac.add(chunk);
      offset += n;
      if (length > 0) {
        IsolateRunner.reportProgress(offset / length);
      }
    }
    mac.close();
    output.writeFromSync(Uint8List.fromList(macOut.digest.bytes));
    IsolateRunner.reportProgress(1);
  } finally {
    input.closeSync();
    output.closeSync();
  }
}

void _decryptPath(
  String source,
  String dest,
  List<int> encKey,
  List<int> macKey,
) {
  final File inFile = File(source);
  final int total = inFile.lengthSync();
  final int minLength = _magic.length + _nonceLength + 8 + _macLength;
  if (total < minLength) {
    throw const FormatException('short');
  }
  final RandomAccessFile input = inFile.openSync();
  final RandomAccessFile output = File(dest).openSync(mode: FileMode.write);
  final _DigestSink macOut = _DigestSink();
  final ByteConversionSink mac = Hmac(
    sha256,
    macKey,
  ).startChunkedConversion(macOut);
  try {
    final Uint8List header = Uint8List(_magic.length + _nonceLength + 8);
    input.readIntoSync(header);
    if (!_bytesEqual(header.sublist(0, _magic.length), _magic)) {
      throw const FormatException('magic');
    }
    final List<int> nonce = header.sublist(
      _magic.length,
      _magic.length + _nonceLength,
    );
    final int length = _getUint64(header, _magic.length + _nonceLength);
    if (total != minLength + length) {
      throw const FormatException('length');
    }
    mac.add(header);
    final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes);
    var offset = 0;
    while (offset < length) {
      final int n = input.readIntoSync(
        buffer,
        0,
        min(buffer.length, length - offset),
      );
      if (n == 0) {
        throw const FormatException('truncated');
      }
      final Uint8List chunk = n == buffer.length
          ? buffer
          : Uint8List.fromList(buffer.sublist(0, n));
      mac.add(chunk);
      _xor(chunk, encKey, nonce, offset);
      output.writeFromSync(chunk);
      offset += n;
      if (length > 0) {
        IsolateRunner.reportProgress(offset / length);
      }
    }
    mac.close();
    final Uint8List tag = Uint8List(_macLength);
    input.readIntoSync(tag);
    if (!_bytesEqual(tag, macOut.digest.bytes)) {
      throw const FormatException('mac');
    }
    IsolateRunner.reportProgress(1);
  } catch (_) {
    output.closeSync();
    _deleteFile(File(dest));
    rethrow;
  } finally {
    input.closeSync();
    try {
      output.closeSync();
    } on FileSystemException {
      // Already closed after a failed MAC.
    }
  }
}

void _xor(Uint8List data, List<int> encKey, List<int> nonce, int startByte) {
  var i = 0;
  while (i < data.length) {
    final int abs = startByte + i;
    final int skip = abs & 31;
    final List<int> stream = _keystream(encKey, nonce, abs >> 5);
    final int n = min(_blockLength - skip, data.length - i);
    for (int j = 0; j < n; j++) {
      data[i + j] ^= stream[skip + j];
    }
    i += n;
  }
}

List<int> _keystream(List<int> encKey, List<int> nonce, int block) {
  final Uint8List material = Uint8List(_nonceLength + 8);
  material.setAll(0, nonce);
  _putUint64(material, _nonceLength, block);
  return Hmac(sha256, encKey).convert(material).bytes;
}

String _newKey() {
  return _toHex(_randomBytes(32));
}

Uint8List _randomBytes(int length) {
  final Random random = Random.secure();
  final Uint8List bytes = Uint8List(length);
  for (int i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

String _toHex(List<int> bytes) {
  final StringBuffer out = StringBuffer();
  for (final int byte in bytes) {
    out.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return out.toString();
}

Uint8List _fromHex(String hex) {
  if (hex.length.isOdd) {
    throw const FormatException('hex');
  }
  final Uint8List out = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

void _putUint64(Uint8List bytes, int offset, int value) {
  ByteData.sublistView(
    bytes,
    offset,
    offset + 8,
  ).setUint64(0, value, Endian.big);
}

int _getUint64(Uint8List bytes, int offset) {
  return ByteData.sublistView(
    bytes,
    offset,
    offset + 8,
  ).getUint64(0, Endian.big);
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  var diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

bool _looksLikeSqlite(File file) {
  if (!file.existsSync() || file.lengthSync() < 16) {
    return false;
  }
  final RandomAccessFile handle = file.openSync();
  try {
    final Uint8List head = Uint8List(16);
    handle.readIntoSync(head);
    return _bytesEqual(head, 'SQLite format 3\x00'.codeUnits);
  } finally {
    handle.closeSync();
  }
}

bool _looksLikeEncrypted(File file) {
  if (!file.existsSync() || file.lengthSync() < _magic.length) {
    return false;
  }
  final RandomAccessFile handle = file.openSync();
  try {
    final Uint8List head = Uint8List(_magic.length);
    handle.readIntoSync(head);
    return _bytesEqual(head, _magic);
  } finally {
    handle.closeSync();
  }
}

void _checkpoint(File file) {
  final sqlite3_raw.Database database = sqlite3_raw.sqlite3.open(file.path);
  try {
    database.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  } finally {
    database.dispose();
  }
}

Map<String, int> _rowCounts(File file) {
  final sqlite3_raw.Database database = sqlite3_raw.sqlite3.open(file.path);
  try {
    final sqlite3_raw.ResultSet tables = database.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    final Map<String, int> counts = <String, int>{};
    for (final sqlite3_raw.Row table in tables) {
      final String name = table['name']! as String;
      final sqlite3_raw.Row count = database
          .select('SELECT COUNT(*) AS n FROM "$name"')
          .first;
      counts[name] = count['n']! as int;
    }
    return counts;
  } finally {
    database.dispose();
  }
}

bool _sameCounts(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final MapEntry<String, int> entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

void _deleteFile(File file) {
  if (file.existsSync()) {
    file.deleteSync();
  }
}

void _deleteSidecars(File sqliteFile) {
  _deleteFile(File('${sqliteFile.path}-wal'));
  _deleteFile(File('${sqliteFile.path}-shm'));
  _deleteFile(File('${sqliteFile.path}-journal'));
}

final class _DigestSink implements Sink<Digest> {
  late final Digest digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}
