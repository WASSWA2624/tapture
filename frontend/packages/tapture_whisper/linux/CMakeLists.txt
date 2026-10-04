# Placeholder from dev-plan task 102 so the app's desktop build configures
# while the plugin has no native build yet. Task 103 replaces this file with
# the engine build (add_subdirectory of ../src) and sets the bundled library.
cmake_minimum_required(VERSION 3.14)
project(tapture_whisper LANGUAGES CXX)
set(tapture_whisper_bundled_libraries "" PARENT_SCOPE)
