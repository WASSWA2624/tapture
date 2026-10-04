import 'dart:ffi';
import 'dart:io';

/// The x86-64 processor check that runs before the library is opened: the
/// desktop builds are compiled for AVX2, FMA, F16C and BMI2, and opening one
/// on an older processor could fault on its first instruction.
///
/// Every other ABI passes here; the library's own `tw_cpu_info_get` decides
/// after it is opened. Both probes are injectable so tests run anywhere.
final class CpuPreflight {
  /// A preflight for [abi] over the given probes.
  const CpuPreflight({
    required this.abi,
    required this.readCpuinfo,
    required this.isProcessorFeaturePresent,
  });

  /// The preflight of this process, over the real probes.
  factory CpuPreflight.current() => CpuPreflight(
    abi: Abi.current(),
    readCpuinfo: _readProcCpuinfo,
    isProcessorFeaturePresent: _windowsFeaturePresent,
  );

  /// `PF_AVX2_INSTRUCTIONS_AVAILABLE` of Windows'
  /// `IsProcessorFeaturePresent`. FMA, F16C and BMI2 come with every AVX2
  /// processor.
  static const int windowsAvx2Feature = 40;

  /// The `/proc/cpuinfo` flags the Linux x86-64 build needs.
  static const List<String> desktopBaselineFlags = <String>[
    'avx2',
    'fma',
    'f16c',
    'bmi2',
  ];

  /// The ABI this process runs.
  final Abi abi;

  /// Reads `/proc/cpuinfo`; null when it cannot be read.
  final String? Function() readCpuinfo;

  /// Windows' `IsProcessorFeaturePresent`.
  final bool Function(int feature) isProcessorFeaturePresent;

  /// Why the processor is refused, or null when the library may be opened.
  String? refusal() {
    if (abi == Abi.windowsX64) {
      return isProcessorFeaturePresent(windowsAvx2Feature)
          ? null
          : 'the processor lacks AVX2';
    }
    if (abi == Abi.linuxX64) {
      return cpuinfoSupportsDesktopBaseline(readCpuinfo() ?? '')
          ? null
          : 'the processor lacks one of ${desktopBaselineFlags.join(' ')}';
    }
    return null;
  }

  /// Whether every `flags` line of [cpuinfo] lists every flag of
  /// [desktopBaselineFlags]; false when there is no `flags` line.
  static bool cpuinfoSupportsDesktopBaseline(String cpuinfo) {
    bool sawFlags = false;
    for (final String line in cpuinfo.split('\n')) {
      final int colon = line.indexOf(':');
      if (colon < 0 || line.substring(0, colon).trim() != 'flags') {
        continue;
      }
      sawFlags = true;
      final Set<String> flags = line
          .substring(colon + 1)
          .split(RegExp(r'\s+'))
          .where((String flag) => flag.isNotEmpty)
          .toSet();
      if (!flags.containsAll(desktopBaselineFlags)) {
        return false;
      }
    }
    return sawFlags;
  }
}

String? _readProcCpuinfo() {
  try {
    return File('/proc/cpuinfo').readAsStringSync();
  } on FileSystemException {
    return null;
  }
}

bool _windowsFeaturePresent(int feature) {
  try {
    final int Function(int) present = DynamicLibrary.open('kernel32.dll')
        .lookupFunction<Int32 Function(Uint32), int Function(int)>(
          'IsProcessorFeaturePresent',
          isLeaf: true,
        );
    return present(feature) != 0;
  } on ArgumentError {
    return false;
  }
}
