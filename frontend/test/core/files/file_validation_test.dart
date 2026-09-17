import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_validation.dart';

void main() {
  final FileValidation validation = FileValidation();
  const Set<ImportKind> all = <ImportKind>{
    ImportKind.image,
    ImportKind.document,
    ImportKind.spreadsheet,
    ImportKind.audio,
    ImportKind.bundle,
  };

  test('a valid file of each kind reports its kind', () async {
    expect(
      _ok(await validation.validate(_file('ok.png', _png()), allowed: all)),
      ImportKind.image,
    );
    expect(
      _ok(
        await validation.validate(
          _file('ok.pdf', utf8.encode('%PDF-1.4\n%%EOF\n')),
          allowed: all,
        ),
      ),
      ImportKind.document,
    );
    expect(
      _ok(
        await validation.validate(
          _file('ok.csv', utf8.encode('a,b\n1,2\n')),
          allowed: all,
        ),
      ),
      ImportKind.spreadsheet,
    );
    expect(
      _ok(
        await validation.validate(
          _file(
            'ok.xlsx',
            _zip(<_ZipEntry>[_ZipEntry('[Content_Types].xml', _xml)]),
          ),
          allowed: all,
        ),
      ),
      ImportKind.spreadsheet,
    );
    expect(
      _ok(await validation.validate(_file('ok.wav', _wav()), allowed: all)),
      ImportKind.audio,
    );
    expect(
      _ok(
        await validation.validate(
          _file('ok.zip', _zip(<_ZipEntry>[_ZipEntry('manifest.json', _xml)])),
          allowed: all,
        ),
      ),
      ImportKind.bundle,
    );
  });

  test('an xlsx that is really an executable is refused', () async {
    final File file = _file('trap.xlsx', <int>[0x4D, 0x5A, 0x90, 0x00]);
    final List<String> before = _names(file.parent);
    final Failure failure = _fail(
      await validation.validate(file, allowed: all),
    );
    expect(failure.message, contains('trap.xlsx'));
    expect(failure.message.toLowerCase(), contains('type'));
    expect(_names(file.parent), before);
  });

  test('an oversized image is refused and leaves no copy', () async {
    final File file = _oversizedPng();
    final List<String> before = _names(file.parent);
    final Failure failure = _fail(
      await validation.validate(file, allowed: all),
    );
    expect(failure.message.toLowerCase(), contains('larger'));
    expect(failure.message.toLowerCase(), contains('image'));
    expect(_names(file.parent), before);
  });

  test('an empty file is refused', () async {
    final Failure failure = _fail(
      await validation.validate(
        _file('blank.png', const <int>[]),
        allowed: all,
      ),
    );
    expect(failure.message.toLowerCase(), contains('empty'));
  });

  test('a zip with a traversal entry is refused', () async {
    final File file = _file(
      'escape.zip',
      _zip(<_ZipEntry>[_ZipEntry('../outside.txt', utf8.encode('no'))]),
    );
    final Failure failure = _fail(
      await validation.validate(file, allowed: all),
    );
    expect(failure.message.toLowerCase(), contains('leaves the folder'));
  });

  test('a zip with a symlink entry is refused', () async {
    final File file = _file(
      'link.zip',
      _zip(<_ZipEntry>[
        _ZipEntry('alias.txt', utf8.encode('x'), unixMode: _iflnk),
      ]),
    );
    final Failure failure = _fail(await validation.validateArchive(file));
    expect(failure.message.toLowerCase(), contains('link'));
  });

  test('a zip bomb declaration is refused', () async {
    final File file = _file(
      'bomb.zip',
      _zip(<_ZipEntry>[
        _ZipEntry(
          'payload.bin',
          const <int>[1],
          uncompressed: AppConstants.imports.archiveUncompressedMaxBytes + 1,
        ),
      ]),
    );
    final Failure failure = _fail(await validation.validateArchive(file));
    expect(failure.message.toLowerCase(), contains('uncompressed'));
  });
}

File _file(String name, List<int> bytes) {
  final Directory dir = Directory.systemTemp.createTempSync('tapture-val-');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  final File file = File('${dir.path}/$name');
  if (bytes.isEmpty) {
    file.createSync();
  } else {
    file.writeAsBytesSync(bytes);
  }
  return file;
}

