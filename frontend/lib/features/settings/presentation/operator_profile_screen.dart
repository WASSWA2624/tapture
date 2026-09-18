import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import '../domain/operator_profile.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// The settings form for the local operator identity.
///
/// Name, initials and optional contact only. No password, PIN, token or
/// other credential is collected or stored here.
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
  final TextEditingController _contact = TextEditingController();
  int _applied = -1;
  bool _initialsOverridden = false;

  @override
  void dispose() {
    _name.dispose();
    _initials.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _bind(_OperatorProfileView view) {
    if (_applied == view.generation) {
      return;
    }
    _name.text = view.profile.name;
    _initials.text = view.profile.initials;
    _contact.text = view.profile.contact ?? '';
    _initialsOverridden =
        view.profile.initials.isNotEmpty &&
        view.profile.initials !=
            OperatorProfile.initialsFrom(view.profile.name);
    _applied = view.generation;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<_OperatorProfileView> value = ref.watch(
      operatorProfileProvider,
    );
    return AppPage(
      title: Copy.operatorProfileTitle,
      subtitle: Copy.operatorNameUse,
      body: AsyncValueView<_OperatorProfileView>(
        value: value,
        data: (_OperatorProfileView view) {
          _bind(view);
          return AppForm(
            key: ValueKey<int>(view.generation),
            guardUnsaved: true,
            errors: view.saveError == null
                ? const <String>[]
                : <String>[view.saveError!],
            fields: <Widget>[
              AppTextField(
                label: Copy.operatorName,
                controller: _name,
                textInputAction: TextInputAction.next,
                errorText: view.nameError,
                onChanged: (String value) {
                  if (!_initialsOverridden) {
                    _initials.text = OperatorProfile.initialsFrom(value);
                  }
                },
              ),
              AppTextField(
                label: Copy.operatorInitials,
                controller: _initials,
                textInputAction: TextInputAction.next,
                maxLength: AppConstants.operator.initialsMax,
                errorText: view.initialsError,
                onChanged: (String _) {
                  _initialsOverridden = true;
                },
              ),
              AppTextField(
                label: Copy.operatorContact,
                controller: _contact,
                textInputAction: TextInputAction.done,
              ),
            ],
            submitLabel: Copy.save,
            onSubmit: () {
              return ref
                  .read(operatorProfileProvider.notifier)
                  .save(
                    name: _name.text,
                    initials: _initials.text,
                    contact: _contact.text,
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
  String? nameError,
  String? initialsError,
  String? saveError,
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

  AppDatabase? _db;
  String? _device;

  @override
  Future<_OperatorProfileView> build() async {
    final OperatorProfile profile = await _read();
    return (
      profile: profile,
      nameError: null,
      initialsError: null,
      saveError: null,
      generation: 0,
    );
  }

  /// Validates and writes the single device-profile row.
  Future<void> save({
    required String name,
    required String initials,
    String? contact,
  }) async {
    final String trimmedName = name.trim();
    final String trimmedInitials = initials.trim();
    final String? trimmedContact = contact?.trim();
    final _OperatorProfileView current =
        state.value ??
        (
          profile: OperatorProfile(
            name: trimmedName,
            initials: trimmedInitials,
            contact: trimmedContact,
          ),
          nameError: null,
          initialsError: null,
          saveError: null,
          generation: 0,
        );
    final String? nameError = trimmedName.isEmpty ? Copy.nameRequired : null;
    final String? initialsError = !_validInitials(trimmedInitials)
        ? Copy.initialsLength
        : null;
    if (nameError != null || initialsError != null) {
      state = AsyncData<_OperatorProfileView>((
        profile: current.profile,
        nameError: nameError,
        initialsError: initialsError,
        saveError: null,
        generation: current.generation,
      ));
      return;
    }
    final OperatorProfile next = OperatorProfile(
      name: trimmedName,
      initials: trimmedInitials,
      contact: trimmedContact == null || trimmedContact.isEmpty
          ? null
          : trimmedContact,
      accountId: current.profile.accountId,
    );
    final Result<OperatorProfile> result = await _persist(next);
    switch (result) {
      case Success<OperatorProfile>(:final OperatorProfile value):
        state = AsyncData<_OperatorProfileView>((
          profile: value,
          nameError: null,
          initialsError: null,
          saveError: null,
          generation: current.generation + 1,
        ));
      case FailureResult<OperatorProfile>(:final failure):
        state = AsyncData<_OperatorProfileView>((
          profile: next,
          nameError: null,
          initialsError: null,
          saveError: failure.message,
          generation: current.generation,
        ));
    }
  }

  Future<OperatorProfile> _read() async {
    final _OperatorProfileStore? store = _store;
    if (store != null) {
      return store.load();
    }
    final DeviceProfileIdentity identity = await readDeviceProfile(
      _database(),
      deviceId: await _deviceId(),
    );
    return OperatorProfile.fromStored(
      name: identity.operatorName,
      preferences: identity.preferences,
      accountId: identity.accountId,
    );
  }

  Future<Result<OperatorProfile>> _persist(OperatorProfile profile) async {
    final _OperatorProfileStore? store = _store;
    if (store != null) {
      return store.save(profile);
    }
    return Result.captureAsync(() async {
      final DeviceProfileIdentity current = await readDeviceProfile(
        _database(),
        deviceId: await _deviceId(),
      );
      await writeDeviceProfile(
        _database(),
        deviceId: await _deviceId(),
        operatorName: profile.name,
        preferences: profile.mergePreferences(current.preferences),
      );
      return profile;
    });
  }

  AppDatabase _database() => _db ??= AppDatabase.open();

  Future<String> _deviceId() async {
    final String? existing = _device;
    if (existing != null) {
      return existing;
    }
    const SystemClock clock = SystemClock();
    return _device = await deviceId(clock: clock, ids: UuidV7Service(clock));
  }

  bool _validInitials(String value) {
    return value.length >= AppConstants.operator.initialsMin &&
        value.length <= AppConstants.operator.initialsMax;
  }
}
