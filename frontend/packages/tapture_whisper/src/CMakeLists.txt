# tapture_whisper: the shim and the vendored whisper.cpp 1.9.4 / ggml 0.23.0
# CPU engine as one shared library (dev-plan task 103, app-write-up section 30.4.1).
#
# One file serves the Android NDK (CMake 3.22.1), MSVC (CMake 4.x), the
# Linux desktop and Emscripten (task 111: tool/whisper_wasm.dart configures it
# with the pinned emsdk's toolchain file and builds tapture_whisper_st or _mt).
# The vendored sources come from whisper_sources.cmake; none of
# upstream's CMake is used: no apply_standard_settings, FetchContent,
# file(DOWNLOAD), install(), git probe, BLAS, Metal or GGML_NATIVE.
#
# Options:
#   TW_OPENMP       persistent OpenMP team in ggml-cpu (default ON on Android,
#                   statically linked; OFF elsewhere)
#   TW_BUILD_SMOKE  also build the tw_smoke command-line test
#   TW_WASM_THREADS Emscripten only: the pthread variant tapture_whisper_mt
#                   (default OFF: the single-thread tapture_whisper_st)
cmake_minimum_required(VERSION 3.14...3.31)
project(tapture_whisper_library VERSION 1.9.4 LANGUAGES C CXX)

set(TW_SRC "${CMAKE_CURRENT_LIST_DIR}")
set(TW_VENDOR "${TW_SRC}/../third_party/whisper.cpp")
include("${TW_SRC}/whisper_sources.cmake")

if(ANDROID)
  set(TW_OPENMP_DEFAULT ON)
else()
  set(TW_OPENMP_DEFAULT OFF)
endif()
option(TW_OPENMP "Use OpenMP threads in ggml-cpu" ${TW_OPENMP_DEFAULT})
option(TW_BUILD_SMOKE "Build the tw_smoke command-line test" OFF)
option(TW_WASM_THREADS "Build the pthread WebAssembly variant" OFF)
if(EMSCRIPTEN)
  set(TW_BUILD_SMOKE OFF)
endif()

# The Flutter Windows runner defines UNICODE for every subdirectory; the
# vendored C needs the narrow Win32 APIs.
remove_definitions(-DUNICODE -D_UNICODE)

if(MSVC)
  # Every configuration runs at release speed: /RTC1 cannot combine with /O2,
  # and /Od would only be overridden. The library exports a C ABI and frees
  # what it allocates, so it uses the release CRT even in a Debug app.
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
  foreach(config DEBUG RELEASE PROFILE RELWITHDEBINFO MINSIZEREL)
    foreach(lang C CXX)
      set(flags "${CMAKE_${lang}_FLAGS_${config}}")
      string(REGEX REPLACE "/RTC[1csu]+" "" flags "${flags}")
      string(REGEX REPLACE "/O[bdx0-9]+" "" flags "${flags}")
      string(REGEX REPLACE "/MDd" "/MD" flags "${flags}")
      string(REGEX REPLACE "/D_DEBUG" "" flags "${flags}")
      set(CMAKE_${lang}_FLAGS_${config} "${flags}")
    endforeach()
  endforeach()
endif()

# ---- architecture -> engine. armeabi-v7a, x86 and Windows ARM64 get the stub.
set(TW_ARCH "")
if(ANDROID)
  if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(TW_ARCH arm64)
  elseif(ANDROID_ABI STREQUAL "x86_64")
    set(TW_ARCH x86_64_android)
  endif()
elseif(EMSCRIPTEN)
  set(TW_ARCH wasm)
