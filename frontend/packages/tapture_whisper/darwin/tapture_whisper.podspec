#
# The CocoaPods build of the tapture_whisper FFI plugin for iOS and macOS
# (dev-plan task 105, app-write-up section 30.4.1). Package.swift beside it is
# the SwiftPM build of the same sources with the same settings.
#
# The sources are the generated one-line forwarders in
# tapture_whisper/Sources/tapture_whisper (tool/whisper_vendor.dart), which
# include the vendored whisper.cpp and the shim in place, so the pod needs no
# include path outside itself and no network. The definitions and flags are
# those src/CMakeLists.txt uses for Apple, plus Accelerate for vDSP only;
# test/tool/whisper_vendor_test.dart holds both manifests to that.
#
# There are no architecture flags: the compiler defaults are the baseline
# (armv8-a on iOS, apple-m1 on macOS arm64, SSSE3-class on macOS x86_64). The
# framework links at launch, so AVX2 would crash older Intel Macs before the
# Dart preflight could run. No Metal, CoreML, BLAS or OpenMP.
#
Pod::Spec.new do |s|
  s.name             = 'tapture_whisper'
  s.version          = '1.9.4'
  s.summary          = 'On-device speech-to-text: whisper.cpp 1.9.4 and ggml (CPU) behind one C ABI.'
  s.description      = <<-DESC
The tapture_whisper FFI plugin: the vendored whisper.cpp 1.9.4 / ggml 0.23.0 CPU
engine and the tapture_whisper C shim, compiled as one dynamic framework that
Dart opens through dart:ffi.
                       DESC
  s.homepage         = 'https://github.com/ggml-org/whisper.cpp'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Tapture'
  s.source           = { :path => '.' }

  # The headers are project headers: CocoaPods never copies or symlinks them
  # into Headers/, where their relative includes would no longer resolve. Dart
  # looks the tw_* symbols up, so nothing imports a module from this pod.
  s.source_files         = 'tapture_whisper/Sources/tapture_whisper/**/*.{c,cpp,h}'
  s.project_header_files = 'tapture_whisper/Sources/tapture_whisper/**/*.h'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'

  s.frameworks       = 'Accelerate'
  s.library          = 'c++'
  s.static_framework = false

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'GCC_C_LANGUAGE_STANDARD' => 'c11',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'GCC_OPTIMIZATION_LEVEL' => '3',
    'GCC_SYMBOLS_PRIVATE_EXTERN' => 'YES',
    'GCC_INLINES_ARE_PRIVATE_EXTERN' => 'YES',
    'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'YES',
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}/tapture_whisper/Sources/tapture_whisper/forward"',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GGML_USE_CPU GGML_USE_CPU_REPACK GGML_SCHED_MAX_COPIES=4 NDEBUG WHISPER_VERSION=\"1.9.4\" _XOPEN_SOURCE=600 _DARWIN_C_SOURCE TW_BUILD TW_ENGINE=1 GGML_USE_ACCELERATE ACCELERATE_NEW_LAPACK ACCELERATE_LAPACK_ILP64',
    'OTHER_CFLAGS' => '$(inherited) -O3 -ffunction-sections -fdata-sections -w -fvisibility=hidden',
    'OTHER_CPLUSPLUSFLAGS' => '$(inherited) -O3 -ffunction-sections -fdata-sections -w -fvisibility=hidden -fvisibility-inlines-hidden',
  }
end
