import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/fields/app_email_field.dart';
import 'package:tapture/core/widgets/fields/app_phone_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import '../domain/operator_profile.dart';
import '../settings.dart' show operatorProfileRepositoryProvider;

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// The settings form for the local operator identity.
///
/// Name, initials, optional email and optional phone only. No password,
/// PIN, token or other credential is collected or stored here.
class OperatorProfileScreen extends ConsumerStatefulWidget {
  /// Creates the operator profile screen.
  const OperatorProfileScreen({super.key});

  @override
  ConsumerState<OperatorProfileScreen> createState() =>
      _OperatorProfileScreenState();
}

class _OperatorProfileScreenState extends ConsumerState<OperatorProfileScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _initials = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  int _applied = -1;
  bool _initialsOverridden = false;

  @override
  void dispose() {
    _name.dispose();
    _initials.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _bind(_OperatorProfileView view) {
    if (_applied == view.generation) {
      return;
    }
    _name.text = view.profile.name;
    _initials.text = view.profile.initials;
    _email.text = view.profile.email ?? '';
    _phone.text = view.profile.phone ?? '';
    _initialsOverridden =
        view.profile.initials.isNotEmpty &&
        view.profile.initials !=
            OperatorProfile.initialsFrom(view.profile.name);
    _applied = view.generation;
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<_OperatorProfileView> value = ref.watch(
      operatorProfileProvider,
    );
    return AppPage(
      title: localCopy.operatorProfileTitle,
      subtitle: localCopy.operatorNameUse,
      body: AsyncValueView<_OperatorProfileView>(
        value: value,
        onRetry: () => ref.invalidate(operatorProfileProvider),
        data: (_OperatorProfileView view) {
          final LocalizedCopy localCopy = Copy.of(context);

          _bind(view);
          return AppForm(
            key: ValueKey<int>(view.generation),
            guardUnsaved: true,
            errors: view.saveError == null
                ? const <String>[]
                : <String>[localCopy.resolve(view.saveError!)],
            fields: <Widget>[
              AppTextField(
                label: localCopy.operatorName,
                controller: _name,
                requiredness: FieldRequiredness.required,
                textInputAction: TextInputAction.next,
                errorText: view.nameError == null
                    ? null
                    : localCopy.resolve(view.nameError!),
                onChanged: (String value) {
                  if (!_initialsOverridden) {
                    _initials.text = OperatorProfile.initialsFrom(value);
                  }
                },
              ),
              AppTextField(
                label: localCopy.operatorInitials,
                controller: _initials,
                requiredness: FieldRequiredness.required,
                dictation: false,
                textInputAction: TextInputAction.next,
                maxLength: AppConstants.operator.initialsMax,
                errorText: view.initialsError == null
                    ? null
                    : localCopy.resolve(view.initialsError!),
                onChanged: (String _) {
                  _initialsOverridden = true;
                },
              ),
              AppEmailField(
                label: localCopy.operatorEmail,
                controller: _email,
                requiredness: FieldRequiredness.optional,
                textInputAction: TextInputAction.next,
                errorText: view.emailError == null
                    ? null
                    : localCopy.resolve(view.emailError!),
              ),
              AppPhoneField(
                label: localCopy.operatorPhone,
                controller: _phone,
                requiredness: FieldRequiredness.optional,
                textInputAction: TextInputAction.done,
              ),
            ],
            submitLabel: localCopy.save,
            onSubmit: () {
              return ref
                  .read(operatorProfileProvider.notifier)
                  .save(
                    name: _name.text,
                    initials: _initials.text,
                    email: _email.text,
                    phone: _phone.text,
                  );
            },
          );
        },
      ),
    );
  }
}

/// Injects in-memory load and save so tests never open a database
/// (FE-TEST-03, FE-STATE-10).
Override operatorProfileOverride({
  required Future<OperatorProfile> Function() load,
  required Future<Result<OperatorProfile>> Function(OperatorProfile profile)
  save,
}) {
  return operatorProfileProvider.overrideWith(
    () => _OperatorProfile.withStore((load: load, save: save)),
  );
}

/// Kept alive: later capture reads the same profile for attribution
/// (FE-STATE-09).
final AsyncNotifierProvider<_OperatorProfile, _OperatorProfileView>
operatorProfileProvider =
    AsyncNotifierProvider<_OperatorProfile, _OperatorProfileView>(
      _OperatorProfile.new,
      retry: (int _, Object _) => null,
    );

