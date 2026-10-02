import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-app locale selection. A null value follows the device's supported locale.
final NotifierProvider<LocaleController, Locale?> appLocaleProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

/// Changes the inherited locale without replacing feature providers or drafts.
final class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => const bool.fromEnvironment('TAPTURE_PSEUDO_LOCALE')
      ? const Locale('en', 'XA')
      : null;

  /// Selects a supported locale, or follows the device when [locale] is null.
  void select(Locale? locale) => state = locale;
}