elseif(MSVC)
  if(CMAKE_GENERATOR_PLATFORM MATCHES "^[xX]64$" OR
     (NOT CMAKE_GENERATOR_PLATFORM AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(AMD64|x86_64)$"))
    set(TW_ARCH x86_64_desktop)
  endif()
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$")
  set(TW_ARCH x86_64_desktop)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
  set(TW_ARCH arm64)
endif()

set(TW_DEFS GGML_USE_CPU GGML_USE_CPU_REPACK GGML_SCHED_MAX_COPIES=4 NDEBUG
    WHISPER_VERSION="1.9.4")
if(WIN32)
  list(APPEND TW_DEFS _CRT_SECURE_NO_WARNINGS _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)
elseif(APPLE)
  list(APPEND TW_DEFS _XOPEN_SOURCE=600 _DARWIN_C_SOURCE)
else()
  list(APPEND TW_DEFS _XOPEN_SOURCE=600 _GNU_SOURCE)
endif()

if(MSVC)
  set(TW_OPT /O2 /Ob2 /Oi /utf-8 /w /external:W0 /bigobj)
else()
  set(TW_OPT -O3 -ffunction-sections -fdata-sections -w)
endif()

# WebAssembly: SIMD128 and native exceptions on every object, and for the mt
# variant -pthread everywhere, because atomics and bulk memory must be in
# every object of a shared-memory module.
set(TW_WASM_COMPILE "")
if(EMSCRIPTEN)
  set(TW_WASM_COMPILE -msimd128 -fwasm-exceptions)
  if(TW_WASM_THREADS)
    list(APPEND TW_WASM_COMPILE -pthread)
  endif()
  add_compile_options(${TW_WASM_COMPILE})
  # ggml sizes each scheduler's split-copy context for 30 inputs per node
  # (about 70 MB for each of whisper's four schedulers). One CPU backend never
  # copies a split input, and a wasm heap commits what is malloc'd, so the
  # web build keeps 1 (0 would stop the input arrays doubling); they still
  # grow on demand, with a warning.
  list(APPEND TW_DEFS GGML_SCHED_MAX_SPLIT_INPUTS=1)
endif()

# Architecture flags apply to ggml-cpu only, as upstream does.
set(TW_CPU_FLAGS "")
set(TW_CPU_DEFS "")
set(TW_CPU_ARCH_SOURCES "")
set(TW_REQUIRED 0)
if(TW_ARCH STREQUAL "x86_64_desktop")
  set(TW_CPU_ARCH_SOURCES ${TW_GGML_CPU_SOURCES_X86_64})
  if(MSVC)
    set(TW_CPU_FLAGS /arch:AVX2)
    set(TW_CPU_DEFS GGML_AVX2 GGML_FMA GGML_F16C __BMI2__ GGML_BMI2)
  else()
    set(TW_CPU_FLAGS -msse4.2 -mavx -mavx2 -mfma -mf16c -mbmi2)
    set(TW_CPU_DEFS GGML_SSE42 GGML_AVX GGML_AVX2 GGML_FMA GGML_F16C GGML_BMI2)
  endif()
  set(TW_REQUIRED 0xFF)  # SSE3 SSSE3 SSE42 AVX AVX2 FMA F16C BMI2
elseif(TW_ARCH STREQUAL "x86_64_android")
  set(TW_CPU_ARCH_SOURCES ${TW_GGML_CPU_SOURCES_X86_64})
  set(TW_CPU_FLAGS -msse4.2 -mpopcnt)
  set(TW_CPU_DEFS GGML_SSE42)
  set(TW_REQUIRED 0x07)  # SSE3 SSSE3 SSE42
elseif(TW_ARCH STREQUAL "arm64")
  set(TW_CPU_ARCH_SOURCES ${TW_GGML_CPU_SOURCES_ARM64})
  set(TW_REQUIRED 0x10000)  # armv8-a baseline: NEON
elseif(TW_ARCH STREQUAL "wasm")
  set(TW_CPU_ARCH_SOURCES ${TW_GGML_CPU_SOURCES_WASM})
  set(TW_REQUIRED 0x100000000)  # WASM_SIMD
endif()

set(TW_ENGINE OFF)
if(NOT TW_ARCH STREQUAL "")
  set(TW_ENGINE ON)
endif()
if(NOT TW_ENGINE)
  set(TW_OPENMP OFF)
endif()
message(STATUS "tapture_whisper: arch='${TW_ARCH}' engine=${TW_ENGINE} openmp=${TW_OPENMP}")

if(TW_OPENMP)
  list(APPEND TW_DEFS GGML_USE_OPENMP)
endif()

function(tw_vendor_objects name)
  set(sources "")
  foreach(source IN LISTS ARGN)
    list(APPEND sources "${TW_VENDOR}/${source}")
  endforeach()
  add_library(${name} OBJECT ${sources})
  set_target_properties(${name} PROPERTIES
    C_STANDARD 11
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    POSITION_INDEPENDENT_CODE ON
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON)
  target_compile_definitions(${name} PRIVATE ${TW_DEFS})
  target_compile_options(${name} PRIVATE ${TW_OPT})
  if(TW_OPENMP)
    target_compile_options(${name} PRIVATE -fopenmp)
  endif()
  target_include_directories(${name} PRIVATE
    "${TW_VENDOR}/ggml/include"
    "${TW_VENDOR}/ggml/src"
    "${TW_VENDOR}/ggml/src/ggml-cpu"
    "${TW_VENDOR}/include"
    "${TW_VENDOR}/src"
    "${TW_SRC}/generated")
endfunction()

set(TW_OBJECTS "")
if(TW_ENGINE)
  tw_vendor_objects(tw_ggml_base ${TW_GGML_BASE_SOURCES})
  tw_vendor_objects(tw_ggml_cpu ${TW_GGML_CPU_SOURCES} ${TW_CPU_ARCH_SOURCES})
  target_compile_options(tw_ggml_cpu PRIVATE ${TW_CPU_FLAGS})
  target_compile_definitions(tw_ggml_cpu PRIVATE ${TW_CPU_DEFS})
  tw_vendor_objects(tw_whisper ${TW_WHISPER_SOURCES})
  set(TW_OBJECTS
    $<TARGET_OBJECTS:tw_ggml_base>
    $<TARGET_OBJECTS:tw_ggml_cpu>
    $<TARGET_OBJECTS:tw_whisper>)
endif()

set(TW_LIBRARY_SOURCES
  "${TW_SRC}/tapture_whisper.cpp"
  "${TW_SRC}/tw_sha256.c"
  ${TW_OBJECTS})
if(EMSCRIPTEN)
  # An ES module factory (createTaptureWhisper) and its .wasm, with no main.
  add_executable(tapture_whisper ${TW_LIBRARY_SOURCES})
else()
  add_library(tapture_whisper SHARED ${TW_LIBRARY_SOURCES})
endif()
set(TW_OUTPUT_NAME tapture_whisper)
if(EMSCRIPTEN AND TW_WASM_THREADS)
  set(TW_OUTPUT_NAME tapture_whisper_mt)
elseif(EMSCRIPTEN)
  set(TW_OUTPUT_NAME tapture_whisper_st)
endif()
set_target_properties(tapture_whisper PROPERTIES
  OUTPUT_NAME ${TW_OUTPUT_NAME}
  C_STANDARD 11
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
  C_VISIBILITY_PRESET hidden
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON)
if(TW_ENGINE)
  set(TW_ENGINE_VALUE 1)
else()
  set(TW_ENGINE_VALUE 0)
endif()
target_compile_definitions(tapture_whisper PRIVATE
  TW_BUILD
  TW_ENGINE=${TW_ENGINE_VALUE}
  TW_REQUIRED_FEATURES=${TW_REQUIRED}ULL
  ${TW_DEFS})
if(EMSCRIPTEN AND TW_WASM_THREADS)
  target_compile_definitions(tapture_whisper PRIVATE TW_WASM_THREADS)
endif()
if(MSVC)
  target_compile_options(tapture_whisper PRIVATE /O2 /utf-8 /W4)
else()
  target_compile_options(tapture_whisper PRIVATE -O3 -Wall -Wextra)
endif()
target_include_directories(tapture_whisper PRIVATE
  "${TW_VENDOR}/include"
  "${TW_VENDOR}/ggml/include")

if(NOT EMSCRIPTEN)
  find_package(Threads REQUIRED)
  target_link_libraries(tapture_whisper PRIVATE Threads::Threads ${CMAKE_DL_LIBS})
endif()
if(NOT WIN32)
  target_link_libraries(tapture_whisper PRIVATE m)
endif()
if(TW_OPENMP)
  # A static OpenMP runtime: no libomp.so to ship or to load.
  target_link_options(tapture_whisper PRIVATE -fopenmp -static-openmp)
endif()
if(EMSCRIPTEN)
  # app-write-up section 30.4.8. The worker allocates its scratch (options,
  # out-pointers, hashes, prompts) on the stack, so malloc is not exported.
  # 64-bit values cross as BigInt, which Emscripten 6 always uses (the
  # WASM_BIGINT setting is deprecated there). Growth steps are capped at
  # 16 MB, so the heap stays close to what is allocated (the default 20%
  # step, up to 96 MB, would hold the base model's heap above its budget).
  # STRICT=2 with a pool of 8 and at most 4 compute threads: exhaustion fails
  # loudly instead of hanging a worker that cannot start a non-pooled thread
  # while ggml spin-waits.
  set(TW_WASM_LINK
    -O3 ${TW_WASM_COMPILE} --no-entry
    -sMODULARIZE -sEXPORT_ES6 -sEXPORT_NAME=createTaptureWhisper
    -sALLOW_MEMORY_GROWTH -sINITIAL_MEMORY=64MB -sMAXIMUM_MEMORY=2GB
    -sMEMORY_GROWTH_GEOMETRIC_CAP=2MB -sSTACK_SIZE=5MB -sFILESYSTEM=0
    -sENVIRONMENT=worker,node
    "-sEXPORTED_FUNCTIONS=@${TW_SRC}/wasm_exports.txt"
    -sEXPORTED_RUNTIME_METHODS=HEAPU8,HEAP32,HEAPU32,HEAPF32,HEAP64,wasmMemory,UTF8ToString,stringToUTF8,lengthBytesUTF8,stackSave,stackRestore,stackAlloc)
  if(TW_WASM_THREADS)
    list(APPEND TW_WASM_LINK -sPTHREAD_POOL_SIZE=8 -sPTHREAD_POOL_SIZE_STRICT=2)
  endif()
  target_link_options(tapture_whisper PRIVATE ${TW_WASM_LINK})
  set_target_properties(tapture_whisper PROPERTIES SUFFIX ".js")
  set_property(TARGET tapture_whisper APPEND PROPERTY LINK_DEPENDS "${TW_SRC}/wasm_exports.txt")
  # The exact flags, recorded in BUILD_INFO.json by tool/whisper_wasm.dart.
  string(REPLACE ";" " " TW_WASM_LINK_TEXT "${TW_WASM_LINK}")
  string(REPLACE "${TW_SRC}/" "src/" TW_WASM_LINK_TEXT "${TW_WASM_LINK_TEXT}")
  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/tw_wasm_flags.txt" "${TW_WASM_LINK_TEXT}")
elseif(UNIX AND NOT APPLE)
  # ELF exports exactly tw_*: hidden visibility cannot hide the typeinfo and
  # vtables that libc++ headers mark visible (std::regex in whisper.cpp).
  set(TW_EXPORT_MAP "${CMAKE_CURRENT_BINARY_DIR}/tapture_whisper.map")
  file(WRITE "${TW_EXPORT_MAP}" "{ global: tw_*; local: *; };\n")
  target_link_options(tapture_whisper PRIVATE
    "-Wl,--version-script=${TW_EXPORT_MAP}"
    "-Wl,--gc-sections"
    "-Wl,--exclude-libs,ALL")
  set_property(TARGET tapture_whisper APPEND PROPERTY LINK_DEPENDS "${TW_EXPORT_MAP}")
endif()
if(ANDROID)
  # 16 KiB pages (Android 15+ devices), checked by tool/check_native_library.dart.
  target_link_options(tapture_whisper PRIVATE
    "-Wl,-z,max-page-size=16384"
    "-Wl,-z,common-page-size=16384"
    "-Wl,--build-id")
endif()

if(TW_BUILD_SMOKE)
  add_executable(tw_smoke "${TW_SRC}/smoke/tw_smoke.c")
  set_target_properties(tw_smoke PROPERTIES C_STANDARD 11)
  target_compile_definitions(tw_smoke PRIVATE _CRT_SECURE_NO_WARNINGS)
  target_link_libraries(tw_smoke PRIVATE tapture_whisper)
endif()
