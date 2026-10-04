Implement robust, production-ready **real-time offline Speech-to-Text (STT)** using **Whisper.cpp**.

### Platform requirements
Must support **Android, iOS, Windows, macOS, web, and Linux** from one maintainable architecture. No internet, cloud STT, or external API may be required for transcription.

### Requirements
- Integrate Whisper.cpp through a clean cross-platform native/FFI abstraction.
- Capture and stream microphone audio continuously.
- Convert/resample audio to Whisper-compatible **16 kHz mono PCM**.
- Implement **VAD** to detect speech and avoid processing silence.
- Provide low-latency partial/interim transcripts followed by stable finalized segments.
- Correctly merge segments without duplicated, missing, or reordered text.
- Handle pauses, punctuation, numbers, repeated speech, and long recording sessions.
- Use configurable quantized Whisper models, balancing accuracy, RAM, CPU, battery usage, and latency per device.
- Run capture, preprocessing, and inference asynchronously without blocking the UI.
- Support start, pause, resume, stop, cancellation, microphone interruptions, permission changes, and application lifecycle events.
- Save original audio and final transcript locally.
- Allow transcript editing.
- Gracefully detect unsupported/low-resource devices and model-loading failures.
- Keep platform-specific code isolated behind a common STT interface.
- Include logging, unit/integration tests, memory-leak protection, and performance benchmarks.
- Package models for reliable offline availability and verify model integrity before loading.
- **Never require an internet connection for STT operation.**