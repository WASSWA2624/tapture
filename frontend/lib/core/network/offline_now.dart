import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while no network path is available or the operator chose to stay
/// offline. `main.dart` derives it from the shell's network watch; tests
/// override it. Features read this instead of the app layer's watch.
final Provider<bool> offlineNowProvider = Provider<bool>((Ref _) => false);
