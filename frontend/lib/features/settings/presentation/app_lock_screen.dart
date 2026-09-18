import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import '../domain/app_lock.dart';
import '../settings.dart' show appLockProvider;

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Set, change and remove a PIN, or unlock on launch and resume.
class AppLockScreen extends ConsumerStatefulWidget {
  /// Unlock gate shown when the lock is armed.
  const AppLockScreen({super.key}) : manage = false;

  /// Settings form for set, change and remove.
  const AppLockScreen.manage({super.key}) : manage = true;

  /// When true, this is the Security settings page.
  final bool manage;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppLockSession>(appLockSessionProvider, (
      AppLockSession? previous,
      AppLockSession next,
    ) {
      if (widget.manage) {
        return;
      }
      if (next.enabled && next.unlocked) {
        _goIntended();
      }
    });
    final _LockView view = ref.watch(_appLockViewProvider);
    if (widget.manage) {
      return AppPage(
        title: Copy.appLockTitle,
        subtitle: view.enabled ? Copy.appLockOn : Copy.appLockOff,
        body: _manageBody(view),
      );
    }
    return PopScope(
      canPop: false,
      child: AppPage(
        title: Copy.appLockUnlockTitle,
        leading: const Icon(Icons.lock_outline),
        body: _unlockBody(view),
        footer: AppPrimaryAction(
          label: Copy.appLockUnlock,
          busy: view.busy,
          onPressed: view.remaining > Duration.zero
              ? null
              : () => _unlock(view),
        ),
      ),
    );
  }

  Widget _unlockBody(_LockView view) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          label: Copy.appLockPin,
          controller: _pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: AppConstants.lock.pinMax,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          errorText: view.pinError,
          onSubmitted: (String _) => _unlock(view),
        ),
        if (view.message != null) ...<Widget>[
          const SizedBox(height: Space.x3),
          Text(
            view.message!,
            style: AppText.body.copyWith(color: context.colors.onSurface),
          ),
        ],
        if (view.biometrics) ...<Widget>[
          const SizedBox(height: Space.x4),
          AppButton(
            label: Copy.appLockBiometrics,
            variant: AppButtonVariant.secondary,
            onPressed: view.busy
                ? null
                : () {
                    ref.read(_appLockViewProvider.notifier).unlockBiometrics();
                  },
          ),
        ],
        const SizedBox(height: Space.x6),
        Text(
          Copy.appLockRecovery,
          style: AppText.body.copyWith(color: context.colors.onSurface),
        ),
      ],
    );
  }

  Widget _manageBody(_LockView view) {
    final List<Widget> fields = <Widget>[
      if (view.enabled)
        AppTextField(
          label: Copy.appLockCurrentPin,
          controller: _current,
          obscureText: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: AppConstants.lock.pinMax,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          errorText: view.currentError,
        ),
      AppTextField(
        label: view.enabled ? Copy.appLockNewPin : Copy.appLockPin,
        controller: _pin,
        obscureText: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        maxLength: AppConstants.lock.pinMax,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        errorText: view.pinError,
      ),
      AppTextField(
        label: Copy.appLockConfirmPin,
        controller: _confirm,
        obscureText: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        maxLength: AppConstants.lock.pinMax,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        errorText: view.confirmError,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: view.enabled ? Copy.appLockChange : Copy.appLockSet,
        ),
        AppForm(
          fields: fields,
          submitLabel: view.enabled ? Copy.appLockChange : Copy.appLockSet,
          errors: view.message == null
              ? const <String>[]
              : <String>[view.message!],
          onSubmit: () {
            return view.enabled
                ? ref
                      .read(_appLockViewProvider.notifier)
                      .changePin(
                        current: _current.text,
                        pin: _pin.text,
                        confirm: _confirm.text,
                      )
                : ref
                      .read(_appLockViewProvider.notifier)
                      .setPin(pin: _pin.text, confirm: _confirm.text);
          },
        ),
        if (view.enabled) ...<Widget>[
          const SizedBox(height: Space.x4),
          AppButton(
            label: Copy.appLockRemove,
            variant: AppButtonVariant.destructive,
            busy: view.busy,
            onPressed: () {
              ref.read(_appLockViewProvider.notifier).removePin(_current.text);
            },
          ),
        ],
        const SizedBox(height: Space.x6),
        Text(
          view.enabled ? Copy.appLockSetEffect : Copy.appLockOff,
          style: AppText.body.copyWith(color: context.colors.onSurface),
        ),
        const SizedBox(height: Space.x3),
        Text(
          Copy.appLockRecovery,
          style: AppText.body.copyWith(color: context.colors.onSurface),
        ),
        if (view.enabled) ...<Widget>[
          const SizedBox(height: Space.x3),
          Text(
            Copy.appLockRemoveEffect,
            style: AppText.body.copyWith(color: context.colors.onSurface),
          ),
        ],
      ],
    );
  }

  Future<void> _unlock(_LockView view) async {
    if (view.remaining > Duration.zero || view.busy) {
      return;
    }
    await ref.read(_appLockViewProvider.notifier).unlockPin(_pin.text);
  }

  void _goIntended() {
    final String? from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from != null && from.startsWith('/') && !from.startsWith('//')) {
      context.go(from);
      return;
    }
    context.go('/projects');
  }
}

