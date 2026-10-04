import 'dart:io';
import 'dart:typed_data';

/// Checks built ELF shared libraries of the speech engine (dev-plan task 103,
/// app-write-up §30.4.1), printing one `path:0: message` line per violation.
///
/// `dart run tool/check_native_library.dart <lib.so>...` lists every
/// loadable segment aligned below 16 KiB, every dynamic export outside `tw_*`
/// and every needed library outside the Android system set, and exits 1 on
/// any of them.
Future<int> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/check_native_library.dart <lib.so>...',
    );
    exitCode = 64;
    return exitCode;
  }
  final List<({String file, int line, String message})> violations =
      findNativeLibraryViolations(args);
  for (final ({String file, int line, String message}) violation
      in violations) {
    stderr.writeln('${violation.file}:${violation.line}: ${violation.message}');
  }
  stdout.writeln(
    violations.isEmpty
        ? 'native library: ${args.length} file(s), 16 KiB pages, tw_* exports '
              'and system libraries only'
        : 'native library: ${violations.length} violation(s)',
  );
  exitCode = violations.isEmpty ? 0 : 1;
  return exitCode;
}

/// The smallest `PT_LOAD` alignment Android 15+ devices with 16 KiB pages
/// can map.
const int requiredSegmentAlignment = 16384;

/// The libraries the shared library may need: Android's system libraries,
/// never `libomp.so` or `libc++_shared.so`, which would have to ship too.
const Set<String> allowedNeededLibraries = <String>{
  'libc.so',
  'libm.so',
  'libdl.so',
  'liblog.so',
};

/// The only symbols the library may export: the C ABI.
final RegExp exportedSymbolPattern = RegExp('^tw_');

/// Reports, for every library in [paths], each loadable segment aligned below
/// [requiredSegmentAlignment], each dynamic export not matching
/// [exportedSymbolPattern] and each `DT_NEEDED` entry outside
/// [allowedNeededLibraries]. A file that cannot be read or is not an ELF
/// shared object is reported too, so one run lists everything.
List<({String file, int line, String message})> findNativeLibraryViolations(
  List<String> paths,
) {
  final List<({String file, int line, String message})> violations =
      <({String file, int line, String message})>[];
  for (final String path in paths) {
    final File file = File(path);
    if (!file.existsSync()) {
      violations.add((file: path, line: 0, message: 'no such file'));
      continue;
    }
    final _ElfImage? image = _ElfImage.parse(file.readAsBytesSync());
    if (image == null) {
      violations.add((
        file: path,
        line: 0,
        message: 'not a little-endian ELF shared object',
      ));
      continue;
    }
    for (final int alignment in image.loadAlignments) {
      if (alignment < requiredSegmentAlignment) {
        violations.add((
          file: path,
          line: 0,
          message:
              'PT_LOAD p_align $alignment < $requiredSegmentAlignment: '
              'link with -Wl,-z,max-page-size=16384',
        ));
      }
    }
    for (final String symbol in image.exports) {
      if (!exportedSymbolPattern.hasMatch(symbol)) {
        violations.add((
          file: path,
          line: 0,
          message: "exports '$symbol': only tw_* may be visible",
        ));
      }
    }
    for (final String library in image.needed) {
      if (!allowedNeededLibraries.contains(library)) {
        violations.add((
          file: path,
          line: 0,
          message:
              "DT_NEEDED '$library' is not a system library: link it "
              'statically',
        ));
      }
    }
    if (image.exportsUnknown) {
      violations.add((
        file: path,
        line: 0,
        message: 'no section headers, so the exports cannot be listed',
      ));
    }
  }
  return violations;
}

/// What the checker reads from one ELF file.
final class _ElfImage {
  _ElfImage({
    required this.loadAlignments,
    required this.exports,
    required this.needed,
    required this.exportsUnknown,
  });

  final List<int> loadAlignments;
  final List<String> exports;
  final List<String> needed;
  final bool exportsUnknown;

  static const int _ptLoad = 1;
  static const int _ptDynamic = 2;
  static const int _dtNull = 0;
  static const int _dtNeeded = 1;
  static const int _dtStrtab = 5;
  static const int _shtDynsym = 11;
  static const int _shnUndef = 0;
  static const int _stbGlobal = 1;
  static const int _stbWeak = 2;
  static const int _stbGnuUnique = 10;
  static const int _stvDefault = 0;
  static const int _stvProtected = 3;
  static const int _etDyn = 3;

  /// Parses [bytes], or returns null when they are not a little-endian ELF
  /// shared object or are truncated.
  static _ElfImage? parse(Uint8List bytes) {
    try {
      return _parse(bytes);
    } on RangeError {
      return null;
    }
  }

