import 'package:flutter/widgets.dart';

/// Rebuilds a [State] after [apply].
///
/// Feature screens mix this in so `setState` stays in `core/widgets`
/// (FE-STATE-01). The rebuild still runs through the [State], which keeps
/// a [ConsumerState]'s `ref` valid.
mixin StateRefresh<T extends StatefulWidget> on State<T> {
  /// Applies [apply], then rebuilds.
  void refresh(VoidCallback apply) {
    setState(apply);
  }
}
