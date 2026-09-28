import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';

/// Shows the server address, the account, enrolment and when the grant ends.
class BackendSettingsScreen extends StatelessWidget {
  /// Creates the screen from the cached [config].
  const BackendSettingsScreen({
    super.key,
    required this.config,
    this.actions = const <Widget>[],
  });

  /// Enrolment cached on the device.
  final BackendConfig config;

  /// Account actions supplied by the route that owns enrolment.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: Copy.backendSettingsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppListTile(
            title: Copy.backendServerAddress,
            subtitle: config.baseUrl,
          ),
          AppListTile(
            title: Copy.signInEmail,
            subtitle: config.accountEmail ?? Copy.signInTitle,
          ),
          Text(
            config.needsSignIn ? Copy.backendNotSignedIn : Copy.backendSignedIn,
          ),
          if (config.grantValidUntil != null)
            AppListTile(
              title: Copy.backendGrantUntil,
              subtitle: DateFormat.yMMMd().format(
                config.grantValidUntil!.toLocal(),
              ),
            ),
          if (!config.reachable) const Text(Copy.backendUnreachable),
          ...actions,
        ],
      ),
    );
  }
}