/// The loaded operator, or null while the profile is still opening.
final Provider<OperatorProfile?> currentOperatorProvider =
    Provider<OperatorProfile?>((Ref ref) {
      final AsyncValue<_OperatorProfileView> value = ref.watch(
        operatorProfileProvider,
      );
      return value.hasValue ? value.requireValue.profile : null;
    });

typedef _OperatorProfileView = ({
  OperatorProfile profile,
  LocalizedMessage? nameError,
  LocalizedMessage? initialsError,
  LocalizedMessage? emailError,
  LocalizedMessage? saveError,
  int generation,
});

typedef _OperatorProfileStore = ({
  Future<OperatorProfile> Function() load,
  Future<Result<OperatorProfile>> Function(OperatorProfile profile) save,
});

class _OperatorProfile extends AsyncNotifier<_OperatorProfileView> {
  _OperatorProfile() : _store = null;

  _OperatorProfile.withStore(this._store);

  final _OperatorProfileStore? _store;

  @override
  Future<_OperatorProfileView> build() async {
    final OperatorProfile profile = await _read();
    return (
      profile: profile,
      nameError: null,
      initialsError: null,
      emailError: null,
      saveError: null,
      generation: 0,
    );
  }

  /// Validates and writes the single device-profile row. Completes with
  /// whether the row was stored.
  Future<bool> save({
    required String name,
    required String initials,
    String? email,
    String? phone,
  }) async {
    final String trimmedName = name.trim();
    final String trimmedInitials = initials.trim();
    final String trimmedEmail = email?.trim() ?? '';
    final String trimmedPhone = phone?.trim() ?? '';
    final String? storedEmail = trimmedEmail.isEmpty ? null : trimmedEmail;
    final String? storedPhone = trimmedPhone.isEmpty ? null : trimmedPhone;
    final _OperatorProfileView current =
        state.value ??
        (
          profile: OperatorProfile(
            name: trimmedName,
            initials: trimmedInitials,
            email: storedEmail,
            phone: storedPhone,
          ),
          nameError: null,
          initialsError: null,
          emailError: null,
          saveError: null,
          generation: 0,
        );
    final LocalizedMessage? nameError = trimmedName.isEmpty
        ? Copy.messages.nameRequired
        : null;
    final LocalizedMessage? initialsError = !_validInitials(trimmedInitials)
        ? Copy.messages.initialsLength
        : null;
    final LocalizedMessage? emailError =
        storedEmail != null && !storedEmail.contains('@')
        ? Copy.messages.emailNeedsAt
        : null;
    if (nameError != null || initialsError != null || emailError != null) {
      state = AsyncData<_OperatorProfileView>((
        profile: current.profile,
        nameError: nameError,
        initialsError: initialsError,
        emailError: emailError,
        saveError: null,
        generation: current.generation,
      ));
      return false;
    }
    final OperatorProfile next = OperatorProfile(
      name: trimmedName,
      initials: trimmedInitials,
      email: storedEmail,
      phone: storedPhone,
      accountId: current.profile.accountId,
    );
    final Result<OperatorProfile> result = await _persist(next);
    switch (result) {
      case Success<OperatorProfile>(:final OperatorProfile value):
        state = AsyncData<_OperatorProfileView>((
          profile: value,
          nameError: null,
          initialsError: null,
          emailError: null,
          saveError: null,
          generation: current.generation + 1,
        ));
        return true;
      case FailureResult<OperatorProfile>(:final failure):
        state = AsyncData<_OperatorProfileView>((
          profile: next,
          nameError: null,
          initialsError: null,
          emailError: null,
          saveError: failure.explanation,
          generation: current.generation,
        ));
        return false;
    }
  }

  /// The stored profile. A failed read fails the load, so the screen shows
  /// the error with a retry rather than an empty form.
  Future<OperatorProfile> _read() async {
    final _OperatorProfileStore? store = _store;
    if (store != null) {
      return store.load();
    }
    final Result<OperatorProfile> loaded = await ref
        .read(operatorProfileRepositoryProvider)
        .load();
    return switch (loaded) {
      Success<OperatorProfile>(:final OperatorProfile value) => value,
      FailureResult<OperatorProfile>(:final Failure failure) => throw failure,
    };
  }

  Future<Result<OperatorProfile>> _persist(OperatorProfile profile) {
    final _OperatorProfileStore? store = _store;
    if (store != null) {
      return store.save(profile);
    }
    return ref.read(operatorProfileRepositoryProvider).save(profile);
  }

  bool _validInitials(String value) {
    return value.length >= AppConstants.operator.initialsMin &&
        value.length <= AppConstants.operator.initialsMax;
  }
}