File _oversizedPng() {
  final File file = _file('big.png', const <int>[]);
  final RandomAccessFile raf = file.openSync(mode: FileMode.write);
  try {
    raf.writeFromSync(_png());
    raf.truncateSync(AppConstants.imports.imageMaxBytes + 1);
  } finally {
    raf.closeSync();
  }
  return file;
}

List<String> _names(Directory dir) {
  return dir
      .listSync()
      .map((FileSystemEntity e) => e.uri.pathSegments.last)
      .toList()
    ..sort();
}

Uint8List _zip(List<_ZipEntry> entries) {
  final BytesBuilder locals = BytesBuilder();
  final BytesBuilder central = BytesBuilder();
  var offset = 0;
  for (final _ZipEntry entry in entries) {
    final List<int> name = utf8.encode(entry.name);
    final int stored = entry.data.length;
    final int uncompressed = entry.uncompressed ?? stored;
    locals.add(_u16le(_localSig));
    locals.add(_u16bytes(20));
    locals.add(_u16bytes(0));
    locals.add(_u16bytes(0));
    locals.add(_u16bytes(0));
    locals.add(_u16bytes(0));
    locals.add(_u32bytes(0));
    locals.add(_u32bytes(stored));
    locals.add(_u32bytes(uncompressed));
    locals.add(_u16bytes(name.length));
    locals.add(_u16bytes(0));
    locals.add(name);
    locals.add(entry.data);
    final int madeBy = entry.unixMode == null ? 20 : 0x0314;
    final int external = entry.unixMode == null ? 0 : (entry.unixMode! << 16);
    central.add(_u16le(_cdSig));
    central.add(_u16bytes(madeBy));
    central.add(_u16bytes(20));
    central.add(_u16bytes(0));
    central.add(_u16bytes(0));
    central.add(_u16bytes(0));
    central.add(_u16bytes(0));
    central.add(_u32bytes(0));
    central.add(_u32bytes(stored));
    central.add(_u32bytes(uncompressed));
    central.add(_u16bytes(name.length));
    central.add(_u16bytes(0));
    central.add(_u16bytes(0));
    central.add(_u16bytes(0));
    central.add(_u16bytes(0));
    central.add(_u32bytes(external));
    central.add(_u32bytes(offset));
    central.add(name);
    offset += 30 + name.length + stored;
  }
  final List<int> directory = central.takeBytes();
  locals.add(directory);
  locals.add(_u16le(_eocdSig));
  locals.add(_u16bytes(0));
  locals.add(_u16bytes(0));
  locals.add(_u16bytes(entries.length));
  locals.add(_u16bytes(entries.length));
  locals.add(_u32bytes(directory.length));
  locals.add(_u32bytes(offset));
  locals.add(_u16bytes(0));
  return Uint8List.fromList(locals.takeBytes());
}

List<int> _u16le(List<int> sig) => sig;

List<int> _u16bytes(int value) {
  return <int>[value & 0xFF, (value >> 8) & 0xFF];
}

List<int> _u32bytes(int value) {
  return <int>[
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

List<int> _png() {
  return const <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
  ];
}

List<int> _wav() {
  final List<int> bytes = List<int>.filled(44, 0);
  bytes[0] = 0x52;
  bytes[1] = 0x49;
  bytes[2] = 0x46;
  bytes[3] = 0x46;
  bytes[4] = 36;
  bytes[8] = 0x57;
  bytes[9] = 0x41;
  bytes[10] = 0x56;
  bytes[11] = 0x45;
  return bytes;
}

final class _ZipEntry {
  _ZipEntry(this.name, this.data, {this.uncompressed, this.unixMode});

  final String name;
  final List<int> data;
  final int? uncompressed;
  final int? unixMode;
}

const List<int> _xml = <int>[0x3C, 0x3F, 0x78, 0x6D];
const List<int> _localSig = <int>[0x50, 0x4B, 0x03, 0x04];
const List<int> _cdSig = <int>[0x50, 0x4B, 0x01, 0x02];
const List<int> _eocdSig = <int>[0x50, 0x4B, 0x05, 0x06];
const int _iflnk = 0xA000;

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}

Failure _fail<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => failure,
    (_) => fail('expected a refusal'),
  );
}