/// Whether the lock is armed and whether this process has unlocked.
typedef AppLockSession = ({bool enabled, bool unlocked});

/// Kept alive: the router redirect reads this on every navigation
/// (FE-STATE-09).
final NotifierProvider<_AppLockSession, AppLockSession> appLockSessionProvider =
    NotifierProvider<_AppLockSession, AppLockSession>(_AppLockSession.new);

/// Injects a fixed session so guard tests never open secure storage.
Override appLockSessionOverride({
  required bool enabled,
  required bool unlocked,
}) {
  return appLockSessionProvider.overrideWith(
    () => _AppLockSession.fixed(enabled: enabled, unlocked: unlocked),
  );
}

class _AppLockSession extends Notifier<AppLockSession> {
  _AppLockSession() : _fixed = null;

  _AppLockSession.fixed({required bool enabled, required bool unlocked})
    : _fixed = (enabled: enabled, unlocked: unlocked);

  final AppLockSession? _fixed;

  @override
  AppLockSession build() {
    final LifecycleObserver lifecycle = ref.watch(lifecycleObserverProvider);
    final StreamSubscription<AppLifecycleState> sub = lifecycle.states.listen((
      AppLifecycleState state,
    ) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden) {
        lockNow();
      }
    });
    ref.onDispose(sub.cancel);

    final AppLockSession? fixed = _fixed;
    if (fixed != null) {
      return fixed;
    }

    final AppLock lock = ref.watch(appLockProvider);
    unawaited(_hydrate(lock));
    return (enabled: lock.isEnabled, unlocked: !lock.isEnabled);
  }

  /// Arms the lock after a PIN is stored, leaving this process unlocked.
  void markEnabled() {
    state = (enabled: true, unlocked: true);
  }

  /// Clears the lock after the PIN is removed.
  void markOff() {
    state = (enabled: false, unlocked: true);
  }

  /// Opens the app after a successful unlock.
  void unlock() {
    if (state.enabled) {
      state = (enabled: true, unlocked: true);
    }
  }

  /// Closes the app on pause or hidden so resume prompts again.
  void lockNow() {
    if (state.enabled) {
      state = (enabled: true, unlocked: false);
    }
  }

  Future<void> _hydrate(AppLock lock) async {
    await lock.hydrate();
    if (!ref.mounted) {
      return;
    }
    if (lock.isEnabled && !state.enabled) {
      state = (enabled: true, unlocked: false);
    }
  }
}

final NotifierProvider<_AppLockForm, _LockView> _appLockViewProvider =
    NotifierProvider<_AppLockForm, _LockView>(_AppLockForm.new);

