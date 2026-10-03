import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

/// Shows the server address, the account, its organisation and role, the
/// enrolment state and when the cached grant ends (§57). Nothing here turns
/// the backend on or off; an unreachable server is one quiet line.
class BackendSettingsScreen extends StatelessWidget {
  /// Creates the screen from the cached [config] and its [authority].
  const BackendSettingsScreen({
    super.key,
    required this.config,
    this.authority = AuthorityState.cachedValid,
    this.onSignIn,
    this.onSignOut,
  });

  /// Enrolment cached on the device.
  final BackendConfig config;

  /// How far the cached grant reaches now.
  final AuthorityState authority;

  /// Opens the sign-in. Offered only while the device needs one.
  final VoidCallback? onSignIn;

  /// Asks to sign out. Offered only while the device is signed in.
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool signedIn = !config.needsSignIn;
    final DateTime? until = config.grantValidUntil;
    final String? organisation = config.organisationId;
    final String? role = config.role;
    final VoidCallback? onSignOut = this.onSignOut;
    return AppPage(
      title: localCopy.backendSettingsTitle,
      footer: signedIn
          ? null
          : AppPrimaryAction(
              label: localCopy.signInAction,
              onPressed: onSignIn,
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ..._banners(localCopy),
          AppListTile(
            title: localCopy.backendServerAddress,
            subtitle: config.baseUrl,
          ),
          if (organisation != null && organisation.isNotEmpty)
            AppListTile(
              title: localCopy.signInOrganisation,
              subtitle: organisation,
            ),
          AppListTile(
            title: localCopy.signInEmail,
            subtitle:
                config.accountEmail ??
                (signedIn
                    ? localCopy.backendSignedIn
                    : localCopy.backendNotSignedIn),
          ),
          if (role != null)
            AppListTile(
              title: localCopy.backendRole,
              subtitle: localCopy.backendRoleName(role),
            ),
          AppListTile(
            title: localCopy.backendEnrolment,
            subtitle: switch (config.state) {
              EnrolmentState.notEnrolled => localCopy.backendNotEnrolled,
              EnrolmentState.enrolling => localCopy.backendEnrolling,
              EnrolmentState.enrolled => localCopy.backendEnrolled,
              EnrolmentState.revoked => localCopy.backendRevokedState,
            },
          ),
          if (until != null)
            AppListTile(
              title: localCopy.backendGrantUntil,
              subtitle: DateFormat.yMMMd().format(until.toLocal()),
            ),
          if (signedIn && onSignOut != null) ...<Widget>[
            const SizedBox(height: Space.x4),
            AppButton(
              label: localCopy.signOutAction,
              variant: AppButtonVariant.destructive,
              expand: true,
              onPressed: onSignOut,
            ),
          ],
        ],
      ),
    );
  }

  /// At most one state line: revoked, then expired, then unreachable.
  List<Widget> _banners(LocalizedCopy copy) {
    final (String, SnackTone)? line = switch (config) {
      BackendConfig(state: EnrolmentState.revoked) => (
        copy.backendRevoked,
        SnackTone.error,
      ),
      BackendConfig(state: EnrolmentState.enrolled)
          when authority == AuthorityState.cachedExpired =>
        (copy.backendGrantExpired, SnackTone.warning),
      BackendConfig(reachable: false) => (
        copy.backendUnreachable,
        SnackTone.info,
      ),
      _ => null,
    };
    if (line == null) {
      return const <Widget>[];
    }
    final (String message, SnackTone tone) = line;
    return <Widget>[
      AppBanner(message: message, icon: tone.icon, tone: tone),
      const SizedBox(height: Space.x3),
    ];
  }
}
