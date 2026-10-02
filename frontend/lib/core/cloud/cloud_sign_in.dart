import 'cloud_settings.dart';
import 'cloud_sign_in_stub.dart'
    if (dart.library.io) 'cloud_sign_in_io.dart'
    as platform;

/// The native browser handoff, when this platform can receive its callback.
CloudSignIn? platformCloudSignIn() => platform.platformCloudSignIn();