typedef _LockView = ({
  bool enabled,
  bool biometrics,
  String? pinError,
  String? confirmError,
  String? currentError,
  String? message,
  Duration remaining,
  bool busy,
});

class _AppLockForm extends Notifier<_LockView> {
  @override
  _LockView build() {
    final AppLock lock = ref.watch(appLockProvider);
    unawaited(_loadBiometrics(lock));
    return (
      enabled: lock.isEnabled,
      biometrics: false,
      pinError: null,
      confirmError: null,
      currentError: null,
      message: null,
      remaining: lock.remainingBackoff,
      busy: false,
    );
  }

  Future<void> setPin({required String pin, required String confirm}) async {
    final String? pinError = isAppLockPin(pin) ? null : Copy.appLockPinLength;
    final String? confirmError = pin == confirm
        ? null
        : Copy.appLockPinMismatch;
    if (pinError != null || confirmError != null) {
      state = (
        enabled: state.enabled,
        biometrics: state.biometrics,
        pinError: pinError,
        confirmError: confirmError,
        currentError: null,
        message: null,
        remaining: Duration.zero,
        busy: false,
      );
      return;
    }
    final AppLock lock = ref.read(appLockProvider);
    state = _busy(lock);
    final Result<void> result = await lock.setPin(pin);
    if (result is Success<void>) {
      ref.read(appLockSessionProvider.notifier).markEnabled();
      state = (
        enabled: true,
        biometrics: state.biometrics,
        pinError: null,
        confirmError: null,
        currentError: null,
        message: null,
        remaining: Duration.zero,
        busy: false,
      );
      return;
    }
    final FailureResult<void> failed = result as FailureResult<void>;
    state = (
      enabled: lock.isEnabled,
      biometrics: state.biometrics,
      pinError: null,
      confirmError: null,
      currentError: null,
      message: failed.failure.message,
      remaining: lock.remainingBackoff,
      busy: false,
    );
  }

  Future<void> changePin({
    required String current,
    required String pin,
    required String confirm,
  }) async {
    final String? currentError = current.isEmpty ? Copy.appLockWrongPin : null;
    final String? pinError = isAppLockPin(pin) ? null : Copy.appLockPinLength;
    final String? confirmError = pin == confirm
        ? null
        : Copy.appLockPinMismatch;
    if (currentError != null || pinError != null || confirmError != null) {
      state = (
        enabled: true,
        biometrics: state.biometrics,
        pinError: pinError,
        confirmError: confirmError,
        currentError: currentError,
        message: null,
        remaining: Duration.zero,
        busy: false,
      );
      return;
    }
    final AppLock lock = ref.read(appLockProvider);
    state = _busy(lock);
    final LockAttempt attempt = await lock.unlockWithPin(current);
    if (attempt != LockAttempt.unlocked) {
      state = _fromAttempt(lock, attempt, currentError: Copy.appLockWrongPin);
      return;
    }
    final Result<void> result = await lock.setPin(pin);
    if (result is Success<void>) {
      ref.read(appLockSessionProvider.notifier).markEnabled();
      state = (
        enabled: true,
        biometrics: state.biometrics,
        pinError: null,
        confirmError: null,
        currentError: null,
        message: null,
        remaining: Duration.zero,
        busy: false,
      );
      return;
    }
    final FailureResult<void> failed = result as FailureResult<void>;
    state = (
      enabled: true,
      biometrics: state.biometrics,
      pinError: null,
      confirmError: null,
      currentError: null,
      message: failed.failure.message,
      remaining: lock.remainingBackoff,
      busy: false,
    );
  }

