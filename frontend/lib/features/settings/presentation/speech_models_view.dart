import 'package:tapture/core/speech/speech.dart';

/// The speech models on this device as the Language screen shows them: each
/// catalogue model's status, the device that decides which fit, whether
/// this platform imports, the models checked this session, and the work in
/// flight (a model being checked or removed, or an import).
typedef SpeechModelsView = ({
  List<SpeechModelStatus> models,
  SpeechDeviceProfile device,
  bool canImport,
  Set<String> verified,
  String? working,
  bool importing,
});
