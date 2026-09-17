import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// The one gate every file from outside the app passes before a parser sees
/// it: extension, magic bytes, size and archive structure (FE-SEC-06).
abstract interface class FileValidation {
  /// Creates the validator. It never copies [file] and never opens a parser.
  factory FileValidation() = _FileValidation;

  /// Extension, size and magic bytes. [allowed] is the kinds this call will
  /// accept. Archives are walked for traversal, links and zip-bomb size.
  Future<Result<ImportKind>> validate(
    File file, {
    required Set<ImportKind> allowed,
  });

  /// Walks a ZIP central directory. Rejects absolute paths, `..` segments,
  /// symlinks and a declared uncompressed total above the ceiling.
  Future<Result<void>> validateArchive(File archive);
}

/// Kinds an imported file may claim, from its extension then its bytes.
enum ImportKind {
  /// A photograph (JPEG, PNG or WebP).
  image,

  /// A PDF document.
  document,

  /// An XLSX workbook or a CSV table.
  spreadsheet,

  /// Recorded audio (WAV, M4A or MP3).
  audio,

  /// A project bundle ZIP.
  bundle,
}

final class _FileValidation implements FileValidation {
  const _FileValidation();

  @override
  Future<Result<ImportKind>> validate(
    File file, {
    required Set<ImportKind> allowed,
  }) {
    return Result.captureAsync(() async {
      if (!file.existsSync()) {
        throw _missing(file);
      }
      final int length = file.lengthSync();
      if (length <= 0) {
        throw _empty(file);
      }
      final ImportKind kind = _kindFromName(file);
      if (!allowed.contains(kind)) {
        throw _unsupported(file);
      }
      if (length > _ceiling(kind)) {
        throw _oversized(file, kind);
      }
      final Uint8List header = _sniff(file, length);
      if (!_magicMatches(kind, _extension(file), header)) {
        throw _mismatch(file);
      }
      if (_isArchiveKind(kind, _extension(file))) {
        final Result<void> archive = await validateArchive(file);
        switch (archive) {
          case FailureResult<void>(:final failure):
            throw failure;
          case Success<void>():
            break;
        }
      }
      return kind;
    });
  }

  @override
  Future<Result<void>> validateArchive(File archive) {
    return Result.captureAsync(() async {
      if (!archive.existsSync()) {
        throw _missing(archive);
      }
      final int length = archive.lengthSync();
      if (length < _eocdMin) {
        throw _notArchive(archive);
      }
      if (length > AppConstants.imports.bundleMaxBytes) {
        throw _oversized(archive, ImportKind.bundle);
      }
      final Uint8List header = _sniff(archive, length);
      if (!_isZip(header)) {
        throw _notArchive(archive);
      }
      _walkZip(archive, length);
    });
  }
}

ImportKind _kindFromName(File file) {
  final String ext = _extension(file);
  final ImportKind? kind = _kinds[ext];
  if (kind == null) {
    throw _unsupported(file);
  }
  return kind;
}

int _ceiling(ImportKind kind) {
  switch (kind) {
    case ImportKind.image:
      return AppConstants.imports.imageMaxBytes;
    case ImportKind.document:
      return AppConstants.imports.documentMaxBytes;
    case ImportKind.spreadsheet:
      return AppConstants.imports.spreadsheetMaxBytes;
    case ImportKind.audio:
      return AppConstants.imports.audioMaxBytes;
    case ImportKind.bundle:
      return AppConstants.imports.bundleMaxBytes;
  }
}

bool _isArchiveKind(ImportKind kind, String ext) {
  return kind == ImportKind.bundle ||
      (kind == ImportKind.spreadsheet && ext == 'xlsx');
}

Uint8List _sniff(File file, int length) {
  final int n = min(AppConstants.imports.sniffHeaderBytes, length);
  final RandomAccessFile raf = file.openSync();
  try {
    final Uint8List buffer = Uint8List(n);
    var filled = 0;
    while (filled < n) {
      final int got = raf.readIntoSync(buffer, filled);
      if (got == 0) {
        break;
      }
      filled += got;
    }
    if (filled == n) {
      return buffer;
    }
    return Uint8List.sublistView(buffer, 0, filled);
  } finally {
    raf.closeSync();
  }
}

bool _magicMatches(ImportKind kind, String ext, Uint8List header) {
  switch (kind) {
    case ImportKind.image:
      if (ext == 'png') {
        return _prefix(header, _png);
      }
      if (ext == 'jpg' || ext == 'jpeg') {
        return _prefix(header, _jpeg);
      }
      if (ext == 'webp') {
        return _isWebp(header);
      }
      return false;
    case ImportKind.document:
      return _prefix(header, _pdf);
    case ImportKind.spreadsheet:
      if (ext == 'xlsx') {
        return _isZip(header);
      }
      return !_isZip(header) &&
          !_prefix(header, _mz) &&
          !_prefix(header, _pdf) &&
          !_prefix(header, _jpeg) &&
          !_prefix(header, _png);
    case ImportKind.audio:
      if (ext == 'wav') {
        return _isWav(header);
      }
      if (ext == 'm4a') {
        return _isFtyp(header);
      }
      if (ext == 'mp3') {
        return _isMp3(header);
      }
      return false;
    case ImportKind.bundle:
      return _isZip(header);
  }
}

