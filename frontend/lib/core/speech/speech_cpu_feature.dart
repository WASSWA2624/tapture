/// A processor feature the speech engine runtime reports.
enum SpeechCpuFeature {
  /// x86 AVX.
  avx,

  /// x86 AVX2.
  avx2,

  /// x86 fused multiply-add.
  fma,

  /// x86 half-precision conversion.
  f16c,

  /// Arm NEON.
  neon,

  /// Arm fused multiply-add.
  armFma,

  /// Arm dot-product instructions.
  dotProd,

  /// Arm half-precision arithmetic.
  fp16,

  /// WebAssembly 128-bit SIMD.
  wasmSimd,
}
