# The Flutter Windows build of the tapture_whisper FFI plugin (dev-plan task
# 103). It adds ../src, which builds the shim and the vendored whisper.cpp
# engine as one shared library, and hands that library to the app's bundle.
# The engine build does not use the runner's apply_standard_settings: its
# warnings-as-errors would fail on vendored code.
cmake_minimum_required(VERSION 3.14)
project(tapture_whisper LANGUAGES C CXX)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")

set(tapture_whisper_bundled_libraries
  $<TARGET_FILE:tapture_whisper>
  PARENT_SCOPE
)
