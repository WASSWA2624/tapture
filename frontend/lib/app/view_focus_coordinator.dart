import 'dart:ui' show PlatformDispatcher, ViewFocusEvent, ViewFocusState;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Delivers native view focus only when Flutter can traverse its laid-out tree.
///
/// A browser can return the view's initial focus request before its first
/// frame. SDK reading-order traversal then reads Navigator geometry that does
/// not yet exist. Retain the latest request until actual layout completes;
/// already laid-out views and loss of focus keep the SDK's immediate behavior.
final class ViewFocusCoordinator {
  ViewFocusCoordinator._(this._binding, this._dispatcher, this._previous);

  /// Wraps native events while retaining the binding's existing SDK callback.
  static ViewFocusCoordinator install(WidgetsBinding binding) {
    // A binding may expose a dispatcher proxy whose getter returns a trampoline
    // while its setter changes that trampoline's destination. Wrapping the
    // actual engine boundary keeps the proxy's callback intact and avoids a
    // cycle in standard, integration and custom test bindings.
    final PlatformDispatcher dispatcher = PlatformDispatcher.instance;
    final ViewFocusCoordinator coordinator = ViewFocusCoordinator._(
      binding,
      dispatcher,
      dispatcher.onViewFocusChange,
    );
    dispatcher.onViewFocusChange = coordinator._callback;
    return coordinator;
  }

  final WidgetsBinding _binding;
  final PlatformDispatcher _dispatcher;
  final void Function(ViewFocusEvent)? _previous;
  late final void Function(ViewFocusEvent) _callback = _handle;
  ViewFocusEvent? _pending;
  bool _scheduled = false;
  bool _disposed = false;

  void _handle(ViewFocusEvent event) {
    if (_disposed) return;
    if (event.state == ViewFocusState.unfocused) {
      if (_pending?.viewId == event.viewId) _pending = null;
      _previous?.call(event);
      return;
    }
    // A newer focused view must not be overtaken by an older queued request.
    _pending = null;
    if (_hasGeometry(event)) {
      _previous?.call(event);
    } else {
      _pending = event;
      _schedule();
    }
  }

  bool _hasGeometry(ViewFocusEvent event) {
    for (final RenderView view in _binding.renderViews) {
      if (view.flutterView.viewId != event.viewId) continue;
      if (view.child == null || !view.child!.hasSize) return false;
      break;
    }
    // Reading-order traversal also sorts the nodes inserted by traversal
    // groups, although those nodes are not focusable themselves. Ordinary
    // excluded nodes need no geometry and may remain unlaid while retained.
    for (final FocusNode node in _binding.focusManager.rootScope.descendants) {
      if (node.nearestScope?.canRequestFocus == false) continue;
      final BuildContext? context = node.context;
      if (context == null ||
          !context.mounted ||
          View.maybeOf(context)?.viewId != event.viewId) {
        continue;
      }
      if ((!node.canRequestFocus || node.skipTraversal) &&
          !_isTraversalGroup(context)) {
        continue;
      }
      final RenderObject? object = context.findRenderObject();
      if (object is RenderBox && (!object.attached || !object.hasSize)) {
        return false;
      }
    }
    return true;
  }

  // The public group widget inserts its own Focus directly beneath itself.
  // Inspect that relationship instead of depending on the SDK's private node
  // type or confusing an excluded ordinary Focus with a sortable group.
  bool _isTraversalGroup(BuildContext context) {
    var group = false;
    context.visitAncestorElements((Element ancestor) {
      group = ancestor.widget is FocusTraversalGroup;
      return false;
    });
    return group;
  }

  void _schedule() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    _binding.addPostFrameCallback((Duration _) => _afterLayout());
    _binding.ensureVisualUpdate();
  }

  void _afterLayout() {
    _scheduled = false;
    if (_disposed) return;
    final ViewFocusEvent? event = _pending;
    if (event == null) return;
    if (_hasGeometry(event)) {
      _pending = null;
      _previous?.call(event);
    } else {
      _schedule();
    }
  }

  /// Cancels pending delivery and restores the callback this instance wrapped.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pending = null;
    if (identical(_dispatcher.onViewFocusChange, _callback)) {
      _dispatcher.onViewFocusChange = _previous;
    }
  }
}
