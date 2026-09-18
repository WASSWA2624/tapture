import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// The kind of device the app is running on, as opposed to how wide its
/// window is: a desktop has a pointer that hovers, whatever its width, and a
/// tablet is a touch device whose shorter side is not a phone's.
enum FormFactor {
  /// A touch phone.
  mobile,

  /// A touch device whose shorter side is past the compact size class.
  tablet,

  /// Windows, macOS or Linux, natively or in a desktop browser.
  desktop;

  /// Resolves [platform] and the window [size] onto a form factor. The
  /// tablet threshold is [SizeClass]'s, so no second breakpoint exists
  /// (FE-RESP-01).
  static FormFactor resolve({
    required TargetPlatform platform,
    required Size size,
  }) {
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FormFactor.desktop;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return SizeClass.fromWidth(size.shortestSide) == SizeClass.compact
            ? FormFactor.mobile
            : FormFactor.tablet;
    }
  }
}

/// Form factor from the theme's platform and the window, never from a raw
/// width in a feature (FE-RESP-02).
extension FormFactorX on BuildContext {
  /// The form factor of this device. The platform comes from the theme so a
  /// test can set it.
  FormFactor get formFactor {
    return FormFactor.resolve(
      platform: Theme.of(this).platform,
      size: MediaQuery.sizeOf(this),
    );
  }

  /// Whether secondary flows open as a dialog over the current screen rather
  /// than as a screen of their own: on a desktop with room for one.
  bool get prefersDialogs {
    return formFactor == FormFactor.desktop && sizeClass != SizeClass.compact;
  }
}
