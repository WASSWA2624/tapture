# tapture_whisper: the shim and the vendored whisper.cpp 1.9.4 / ggml 0.23.0
# CPU engine as one shared library (dev-plan task 103, app-write-up §30.4.1).
#
# One file serves the Android NDK (CMake 3.22.1), MSVC (CMake 4.x) and the
# Linux desktop. The vendored sources come from whisper_sources.cmake; none of
# upstream's CMake is used: no apply_standard_settings, FetchContent,
# file(DOWNLOAD), install(), git probe, BLAS, Metal or GGML_NATIVE.
#
# Options:
#   TW_OPENMP       persistent OpenMP team in ggml-cpu (default ON on Android,
#                   statically linked; OFF elsewhere)
#   TW_BUILD_SMOKE  also build the tw_smoke command-line test
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
  set(TW_OPT /O2 /Ob2 /Oi /utf-8 /w /bigobj)
else()
  set(TW_OPT -O3 -ffunction-sections -fdata-sections -w)
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

add_library(tapture_whisper SHARED
  "${TW_SRC}/tapture_whisper.cpp"
  "${TW_SRC}/tw_sha256.c"
  ${TW_OBJECTS})
set_target_properties(tapture_whisper PROPERTIES
  OUTPUT_NAME tapture_whisper
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
if(MSVC)
  target_compile_options(tapture_whisper PRIVATE /O2 /utf-8 /W4)
else()
  target_compile_options(tapture_whisper PRIVATE -O3 -Wall -Wextra)
endif()
target_include_directories(tapture_whisper PRIVATE
  "${TW_VENDOR}/include"
  "${TW_VENDOR}/ggml/include")

find_package(Threads REQUIRED)
target_link_libraries(tapture_whisper PRIVATE Threads::Threads ${CMAKE_DL_LIBS})
if(NOT WIN32)
  target_link_libraries(tapture_whisper PRIVATE m)
endif()
if(TW_OPENMP)
  # A static OpenMP runtime: no libomp.so to ship or to load.
  target_link_options(tapture_whisper PRIVATE -fopenmp -static-openmp)
endif()
if(ANDROID)
  target_link_options(tapture_whisper PRIVATE
    "-Wl,-z,max-page-size=16384"
    "-Wl,-z,common-page-size=16384"
    "-Wl,--gc-sections"
    "-Wl,--exclude-libs,ALL"
    "-Wl,--build-id")
elseif(UNIX AND NOT APPLE)
  target_link_options(tapture_whisper PRIVATE
    "-Wl,--gc-sections"
    "-Wl,--exclude-libs,ALL")
endif()

if(TW_BUILD_SMOKE)
  add_executable(tw_smoke "${TW_SRC}/smoke/tw_smoke.c")
  set_target_properties(tw_smoke PROPERTIES C_STANDARD 11)
  target_compile_definitions(tw_smoke PRIVATE _CRT_SECURE_NO_WARNINGS)
  target_link_libraries(tw_smoke PRIVATE tapture_whisper)
endif()
