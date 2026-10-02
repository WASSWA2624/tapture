import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/router.dart' show routerProvider;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/incoming_bundle_service.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/merge/presentation/package_import_controller.dart';
import 'package:tapture/features/merge/presentation/package_import_flow.dart';
import 'package:tapture/features/merge/presentation/package_import_phase.dart';
import 'package:tapture/features/settings/presentation/app_lock_screen.dart';

/// Queues operating-system document opens behind the lock and import preview.
/// Pausing the one subscription leaves later copies at the bounded bridge.
class IncomingBundleHost extends ConsumerStatefulWidget {
  /// Wraps the navigator without replacing its state or a capture draft.
  const IncomingBundleHost({required this.child, super.key});

  /// The application navigator.
  final Widget child;

  @override
  ConsumerState<IncomingBundleHost> createState() => _IncomingBundleHostState();
}

class _IncomingBundleHostState extends ConsumerState<IncomingBundleHost> {
  late final StreamSubscription<Result<PickedDocument>> _subscription;
  Result<PickedDocument>? _pending;
  bool _scheduled = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(incomingBundleServiceProvider).watch().listen((
      Result<PickedDocument> document,
    ) {
      _subscription.pause();
      _pending = document;
      _schedule();
    });
  }

  void _schedule() {
    if (_scheduled || _opening || _pending == null || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      _scheduled = false;
      if (!mounted || _opening || _pending == null) return;
      final AppLockSession lock = ref.read(appLockSessionProvider);
      if (lock.enabled && !lock.unlocked) return;
      if (ref.read(packageImportControllerProvider).phase !=
          PackageImportPhase.idle) {
        return;
      }
      final BuildContext? navigatorContext = ref
          .read(routerProvider)
          .routerDelegate
          .navigatorKey
          .currentContext;
      if (navigatorContext == null || !navigatorContext.mounted) return;
      unawaited(_open(navigatorContext));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _open(BuildContext navigatorContext) async {
    final Result<PickedDocument> pending = _pending!;
    _pending = null;
    _opening = true;
    final PackageImportController flow = ref.read(
      packageImportControllerProvider.notifier,
    );
    try {
      switch (pending) {
        case FailureResult<PickedDocument>(:final Failure failure):
          showAppSnack(
            navigatorContext,
            failure.message,
            tone: SnackTone.error,
            localizedMessage: failure.explanation,
          );
        case Success<PickedDocument>(:final PickedDocument value):
          await startPackageImport(
            navigatorContext,
            ref,
            supplied: value,
            waitForPreview: true,
          );
      }
    } on Object catch (error) {
      if (navigatorContext.mounted) {
        final Failure failure = Failure.from(error);
        showAppSnack(
          navigatorContext,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      }
    } finally {
      await flow.finish();
      _opening = false;
      if (mounted) _subscription.resume();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    if (_pending case Success<PickedDocument>(:final PickedDocument value)) {
      unawaited(discardPickedCopy(value));
    }
    _pending = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppLockSession>(appLockSessionProvider, (
      AppLockSession? previous,
      AppLockSession next,
    ) {
      if (!next.enabled || next.unlocked) _schedule();
    });
    ref.listen<PackageImportPhase>(
      packageImportControllerProvider.select(
        (PackageImportView view) => view.phase,
      ),
      (PackageImportPhase? previous, PackageImportPhase next) {
        if (next == PackageImportPhase.idle) _schedule();
      },
    );
    _schedule();
    return widget.child;
  }
}

/// One file bridge for this app scope, disposed with its native subscription.
final Provider<IncomingBundleService> incomingBundleServiceProvider =
    Provider<IncomingBundleService>((Ref ref) {
      final IncomingBundleService service = IncomingBundleService();
      ref.onDispose(() => unawaited(service.dispose()));
      return service;
    });