  Future<void> removePin(String current) async {
    if (current.isEmpty) {
      state = (
        enabled: true,
        biometrics: state.biometrics,
        pinError: null,
        confirmError: null,
        currentError: Copy.appLockWrongPin,
        message: null,
        remaining: Duration.zero,
        busy: false,
      );
      return;
    }
    final AppLock lock = ref.read(appLockProvider);
    state = _busy(lock);
    final Result<void> result = await lock.removePin(current);
    if (result is Success<void>) {
      ref.read(appLockSessionProvider.notifier).markOff();
      state = (
        enabled: false,
        biometrics: false,
        pinError: null,
        confirmError: null,
        currentError: null,
        message: null,
        remaining: Duration.zero,
        busy: false,
      );
      return;
    }
    final FailureResult<void> failed = result as FailureResult<void>;
    state = (
      enabled: true,
      biometrics: state.biometrics,
      pinError: null,
      confirmError: null,
      currentError: failed.failure.message,
      message: failed.failure.message,
      remaining: lock.remainingBackoff,
      busy: false,
    );
  }

  Future<bool> unlockPin(String pin) async {
    final AppLock lock = ref.read(appLockProvider);
    if (lock.remainingBackoff > Duration.zero) {
      state = (
        enabled: true,
        biometrics: state.biometrics,
        pinError: null,
        confirmError: null,
        currentError: null,
        message: Copy.appLockWait(lock.remainingBackoff),
        remaining: lock.remainingBackoff,
        busy: false,
      );
      return false;
    }
    state = _busy(lock);
    final LockAttempt attempt = await lock.unlockWithPin(pin);
    if (attempt == LockAttempt.unlocked) {
      ref.read(appLockSessionProvider.notifier).unlock();
      state = (
        enabled: true,
        biometrics: state.biometrics,
        pinError: null,
        confirmError: null,
        currentError: null,
        message: null,
        remaining: Duration.zero,
        busy: false,
      );
      return true;
    }
    state = _fromAttempt(lock, attempt);
    return false;
  }

  Future<void> unlockBiometrics() async {
    final AppLock lock = ref.read(appLockProvider);
    state = _busy(lock);
    final LockAttempt attempt = await lock.unlockWithBiometrics();
    if (attempt == LockAttempt.unlocked) {
      ref.read(appLockSessionProvider.notifier).unlock();
      state = (
        enabled: true,
        biometrics: state.biometrics,
        pinError: null,
        confirmError: null,
        currentError: null,
        message: null,
        remaining: Duration.zero,
        busy: false,
      );
      return;
    }
    state = (
      enabled: true,
      biometrics: state.biometrics,
      pinError: null,
      confirmError: null,
      currentError: null,
      message: null,
      remaining: lock.remainingBackoff,
      busy: false,
    );
  }

  Future<void> _loadBiometrics(AppLock lock) async {
    final bool available = await lock.biometricsAvailable();
    if (!ref.mounted) {
      return;
    }
    if (available == state.biometrics) {
      return;
    }
    state = (
      enabled: state.enabled,
      biometrics: available,
      pinError: state.pinError,
      confirmError: state.confirmError,
      currentError: state.currentError,
      message: state.message,
      remaining: state.remaining,
      busy: state.busy,
    );
  }

  _LockView _busy(AppLock lock) {
    return (
      enabled: lock.isEnabled,
      biometrics: state.biometrics,
      pinError: null,
      confirmError: null,
      currentError: null,
      message: null,
      remaining: lock.remainingBackoff,
      busy: true,
    );
  }

  _LockView _fromAttempt(
    AppLock lock,
    LockAttempt attempt, {
    String? currentError,
  }) {
    final String? message = switch (attempt) {
      LockAttempt.lockedOut => Copy.appLockWait(lock.remainingBackoff),
      LockAttempt.wrong => Copy.appLockWrongPin,
      LockAttempt.unavailable => Copy.appLockWrongPin,
      LockAttempt.unlocked => null,
    };
    return (
      enabled: lock.isEnabled,
      biometrics: state.biometrics,
      pinError: attempt == LockAttempt.wrong ? Copy.appLockWrongPin : null,
      confirmError: null,
      currentError: currentError,
      message: message,
      remaining: lock.remainingBackoff,
      busy: false,
    );
  }
}
