#pragma once

// Upstream configures ggml/src/ggml-version.h.in from CMake and a git probe.
// The vendored build uses neither, so the values for whisper.cpp v1.9.4
// (ggml 0.23.0, commit 927cfce3) are committed here (dev-plan task 102).

#define GGML_VERSION "0.23.0"
#define GGML_COMMIT  "927cfce3"
