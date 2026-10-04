# The canonical list of vendored whisper.cpp 1.9.4 / ggml 0.23.0 translation
# units, relative to third_party/whisper.cpp (dev-plan task 102).
#
# One list drives every build: src/CMakeLists.txt (Android, Windows, Linux,
# WebAssembly) and the generated Darwin forwarders. tool/whisper_vendor.dart
# reads the set(NAME ...) blocks below; --check fails an entry that is not
# vendored and a forwarder that no longer matches this list.
#
# It mirrors upstream ggml/src/CMakeLists.txt and ggml/src/ggml-cpu/
# CMakeLists.txt for the CPU-only, non-dynamic-loading configuration.

set(TW_GGML_BASE_SOURCES
  ggml/src/ggml.c
  ggml/src/ggml.cpp
  ggml/src/ggml-alloc.c
  ggml/src/ggml-backend.cpp
  ggml/src/ggml-backend-meta.cpp
  ggml/src/ggml-backend-dl.cpp
  ggml/src/ggml-backend-reg.cpp
  ggml/src/ggml-opt.cpp
  ggml/src/ggml-threading.cpp
  ggml/src/ggml-quants.c
  ggml/src/gguf.cpp
)

set(TW_GGML_CPU_SOURCES
  ggml/src/ggml-cpu/ggml-cpu.c
  ggml/src/ggml-cpu/ggml-cpu.cpp
  ggml/src/ggml-cpu/repack.cpp
  ggml/src/ggml-cpu/iqp.cpp
  ggml/src/ggml-cpu/hbm.cpp
  ggml/src/ggml-cpu/quants.c
  ggml/src/ggml-cpu/traits.cpp
  ggml/src/ggml-cpu/amx/amx.cpp
  ggml/src/ggml-cpu/amx/mmq.cpp
  ggml/src/ggml-cpu/binary-ops.cpp
  ggml/src/ggml-cpu/unary-ops.cpp
  ggml/src/ggml-cpu/vec.cpp
  ggml/src/ggml-cpu/ops.cpp
)

set(TW_GGML_CPU_SOURCES_X86_64
  ggml/src/ggml-cpu/arch/x86/quants.c
  ggml/src/ggml-cpu/arch/x86/repack.cpp
)

set(TW_GGML_CPU_SOURCES_ARM64
  ggml/src/ggml-cpu/arch/arm/quants.c
  ggml/src/ggml-cpu/arch/arm/repack.cpp
)

set(TW_GGML_CPU_SOURCES_WASM
  ggml/src/ggml-cpu/arch/wasm/quants.c
)

set(TW_WHISPER_SOURCES
  src/whisper.cpp
)
