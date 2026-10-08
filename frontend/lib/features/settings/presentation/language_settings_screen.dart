import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/setting_key.dart';
import '../domain/setting_keys.dart';
import '../settings.dart' show SettingsStore;
import 'offline_switch.dart';
import 'speech_settings_section.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// The app language, the language dictation listens for, and on-device
/// speech (§57, §30.4.2).
class LanguageSettingsScreen extends ConsumerWidget {
  /// Creates the Language screen.
  const LanguageSettingsScreen({super.key});

  /// Languages a speech engine commonly offers, by BCP 47 tag.
  static List<Choice<String>> _voiceLanguages(LocalizedCopy copy) =>
      <Choice<String>>[
        Choice<String>('en', copy.languageEnglish),
        Choice<String>('fr', copy.languageFrench),
        Choice<String>('sw', copy.languageSwahili),
        Choice<String>('pt', copy.languagePortuguese),
        Choice<String>('es', copy.languageSpanish),
        Choice<String>('ar', copy.languageArabic),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppPage(
      title: localCopy.settingsLanguageTitle,
      inset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppListTile(
            title: localCopy.settingsAppLanguage,
            subtitle: localCopy.settingsAppLanguageEffect,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.x4,
              vertical: Space.x2,
            ),
            child: AppChoiceField<String>(
              alwaysSheet: true,
              label: localCopy.settingsVoiceLanguage,
              value: ref.watch(voiceLanguageProvider),
              options: _voiceLanguages(localCopy),
              onChanged: (String? tag) {
                if (tag != null) {
                  unawaited(_writeLanguage(context, ref, tag));
                }
              },
            ),
          ),
          const SpeechSettingsSection(),
        ],
      ),
    );
  }
}

/// The language dictation listens for, re-read from the settings store on
/// every change rather than held as a second copy (FE-STATE-06). Kept
/// alive: the app shell hands it to dictation (FE-STATE-09).
final NotifierProvider<_VoiceLanguage, String> voiceLanguageProvider =
    NotifierProvider<_VoiceLanguage, String>(_VoiceLanguage.new);

class _VoiceLanguage extends Notifier<String> {
  StreamSubscription<SettingKey<Object?>>? _changes;

  @override
  String build() {
    final SettingsStore store = ref.watch(offlineStoreProvider);
    unawaited(_changes?.cancel());
    _changes = store.changes().listen((SettingKey<Object?> key) {
      if (key.name == SettingKeys.voiceLanguage.name) {
        state = store.read(SettingKeys.voiceLanguage);
      }
    });
    ref.onDispose(() {
      unawaited(_changes?.cancel());
      _changes = null;
    });
    return store.read(SettingKeys.voiceLanguage);
  }

  /// Persists [tag]; the state follows once the write has committed.
  Future<Result<void>> set(String tag) async {
    final SettingsStore store = ref.read(offlineStoreProvider);
    final Result<void> result = await store.write(
      SettingKeys.voiceLanguage,
      tag,
    );
    if (ref.mounted) {
      state = store.read(SettingKeys.voiceLanguage);
    }
    return result;
  }
}

Future<void> _writeLanguage(
  BuildContext context,
  WidgetRef ref,
  String tag,
) async {
  final Result<void> result = await ref
      .read(voiceLanguageProvider.notifier)
      .set(tag);
  if (result case FailureResult<void>(
    :final Failure failure,
  ) when context.mounted) {
    showAppSnack(
      context,
      Copy.of(context).failureMessage(failure),
      tone: SnackTone.error,
    );
  }
}
