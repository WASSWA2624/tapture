import 'package:tapture/core/files/bundled_assets.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'speech_engine.dart';
import 'speech_model_entry.dart';
import 'speech_model_store.dart';

/// The store a platform without files gets: nothing installed and no
/// import. Task 112 adds the browser store behind the same conditional
/// import.
SpeechModelStore openSpeechModelStore({
  required StorageRoot privateRoot,
  required BundledAssets assets,
  required List<SpeechModelEntry> catalogue,
  SpeechEngine? webEngine,
}) => const SpeechModelStore.empty();