  static _ElfImage? _parse(Uint8List bytes) {
    if (bytes.length < 52 ||
        bytes[0] != 0x7f ||
        bytes[1] != 0x45 ||
        bytes[2] != 0x4c ||
        bytes[3] != 0x46 ||
        bytes[5] != 1) {
      return null;
    }
    final bool wide = bytes[4] == 2;
    if (!wide && bytes[4] != 1) {
      return null;
    }
    final ByteData data = ByteData.sublistView(bytes);
    int word(int offset) => wide
        ? data.getUint64(offset, Endian.little)
        : data.getUint32(offset, Endian.little);
    int half(int offset) => data.getUint16(offset, Endian.little);
    int u32(int offset) => data.getUint32(offset, Endian.little);
    String text(int offset) {
      int end = offset;
      while (bytes[end] != 0) {
        end++;
      }
      return String.fromCharCodes(bytes.sublist(offset, end));
    }

    if (half(16) != _etDyn) {
      return null;
    }
    final int programOffset = word(wide ? 32 : 28);
    final int sectionOffset = word(wide ? 40 : 32);
    final int programSize = half(wide ? 54 : 42);
    final int programCount = half(wide ? 56 : 44);
    final int sectionSize = half(wide ? 58 : 46);
    final int sectionCount = half(wide ? 60 : 48);

    final List<int> alignments = <int>[];
    final List<({int vaddr, int offset, int size})> loads =
        <({int vaddr, int offset, int size})>[];
    int dynamicOffset = -1;
    int dynamicSize = 0;
    for (int i = 0; i < programCount; i++) {
      final int at = programOffset + i * programSize;
      final int type = u32(at);
      final int offset = word(wide ? at + 8 : at + 4);
      final int vaddr = word(wide ? at + 16 : at + 8);
      final int fileSize = word(wide ? at + 32 : at + 16);
      final int align = word(wide ? at + 48 : at + 28);
      if (type == _ptLoad) {
        alignments.add(align);
        loads.add((vaddr: vaddr, offset: offset, size: fileSize));
      } else if (type == _ptDynamic) {
        dynamicOffset = offset;
        dynamicSize = fileSize;
      }
    }

    int fileOffsetOf(int vaddr) {
      for (final ({int vaddr, int offset, int size}) load in loads) {
        if (vaddr >= load.vaddr && vaddr < load.vaddr + load.size) {
          return load.offset + vaddr - load.vaddr;
        }
      }
      throw RangeError('address $vaddr is not loaded');
    }

    final List<String> needed = <String>[];
    if (dynamicOffset >= 0) {
      final int entrySize = wide ? 16 : 8;
      final List<int> neededOffsets = <int>[];
      int strtab = -1;
      for (
        int at = dynamicOffset;
        at + entrySize <= dynamicOffset + dynamicSize;
        at += entrySize
      ) {
        final int tag = word(at);
        final int value = word(at + entrySize ~/ 2);
        if (tag == _dtNull) {
          break;
        }
        if (tag == _dtNeeded) {
          neededOffsets.add(value);
        } else if (tag == _dtStrtab) {
          strtab = fileOffsetOf(value);
        }
      }
      if (strtab >= 0) {
        needed.addAll(<String>[
          for (final int offset in neededOffsets) text(strtab + offset),
        ]);
      }
    }

    final List<String> exports = <String>[];
    bool dynsymFound = false;
    for (int i = 0; i < sectionCount; i++) {
      final int at = sectionOffset + i * sectionSize;
      if (u32(at + 4) != _shtDynsym) {
        continue;
      }
      dynsymFound = true;
      final int symbolsOffset = word(wide ? at + 24 : at + 16);
      final int symbolsSize = word(wide ? at + 32 : at + 20);
      final int link = u32(wide ? at + 40 : at + 24);
      final int symbolSize = word(wide ? at + 56 : at + 36);
      final int linkAt = sectionOffset + link * sectionSize;
      final int strings = word(wide ? linkAt + 24 : linkAt + 16);
      for (
        int s = symbolsOffset + symbolSize;
        s + symbolSize <= symbolsOffset + symbolsSize;
        s += symbolSize
      ) {
        final int name = u32(s);
        final int info = bytes[wide ? s + 4 : s + 12];
        final int other = bytes[wide ? s + 5 : s + 13];
        final int sectionIndex = half(wide ? s + 6 : s + 14);
        final int binding = info >> 4;
        final int visibility = other & 3;
        final bool global =
            binding == _stbGlobal ||
            binding == _stbWeak ||
            binding == _stbGnuUnique;
        final bool visible =
            visibility == _stvDefault || visibility == _stvProtected;
        if (sectionIndex != _shnUndef && global && visible && name != 0) {
          exports.add(text(strings + name));
        }
      }
    }
    return _ElfImage(
      loadAlignments: alignments,
      exports: exports,
      needed: needed,
      exportsUnknown: !dynsymFound && sectionCount == 0,
    );
  }
}
