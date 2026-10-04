/// Audio recording and streaming capture: the recorder contracts, the
/// platform adapters, the staged take and the microphone's one owner.
library;

export 'audio_capture_event.dart';
export 'audio_capture_plugin.dart' show AudioCapturePlugin;
export 'audio_capture_request.dart';
export 'audio_capture_service.dart';
export 'audio_capture_session.dart';
export 'audio_recorder_plugin.dart';
export 'audio_recorder_service.dart';
export 'audio_recording.dart';
export 'capture_format.dart';
export 'capture_pause_reason.dart';
export 'file_pcm_store.dart';
export 'memory_pcm_store.dart';
export 'microphone_access.dart';
export 'microphone_arbiter.dart';
export 'microphone_lease.dart';
export 'microphone_owner.dart';
export 'pcm_chunk.dart';
export 'pcm_level_meter.dart';
export 'pcm_resampler.dart';
export 'pcm_ring.dart';
export 'pcm_store.dart';
export 'staged_take.dart';
export 'staged_take_recovery.dart';
export 'wav_header.dart';
export 'wav_take.dart';
