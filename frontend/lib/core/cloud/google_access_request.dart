import 'google_access.dart';

/// Requests interactive authorization only on an explicit sign-in action.
typedef GoogleAccessRequest =
    Future<GoogleAccess> Function({
      required bool interactive,
      String? accountId,
      String? invalidToken,
    });
