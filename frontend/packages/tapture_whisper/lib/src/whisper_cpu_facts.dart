/// What the processor offers and what the library needs from it
/// (`tw_cpu_info`). Feature sets are bit masks of the constants below.
final class WhisperCpuFacts {
  /// Describes the processor.
  const WhisperCpuFacts({
    required this.logicalCores,
    required this.performanceCores,
    required this.arch,
    required this.runtimeFeatures,
    required this.requiredFeatures,
    required this.supported,
    required this.engineBuilt,
  });

  /// `arch` of an unrecognised processor.
  static const int archUnknown = 0;

  /// `arch` of a 64-bit x86 processor.
  static const int archX8664 = 1;

  /// `arch` of a 64-bit Arm processor.
  static const int archArm64 = 2;

  /// `arch` of a 32-bit Arm processor.
  static const int archArm32 = 3;

  /// `arch` of WebAssembly.
  static const int archWasm32 = 4;

  /// `arch` of a 32-bit x86 processor.
  static const int archX86 = 5;

  /// x86 SSE3.
  static const int sse3 = 1 << 0;

  /// x86 SSSE3.
  static const int ssse3 = 1 << 1;

  /// x86 SSE4.2.
  static const int sse42 = 1 << 2;

  /// x86 AVX.
  static const int avx = 1 << 3;

  /// x86 AVX2.
  static const int avx2 = 1 << 4;

  /// x86 fused multiply-add.
  static const int fma = 1 << 5;

  /// x86 half-precision conversion.
  static const int f16c = 1 << 6;

  /// x86 BMI2.
  static const int bmi2 = 1 << 7;

  /// x86 AVX-512 foundation.
  static const int avx512f = 1 << 8;

  /// x86 AVX-VNNI.
  static const int avxVnni = 1 << 9;

  /// Arm NEON.
  static const int neon = 1 << 16;

  /// Arm fused multiply-add.
  static const int armFma = 1 << 17;

  /// Arm half-precision vector arithmetic.
  static const int fp16VectorArithmetic = 1 << 18;

  /// Arm dot-product instructions.
  static const int dotProd = 1 << 19;

  /// Arm 8-bit integer matrix multiply.
  static const int i8mm = 1 << 20;

  /// Arm SVE.
  static const int sve = 1 << 21;

  /// Arm SME.
  static const int sme = 1 << 22;

  /// WebAssembly 128-bit SIMD.
  static const int wasmSimd = 1 << 32;

  /// Hardware threads.
  final int logicalCores;

  /// Cores worth computing on: performance cores on a hybrid processor.
  final int performanceCores;

  /// The processor family, one of the `arch*` constants.
  final int arch;

  /// Features detected on this processor now.
  final int runtimeFeatures;

  /// Features the engine was compiled to use.
  final int requiredFeatures;

  /// Whether the engine is built and every required feature is present.
  final bool supported;

  /// Whether the library carries the engine; false in a stub library.
  final bool engineBuilt;

  /// Whether this processor offers every feature in [mask].
  bool has(int mask) => runtimeFeatures & mask == mask;
}
