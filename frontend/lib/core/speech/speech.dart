/// On-device speech: the model catalogue now, the whisper engine later.
///
/// Network-free by construction (FE-SEC-03): the only download of a model is
/// the build-time `tool/speech_models.dart --fetch`.
library;

export 'speech_model_catalogue.dart';
export 'speech_model_entry.dart';
export 'speech_model_header.dart';
export 'speech_model_kind.dart';
export 'speech_model_tier.dart';
