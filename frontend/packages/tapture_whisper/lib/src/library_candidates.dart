import 'dart:ffi';
import 'dart:io';

import 'cpu_preflight.dart';
import 'whisper_library_load.dart';
import 'whisper_unavailable_reason.dart';

/// Where the native library may sit on one operating system, in the order it
/// is tried, and the one sequence that opens it: the processor preflight
/// first, then each candidate.
final class LibraryCandidates {
  /// Candidates over explicit [paths], then the process itself when
  /// [processFallback] is set.
  const LibraryCandidates({required this.paths, this.processFallback = false});

  /// The candidates of operating system [os] (`Platform.operatingSystem`),
  /// whose executable is [resolvedExecutable].
  factory LibraryCandidates.forHost({
    required String os,
    required String resolvedExecutable,
  }) {
    switch (os) {
      case 'android':
        return const LibraryCandidates(paths: <String>[sharedObjectName]);
      case 'windows':
        return const LibraryCandidates(paths: <String>[windowsName]);
      case 'linux':
        return LibraryCandidates(
          paths: <String>[
            '${_directoryOf(resolvedExecutable)}/lib/$sharedObjectName',
            sharedObjectName,
          ],
        );
      case 'ios':
      case 'macos':
        return const LibraryCandidates(
          paths: <String>[frameworkName],
          processFallback: true,
        );
      default:
        return const LibraryCandidates(paths: <String>[]);
    }
  }

  /// The candidates of this process.
  factory LibraryCandidates.current() => LibraryCandidates.forHost(
    os: Platform.operatingSystem,
    resolvedExecutable: Platform.resolvedExecutable,
  );

  /// The library's file name on Windows, beside the executable.
  static const String windowsName = 'tapture_whisper.dll';

  /// The library's file name on Android and Linux.
  static const String sharedObjectName = 'libtapture_whisper.so';

  /// The library inside its Apple framework.
  static const String frameworkName =
      'tapture_whisper.framework/tapture_whisper';

  /// The symbol that proves the process itself carries the library.
  static const String probeSymbol = 'tw_abi_version';

  /// The paths tried, in order.
  final List<String> paths;

  /// Whether the process itself is tried last, when it provides
  /// [probeSymbol] (a statically linked Apple build).
  final bool processFallback;

  /// Whether this operating system has a build of the library at all.
  bool get isSupported => paths.isNotEmpty || processFallback;

  /// Runs [preflight], then opens the first candidate that loads.
  ///
  /// No candidate is opened when the preflight refuses the processor.
  /// [openPath] and [openProcess] default to `DynamicLibrary.open` and
  /// `DynamicLibrary.process`.
  ({DynamicLibrary? library, WhisperLibraryUnavailable? refusal}) open({
    required CpuPreflight preflight,
    DynamicLibrary Function(String path)? openPath,
    DynamicLibrary Function()? openProcess,
  }) {
    if (!isSupported) {
      return (
        library: null,
        refusal: const WhisperLibraryUnavailable(
          WhisperUnavailableReason.unsupportedPlatform,
          'no build of the library for this operating system',
        ),
      );
    }
    final String? cpu = preflight.refusal();
    if (cpu != null) {
      return (
        library: null,
        refusal: WhisperLibraryUnavailable(
          WhisperUnavailableReason.unsupportedCpu,
          cpu,
        ),
      );
    }
    final DynamicLibrary Function(String path) byPath =
        openPath ?? DynamicLibrary.open;
    for (final String path in paths) {
      try {
        return (library: byPath(path), refusal: null);
      } on ArgumentError {
        continue;
      }
    }
    if (processFallback) {
      final DynamicLibrary process = (openProcess ?? DynamicLibrary.process)();
      if (process.providesSymbol(probeSymbol)) {
        return (library: process, refusal: null);
      }
    }
    return (
      library: null,
      refusal: WhisperLibraryUnavailable(
        WhisperUnavailableReason.libraryMissing,
        'none of ${paths.length} candidate libraries could be opened',
      ),
    );
  }

  static String _directoryOf(String path) {
    final int slash = path.lastIndexOf(RegExp(r'[\\/]'));
    return slash <= 0 ? '.' : path.substring(0, slash);
  }
}
