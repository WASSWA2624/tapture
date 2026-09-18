import 'package:flutter/widgets.dart';
import 'package:tapture/core/device/device.dart';
import 'package:tapture/core/device/platform_facts.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/responsive/form_factor.dart';
import 'package:tapture/core/widgets/responsive/viewport_metrics.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/feedback_context.dart';
import '../domain/feedback_device_type.dart';
import '../domain/feedback_origin.dart';
import '../domain/feedback_submitter.dart';

/// Builds a [FeedbackContext] from the shell's [FeedbackOrigin] and what
/// this device can say about itself, without the feature reading the router.
abstract final class FeedbackContextCapture {
  /// Captures the moment Feedback was tapped.
  static FeedbackContext from({
    required BuildContext context,
    required FeedbackOrigin origin,
    required Clock clock,
    required PlatformFacts facts,
    required DeviceDescriptor device,
    OperatorProfile? operator,
    String? deviceId,
  }) {
    final ViewportMetrics metrics = context.viewportMetrics;
    final String? name = operator != null && operator.hasName
        ? operator.name.trim()
        : null;
    final String? account = operator?.accountId;
    final String? initials = operator != null && operator.hasInitials
        ? operator.initials.trim()
        : null;
    final String? contact = operator?.contact;
    return FeedbackContext(
      capturedAtUtc: clock.nowUtc(),
      submitter: FeedbackSubmitter.resolve(name: name, accountId: account),
      operatorName: name,
      operatorInitials: initials,
      operatorContact: contact != null && contact.isNotEmpty ? contact : null,
      accountId: account != null && account.trim().isNotEmpty
          ? account.trim()
          : null,
      screen: origin.screen,
      route: origin.route,
      routeName: origin.routeName,
      pageUrl: facts.pageUrl,
      projectId: origin.projectId,
      platform: facts.platform,
      deviceType: _deviceType(context.formFactor),
      appVersion: device.appVersion,
      environment: origin.environment,
      locale: Localizations.localeOf(context).toString(),
      timeZone: facts.timeZone,
      utcOffsetMinutes: clock.offset.inMinutes,
      viewportWidth: metrics.viewport.width,
      viewportHeight: metrics.viewport.height,
      devicePixelRatio: metrics.devicePixelRatio,
      displayWidth: metrics.display.width,
      displayHeight: metrics.display.height,
      orientation: metrics.orientation == Orientation.portrait
          ? 'portrait'
          : 'landscape',
      breakpoint: metrics.sizeClass.name,
      theme: origin.theme,
      textScale: metrics.textScale,
      connectivity: origin.connectivity,
      userAgent: facts.userAgent,
      addresses: facts.addresses,
      deviceId: deviceId != null && deviceId.trim().isNotEmpty
          ? deviceId.trim()
          : null,
      deviceModel: device.model,
      osVersion: device.osVersion,
    );
  }
}

FeedbackDeviceType _deviceType(FormFactor factor) {
  return switch (factor) {
    FormFactor.mobile => FeedbackDeviceType.mobile,
    FormFactor.tablet => FeedbackDeviceType.tablet,
    FormFactor.desktop => FeedbackDeviceType.desktop,
  };
}
