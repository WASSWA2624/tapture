part of 'encryption.dart';

const String _plainName = 'tapture.sqlite';
const String _encName = 'tapture.sqlite.enc';
const String _partialName = 'tapture.sqlite.enc.partial';
const String _bakName = 'tapture.sqlite.bak';
const String _stateName = 'tapture.encryption';
const String _stateEnabled = 'enabled';

const int _nonceLength = 16;
const int _macLength = 32;
const int _blockLength = 32;
const List<int> _magic = <int>[84, 65, 80, 69, 78, 67, 48, 49];
const AuthenticatedFileCipher _cipher = AuthenticatedFileCipher(
  magic: 'TAPENC02',
  purpose: 'database',
);
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
  if (encrypt) {
    _cipher.sealFile(
      File(source),
      File(dest),
      keyBytes,
      onProgress: IsolateRunner.reportProgress,
    );
  } else if (_hasMagic(File(source), _magic)) {
    // Read existing installations without ever writing this legacy cipher.
    // A successful close upgrades the encrypted snapshot to AES-256.
    final List<int> encKey = Hmac(sha256, keyBytes).convert(_encLabel).bytes;
    final List<int> macKey = Hmac(sha256, keyBytes).convert(_macLabel).bytes;
    _decryptPath(source, dest, encKey, macKey);
  } else {
    _cipher.openFile(
      File(source),
      File(dest),
      keyBytes,
      onProgress: IsolateRunner.reportProgress,
    );
  }
}

void _verifyEncryptionKey(({String path, String key}) job) {
  final Uint8List key = _fromHex(job.key);
  final File source = File(job.path);
  if (_hasMagic(source, _magic)) {
    _verifyLegacyMac(source, Hmac(sha256, key).convert(_macLabel).bytes);
  } else {
    _cipher.verifyFile(source, key);
  }
}

void _verifyLegacyMac(File source, List<int> macKey) {
  final RandomAccessFile input = source.openSync();
  try {
    final int length = input.lengthSync() - _macLength;
    if (length < _magic.length + _nonceLength + 8) {
      throw const FormatException('short');
    }
    final _DigestSink digest = _DigestSink();
    final ByteConversionSink mac = Hmac(
      sha256,
      macKey,
    ).startChunkedConversion(digest);
    final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes);
    var remaining = length;
    while (remaining > 0) {
      final int count = input.readIntoSync(
        buffer,
        0,
        min(buffer.length, remaining),
      );
      if (count == 0) {
        throw const FormatException('truncated');
      }
      mac.add(Uint8List.sublistView(buffer, 0, count));
      remaining -= count;
    }
    mac.close();
    if (!_bytesEqual(input.readSync(_macLength), digest.digest.bytes)) {
      throw const FormatException('mac');
    }
  } finally {
    input.closeSync();
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
  _verifyLegacyMac(inFile, macKey);
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
  return _hasMagic(file, _magic) || _hasMagic(file, _cipher.magic.codeUnits);
}

bool _hasMagic(File file, List<int> magic) {
  if (!file.existsSync() || file.lengthSync() < magic.length) {
    return false;
  }
  final RandomAccessFile handle = file.openSync();
  try {
    final Uint8List head = Uint8List(magic.length);
    handle.readIntoSync(head);
    return _bytesEqual(head, magic);
  } finally {
    handle.closeSync();
  }
}

void _checkpoint(File file) {
  final sqlite3_raw.Database database = sqlite3_raw.sqlite3.open(file.path);
  try {
    database.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  } finally {
    database.close();
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
    database.close();
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
