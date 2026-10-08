import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';

import 'account_connection_panel.dart';

/// Compatibility wrapper for the account controls. The app redirects legacy
/// account links to the expanded AI settings section.
class AccountRoute extends StatelessWidget {
  /// Creates the compatibility wrapper.
  const AccountRoute({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: Copy.of(context).backendSettingsTitle,
    body: const AccountConnectionPanel(),
  );
}
