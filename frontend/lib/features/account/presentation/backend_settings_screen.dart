import 'package:flutter/material.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';

/// Shows the server address, the account, enrolment and when the grant ends.
class BackendSettingsScreen extends StatelessWidget {
  /// Creates the screen from the cached [config].
  const BackendSettingsScreen({super.key, required this.config});

  /// Enrolment cached on the device.
  final BackendConfig config;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: Copy.backendSettingsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(config.baseUrl),
          Text(config.accountEmail ?? Copy.signInTitle),
          Text(config.state.name),
          if (config.grantValidUntil != null)
            Text(config.grantValidUntil!.toIso8601String()),
          if (!config.reachable) const Text(Copy.backendUnreachable),
        ],
      ),
    );
  }
}