void _walkZip(File archive, int length) {
  final RandomAccessFile raf = archive.openSync();
  try {
    final ({int offset, int size, int entries}) eocd = _eocd(raf, length);
    if (eocd.offset < 0 || eocd.size < 0 || eocd.offset + eocd.size > length) {
      throw _notArchive(archive);
    }
    raf.setPositionSync(eocd.offset);
    var totalUncompressed = 0;
    var seen = 0;
    while (seen < eocd.entries) {
      final Uint8List head = _readExact(raf, _cdHead);
      if (!_prefix(head, _cdSig)) {
        throw _notArchive(archive);
      }
      final int madeBy = _u16(head, 4);
      final int nameLen = _u16(head, 28);
      final int extraLen = _u16(head, 30);
      final int commentLen = _u16(head, 32);
      final int external = _u32(head, 38);
      final int uncompressed = _u32(head, 24);
      final Uint8List nameBytes = _readExact(raf, nameLen);
      _skip(raf, extraLen + commentLen);
      final String name = _zipName(nameBytes);
      if (_escapes(name)) {
        throw _traversal(archive);
      }
      if (_isSymlink(madeBy, external)) {
        throw _symlink(archive);
      }
      if (uncompressed == 0xFFFFFFFF) {
        throw _bomb(archive);
      }
      totalUncompressed += uncompressed;
      if (totalUncompressed >
          AppConstants.imports.archiveUncompressedMaxBytes) {
        throw _bomb(archive);
      }
      seen += 1;
    }
  } finally {
    raf.closeSync();
  }
}

({int offset, int size, int entries}) _eocd(RandomAccessFile raf, int length) {
  final int window = min(length, _eocdMin + _maxComment);
  raf.setPositionSync(length - window);
  final Uint8List tail = _readExact(raf, window);
  for (var i = tail.length - _eocdMin; i >= 0; i--) {
    if (!_prefixAt(tail, i, _eocdSig)) {
      continue;
    }
    final int comment = _u16(tail, i + 20);
    if (i + _eocdMin + comment != tail.length) {
      continue;
    }
    return (
      entries: _u16(tail, i + 10),
      size: _u32(tail, i + 12),
      offset: _u32(tail, i + 16),
    );
  }
  throw _notArchive(File(raf.path));
}

Uint8List _readExact(RandomAccessFile raf, int n) {
  if (n == 0) {
    return Uint8List(0);
  }
  final Uint8List buffer = Uint8List(n);
  var filled = 0;
  while (filled < n) {
    final int got = raf.readIntoSync(buffer, filled);
    if (got == 0) {
      throw _notArchive(File(raf.path));
    }
    filled += got;
  }
  return buffer;
}

void _skip(RandomAccessFile raf, int n) {
  if (n <= 0) {
    return;
  }
  raf.setPositionSync(raf.positionSync() + n);
}

String _zipName(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    throw const ValidationFailure(
      message: 'The archive contains a name that is not valid.',
      recoveryAction: 'Choose a different file and try again.',
    );
  }
}

