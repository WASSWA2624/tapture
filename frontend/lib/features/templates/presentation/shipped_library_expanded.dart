import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Categories open in the shipped library, by code. All closed at first, so
/// the catalogue reads as areas and counted categories (FBK0000161, D11).
/// Auto-dispose: leaving the library closes them again (FE-STATE-09).
final shippedLibraryExpandedProvider =
    NotifierProvider.autoDispose<ShippedLibraryExpanded, Set<String>>(
      ShippedLibraryExpanded.new,
    );

/// Which library categories show their templates.
final class ShippedLibraryExpanded extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Opens [code] when closed, closes it when open.
  void toggle(String code) {
    state = state.contains(code)
        ? <String>{
            for (final String open in state)
              if (open != code) open,
          }
        : <String>{...state, code};
  }

  /// Opens [code], as ticking one of its templates does.
  void open(String code) {
    if (!state.contains(code)) {
      state = <String>{...state, code};
    }
  }
}
