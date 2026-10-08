# Fixture source list for whisper_vendor_test (dev-plan task 102).
set(TW_GGML_BASE_SOURCES
  ggml/src/ggml.c
)

set(TW_GGML_CPU_SOURCES_X86_64
  ggml/src/ggml-cpu/arch/x86/quants.c
)

set(TW_GGML_CPU_SOURCES_ARM64
  ggml/src/ggml-cpu/arch/arm/quants.c
)

set(TW_WHISPER_SOURCES
  src/whisper.cpp
)