bool _escapes(String name) {
  if (name.contains('\u0000')) {
    return true;
  }
  final String norm = name.replaceAll(r'\', '/');
  if (norm.startsWith('/') || _drive.hasMatch(norm)) {
    return true;
  }
  for (final String part in norm.split('/')) {
    if (part == '..') {
      return true;
    }
  }
  return false;
}

bool _isSymlink(int madeBy, int external) {
  if (madeBy >> 8 != _unixHost) {
    return false;
  }
  return ((external >> 16) & _ifmt) == _iflnk;
}

bool _prefix(Uint8List bytes, List<int> magic) {
  return _prefixAt(bytes, 0, magic);
}

bool _prefixAt(Uint8List bytes, int offset, List<int> magic) {
  if (offset < 0 || offset + magic.length > bytes.length) {
    return false;
  }
  for (var i = 0; i < magic.length; i++) {
    if (bytes[offset + i] != magic[i]) {
      return false;
    }
  }
  return true;
}

bool _isZip(Uint8List header) {
  return _prefix(header, _localSig) || _prefix(header, _eocdSig);
}

bool _isWebp(Uint8List header) {
  return _prefix(header, _riff) && _prefixAt(header, 8, _webp);
}

bool _isWav(Uint8List header) {
  return _prefix(header, _riff) && _prefixAt(header, 8, _wave);
}

bool _isFtyp(Uint8List header) {
  return _prefixAt(header, 4, _ftyp);
}

bool _isMp3(Uint8List header) {
  if (_prefix(header, _id3)) {
    return true;
  }
  if (header.length < 2 || header[0] != 0xFF) {
    return false;
  }
  final int b = header[1];
  return b == 0xFB || b == 0xF3 || b == 0xF2;
}

int _u16(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

int _u32(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

String _extension(File file) {
  final String name = _basename(file.path);
  final int dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) {
    return '';
  }
  return name.substring(dot + 1).toLowerCase();
}

String _basename(String path) {
  final String n = path.replaceAll(r'\', '/');
  final int slash = n.lastIndexOf('/');
  return slash == -1 ? n : n.substring(slash + 1);
}

String _quoted(File file) {
  final String name = _basename(file.path).replaceAll('"', "'");
  return '"$name"';
}

ValidationFailure _empty(File file) {
  return ValidationFailure(
    message: 'The file ${_quoted(file)} is empty.',
    recoveryAction: 'Choose a file that has contents and try again.',
  );
}

ValidationFailure _unsupported(File file) {
  return ValidationFailure(
    message: 'The file ${_quoted(file)} is not a supported type.',
    recoveryAction:
        'Choose an image, document, spreadsheet, audio file or '
        'bundle and try again.',
  );
}

ValidationFailure _mismatch(File file) {
  return ValidationFailure(
    message: 'The file ${_quoted(file)} does not match its type.',
    recoveryAction: 'Choose a file of the expected type and try again.',
  );
}

ValidationFailure _oversized(File file, ImportKind kind) {
  return ValidationFailure(
    message:
        'The file ${_quoted(file)} is larger than the allowed size for '
        'a ${_label(kind)}.',
    recoveryAction: 'Choose a smaller file and try again.',
  );
}

ValidationFailure _traversal(File file) {
  return ValidationFailure(
    message:
        'The archive ${_quoted(file)} contains a path that leaves the '
        'folder.',
    recoveryAction: 'Choose a different file and try again.',
  );
}

ValidationFailure _symlink(File file) {
  return ValidationFailure(
    message: 'The archive ${_quoted(file)} contains a link instead of a file.',
    recoveryAction: 'Choose a different file and try again.',
  );
}

ValidationFailure _bomb(File file) {
  return ValidationFailure(
    message:
        'The archive ${_quoted(file)} declares more uncompressed data '
        'than is allowed.',
    recoveryAction: 'Choose a different file and try again.',
  );
}

ValidationFailure _notArchive(File file) {
  return ValidationFailure(
    message: 'The file ${_quoted(file)} is not an archive.',
    recoveryAction: 'Choose a ZIP bundle or spreadsheet and try again.',
  );
}

StorageFailure _missing(File file) {
  return StorageFailure(
    message: 'Tapture could not find ${_quoted(file)}.',
    recoveryAction: 'Choose the file again, then try again.',
  );
}

String _label(ImportKind kind) {
  switch (kind) {
    case ImportKind.image:
      return 'image';
    case ImportKind.document:
      return 'document';
    case ImportKind.spreadsheet:
      return 'spreadsheet';
    case ImportKind.audio:
      return 'audio file';
    case ImportKind.bundle:
      return 'bundle';
  }
}

const Map<String, ImportKind> _kinds = <String, ImportKind>{
  'jpg': ImportKind.image,
  'jpeg': ImportKind.image,
  'png': ImportKind.image,
  'webp': ImportKind.image,
  'pdf': ImportKind.document,
  'xlsx': ImportKind.spreadsheet,
  'csv': ImportKind.spreadsheet,
  'wav': ImportKind.audio,
  'm4a': ImportKind.audio,
  'mp3': ImportKind.audio,
  'zip': ImportKind.bundle,
};

final RegExp _drive = RegExp(r'^[A-Za-z]:');

const List<int> _png = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const List<int> _jpeg = <int>[0xFF, 0xD8, 0xFF];
const List<int> _pdf = <int>[0x25, 0x50, 0x44, 0x46, 0x2D];
const List<int> _mz = <int>[0x4D, 0x5A];
const List<int> _riff = <int>[0x52, 0x49, 0x46, 0x46];
const List<int> _webp = <int>[0x57, 0x45, 0x42, 0x50];
const List<int> _wave = <int>[0x57, 0x41, 0x56, 0x45];
const List<int> _ftyp = <int>[0x66, 0x74, 0x79, 0x70];
const List<int> _id3 = <int>[0x49, 0x44, 0x33];
const List<int> _localSig = <int>[0x50, 0x4B, 0x03, 0x04];
const List<int> _cdSig = <int>[0x50, 0x4B, 0x01, 0x02];
const List<int> _eocdSig = <int>[0x50, 0x4B, 0x05, 0x06];

const int _eocdMin = 22;
const int _cdHead = 46;
const int _maxComment = 65535;
const int _unixHost = 3;
const int _ifmt = 0xF000;
const int _iflnk = 0xA000;
