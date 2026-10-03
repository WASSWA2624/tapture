import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/device/app_version.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Version, build, licences, and links to the plan and the specification.
class AboutScreen extends ConsumerWidget {
  /// Creates the About screen.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<_AboutView> value = ref.watch(aboutProvider);
    return AppPage(
      title: localCopy.settingsAboutTitle,
      inset: false,
      body: AsyncValueView<_AboutView>(
        value: value,
        isEmpty: (_AboutView view) =>
            view.version.isEmpty && view.build.isEmpty,
        onRetry: () => ref.invalidate(aboutProvider),
        empty: () {
          final LocalizedCopy localCopy = Copy.of(context);

          return AppEmptyState(
            icon: AppIcons.info,
            headline: localCopy.settingsAboutEmptyHeadline,
            message: localCopy.settingsAboutEmptyMessage,
            actionLabel: localCopy.tryAgain,
            onAction: () => ref.invalidate(aboutProvider),
          );
        },
        data: (_AboutView view) {
          final LocalizedCopy localCopy = Copy.of(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppListTile(
                title: localCopy.settingsVersion,
                subtitle: view.version,
              ),
              AppListTile(title: localCopy.settingsBuild, subtitle: view.build),
              AppListTile(
                title: localCopy.settingsLicences,
                subtitle: localCopy.settingsLicencesEffect,
                trailing: const Icon(AppIcons.open),
                onTap: () => context.go(RoutePaths.settingsLicences),
              ),
              for (final ({String title, String url}) link in _links(localCopy))
                AppListTile(
                  key: ValueKey<String>('about-${link.url}'),
                  title: link.title,
                  subtitle: link.url,
                  trailing: const Icon(AppIcons.open),
                  onTap: () {
                    unawaited(
                      ref
                          .read(aboutProvider.notifier)
                          .openUrl(context, link.url),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Where the plan and the specification are published.
List<({String title, String url})> _links(LocalizedCopy copy) =>
    <({String title, String url})>[
      (title: copy.settingsPlanLink, url: _planUrl),
      (title: copy.settingsSpecLink, url: _specUrl),
    ];

/// The development plan's index in the public repository.
const String _planUrl =
    'https://github.com/WASSWA2624/tapture/blob/main/dev-plan/INDEX.md';

/// The product specification in the public repository.
const String _specUrl =
    'https://github.com/WASSWA2624/tapture/blob/main/app-write-up.md';

/// Injects version, build and link opening so tests never read the platform.
Override aboutOverride({
  Future<({String version, String build})> Function()? load,
  Future<void> Function(String url)? openUrl,
  Object? failWith,
  bool pending = false,
}) {
  return aboutProvider.overrideWith(
    () => _About.withLoad(
      load,
      openUrl: openUrl,
      failWith: failWith,
      pending: pending,
    ),
  );
}

/// Version on this device. A failed read shows immediately — Riverpod's
/// default backoff would keep the screen in [AsyncLoading] (FE-STATE-11).
final AsyncNotifierProvider<_About, _AboutView> aboutProvider =
    AsyncNotifierProvider<_About, _AboutView>(
      _About.new,
      retry: (int _, Object _) => null,
    );

typedef _AboutView = ({String version, String build});

class _About extends AsyncNotifier<_AboutView> {
  _About() : _load = null, _openUrl = null, _failWith = null, _pending = false;

  _About.withLoad(
    this._load, {
    this._openUrl,
    this._failWith,
    this._pending = false,
  });

  final Future<({String version, String build})> Function()? _load;
  final Future<void> Function(String url)? _openUrl;
  final Object? _failWith;
  final bool _pending;

  @override
  Future<_AboutView> build() async {
    if (_pending) {
      return Completer<_AboutView>().future;
    }
    final Object? failWith = _failWith;
    if (failWith != null) {
      throw _asError(failWith);
    }
    final Future<({String version, String build})> Function()? load = _load;
    if (load != null) {
      return load();
    }
    final DeviceDescriptor descriptor = await deviceDescriptor();
    return (version: descriptor.appVersion, build: appBuildNumber);
  }

  /// Opens [url] through the injected opener. With none (no launcher is
  /// on the allowlist), copies the link so it can be pasted into a browser,
  /// and says so.
  Future<void> openUrl(BuildContext context, String url) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Future<void> Function(String url)? opener = _openUrl;
    if (opener != null) {
      await opener(url);
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      showAppSnack(
        context,
        localCopy.settingsLinkCopied,
        tone: SnackTone.success,
      );
    }
  }
}

Object _asError(Object error) {
  if (error is Exception || error is Error) {
    return error;
  }
  return Exception(error.toString());
}
