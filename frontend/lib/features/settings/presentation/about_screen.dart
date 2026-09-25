import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Version, build and licences.
class AboutScreen extends ConsumerWidget {
  /// Creates the About screen.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<_AboutView> value = ref.watch(aboutProvider);
    return AppPage(
      title: Copy.settingsAboutTitle,
      body: AsyncValueView<_AboutView>(
        value: value,
        isEmpty: (_AboutView view) =>
            view.version.isEmpty && view.build.isEmpty,
        onRetry: () => ref.invalidate(aboutProvider),
        empty: () {
          return const AppEmptyState(
            icon: AppIcons.info,
            headline: Copy.settingsAboutEmptyHeadline,
            message: Copy.settingsAboutEmptyMessage,
          );
        },
        data: (_AboutView view) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppSectionHeader(title: Copy.settingsAboutTitle),
              AppListTile(title: Copy.settingsVersion, subtitle: view.version),
              AppListTile(title: Copy.settingsBuild, subtitle: view.build),
              AppListTile(
                title: Copy.settingsLicences,
                subtitle: Copy.settingsLicencesEffect,
                trailing: const Icon(AppIcons.open),
                onTap: () => context.go(_licencesRoute),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Injects version, build and link opening so tests never read the platform.
Override aboutOverride({
  Future<({String version, String build})> Function()? load,
  void Function(String url)? openUrl,
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

/// Build number from `pubspec.yaml` (`1.0.0+1`). No package_info on the
/// allowlist (FE-FLOW-06).
const String _appBuild = '1';

class _About extends AsyncNotifier<_AboutView> {
  _About() : _load = null, _openUrl = null, _failWith = null, _pending = false;

  _About.withLoad(
    this._load, {
    this._openUrl,
    this._failWith,
    this._pending = false,
  });

  final Future<({String version, String build})> Function()? _load;
  final void Function(String url)? _openUrl;
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
    return (version: descriptor.appVersion, build: _appBuild);
  }

  /// Opens [url] when a test or later task supplies an opener.
  void openUrl(String url) {
    _openUrl?.call(url);
  }
}

/// Must match [AppRoutes.settingsLicences]. This file cannot import
/// `router.dart`.
const String _licencesRoute = '/more/about/licences';

Object _asError(Object error) {
  if (error is Exception || error is Error) {
    return error;
  }
  return Exception(error.toString());
}
