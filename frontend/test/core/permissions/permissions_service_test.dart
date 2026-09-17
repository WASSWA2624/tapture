import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

void main() {
  for (final AppPermission permission in AppPermission.values) {
    test('granting $permission returns granted', () async {
      final PermissionsService service = _fake(
        permission,
        PermissionState.granted,
      );

      final Result<PermissionState> requested = await service.request(
        permission,
      );
      final PermissionState status = await service.status(permission);

      expect(
        requested.fold((_) => null, (PermissionState state) => state),
        PermissionState.granted,
      );
      expect(status, PermissionState.granted);
    });

    test(
      'denying $permission returns PermissionFailure with a recovery action',
      () async {
        final List<AppPermission> prompted = <AppPermission>[];
        final List<AppPermission> settings = <AppPermission>[];
        final PermissionsService service = _fake(
          permission,
          PermissionState.denied,
          onPrompt: prompted.add,
          onOpenSettings: settings.add,
        );

        final Result<PermissionState> requested = await service.request(
          permission,
        );
        final Failure? failure = requested.fold(
          (Failure value) => value,
          (_) => null,
        );

        expect(failure, isA<PermissionFailure>());
        expect(failure?.recoveryAction, isNotEmpty);
        expect(prompted, <AppPermission>[permission]);
        expect(settings, isEmpty);
      },
    );

    test(
      'a permanently denied $permission offers settings rather than prompting',
      () async {
        final List<AppPermission> prompted = <AppPermission>[];
        final List<AppPermission> settings = <AppPermission>[];
        final PermissionsService service = _fake(
          permission,
          PermissionState.permanentlyDenied,
          onPrompt: prompted.add,
          onOpenSettings: settings.add,
        );

        final Result<PermissionState> requested = await service.request(
          permission,
        );
        final Failure? failure = requested.fold(
          (Failure value) => value,
          (_) => null,
        );

        expect(failure, isA<PermissionFailure>());
        expect(failure?.recoveryAction, contains('settings'));
        expect(prompted, isEmpty);
        expect(settings, <AppPermission>[permission]);
      },
    );
  }

  test('location is not requested while GPS is off', () async {
    final List<AppPermission> prompted = <AppPermission>[];
    final List<AppPermission> settings = <AppPermission>[];
    final PermissionsService service = PermissionsService.fake(
      states: <AppPermission, PermissionState>{
        AppPermission.location: PermissionState.granted,
      },
      gpsEnabled: () => false,
      onPrompt: prompted.add,
      onOpenSettings: settings.add,
    );

    final Result<PermissionState> requested = await service.request(
      AppPermission.location,
    );
    final PermissionState status = await service.status(AppPermission.location);

    expect(
      requested.fold((Failure failure) => failure, (_) => null),
      isA<PermissionFailure>(),
    );
    expect(status, PermissionState.denied);
    expect(prompted, isEmpty);
    expect(settings, isEmpty);
  });
}

PermissionsService _fake(
  AppPermission permission,
  PermissionState state, {
  void Function(AppPermission)? onPrompt,
  void Function(AppPermission)? onOpenSettings,
}) {
  return PermissionsService.fake(
    states: <AppPermission, PermissionState>{permission: state},
    gpsEnabled: () => true,
    onPrompt: onPrompt,
    onOpenSettings: onOpenSettings,
  );
}
