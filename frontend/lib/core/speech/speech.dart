/// On-device speech: the engine contract, the transcript value types and
/// the model catalogue (spec §30.4.2).
///
/// Network-free by construction (FE-SEC-03): the only download of a model is
/// the build-time `tool/speech_models.dart --fetch`. Platform engines
/// (`_io`, `_web`) and stubs are never exported.
library;

export 'finished_utterance.dart';
export 'speech_cpu_feature.dart';
export 'speech_decode_kind.dart';
export 'speech_decode_profile.dart';
export 'speech_decode_request.dart';
export 'speech_decode_result.dart';
export 'speech_engine.dart';
export 'speech_engine_state.dart';
export 'speech_failures.dart';
export 'speech_languages.dart';
export 'speech_load_report.dart';
export 'speech_model_catalogue.dart';
export 'speech_model_entry.dart';
export 'speech_model_header.dart';
export 'speech_model_kind.dart';
export 'speech_model_shape.dart';
export 'speech_model_source.dart';
export 'speech_model_tier.dart';
export 'speech_piece.dart';
export 'speech_piece_text.dart';
export 'speech_runtime_facts.dart';
export 'speech_segment.dart';
export 'speech_text.dart';
export 'speech_unavailable_reason.dart';
export 'speech_vad_handle.dart';
export 'speech_vad_result.dart';
export 'transcript_outcome.dart';
export 'transcript_segment.dart';
export 'transcript_sink.dart';
export 'transcript_word.dart';
