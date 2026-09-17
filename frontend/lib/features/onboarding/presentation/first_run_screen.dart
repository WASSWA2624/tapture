import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/core/widgets/app_brand_lockup.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// The one screen between install and first capture: an operator name, then
/// start a project with a shipped template or skip through to capture.
class FirstRunScreen extends ConsumerStatefulWidget {
  /// Creates the first-run screen.
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FirstRunSnapshot run = ref.watch(firstRunProvider);
    final Widget field = AppTextField(
      label: Copy.firstRunName,
      controller: _name,
      textInputAction: TextInputAction.done,
      onSubmitted: (String value) {
        if (value.trim().isEmpty) {
          return;
        }
        ref.read(firstRunProvider.notifier).startProject(value);
      },
    );
    final Widget actions = ListenableBuilder(
      listenable: _name,
      builder: (BuildContext _, Widget? _) {
        final bool ready = _name.text.trim().isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppPrimaryAction(
              label: Copy.firstRunStartProject,
              caption: Copy.firstRunStartCaption,
              busy: run.busy,
              onPressed: ready
                  ? () {
                      ref
                          .read(firstRunProvider.notifier)
                          .startProject(_name.text);
                    }
                  : null,
            ),
            const SizedBox(height: Space.x2),
            AppButton(
              label: Copy.firstRunSkip,
              variant: AppButtonVariant.text,
              busy: run.busy,
              onPressed: ready
                  ? () {
                      ref.read(firstRunProvider.notifier).skip(_name.text);
                    }
                  : null,
            ),
          ],
        );
      },
    );
    return ResponsiveBuilder(
      compact: (BuildContext _) {
        return AppPage(
          title: Copy.firstRunTitle,
          subtitle: Copy.firstRunSubtitle,
          leading: AppBrandLockup(
            showName: false,
            inverted: Theme.of(context).brightness != Brightness.dark,
          ),
          body: field,
          footer: actions,
        );
      },
      medium: (BuildContext _) {
        return AppPage(
          title: Copy.firstRunTitle,
          subtitle: Copy.firstRunSubtitle,
          leading: AppBrandLockup(
            showName: false,
            inverted: Theme.of(context).brightness != Brightness.dark,
          ),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              field,
              const SizedBox(height: Space.x6),
              actions,
            ],
          ),
        );
      },
    );
  }
}

/// What the first-run gate and screen both read.
typedef FirstRunSnapshot = ({
  bool completed,
  String name,
  bool startProject,
  bool busy,
});

/// Kept alive: the router redirect reads this on every navigation
/// (FE-STATE-09). The notifier stays private so this file holds one public
/// class (FE-STR-06).
final NotifierProvider<_FirstRun, FirstRunSnapshot> firstRunProvider =
    NotifierProvider<_FirstRun, FirstRunSnapshot>(_FirstRun.new);

/// Injects a fake store so tests never touch the disk (FE-TEST-03).
Override firstRunOverride(Map<String, String> backing) {
  return firstRunProvider.overrideWith(
    () => _FirstRun.withStore(TextStore.firstRun(backing)),
  );
}

/// Marks first-run complete so suites that are not about it skip the gate.
Override firstRunCompletedOverride() {
  return firstRunOverride(<String, String>{
    AppConstants.preferences.firstRun: _encode(_completedAda),
  });
}

const FirstRunSnapshot _fresh = (
  completed: false,
  name: '',
  startProject: false,
  busy: false,
);

const FirstRunSnapshot _completedAda = (
  completed: true,
  name: 'Ada',
  startProject: false,
  busy: false,
);

class _FirstRun extends Notifier<FirstRunSnapshot> {
  _FirstRun() : this.withStore(TextStore.firstRun());

  _FirstRun.withStore(this._store);

  final TextStore _store;

  @override
  FirstRunSnapshot build() => _decode(_store.read());

  /// Persist the name and open capture with a shipped template.
  Future<void> startProject(String name) => _finish(name, startProject: true);

  /// Persist the name and open capture without creating a project.
  Future<void> skip(String name) => _finish(name, startProject: false);

  Future<void> _finish(String name, {required bool startProject}) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty || state.busy || state.completed) {
      return;
    }
    state = (
      completed: false,
      name: trimmed,
      startProject: startProject,
      busy: true,
    );
    final FirstRunSnapshot next = (
      completed: true,
      name: trimmed,
      startProject: startProject,
      busy: false,
    );
    await _store.write(_encode(next));
    state = next;
  }
}

String _encode(FirstRunSnapshot snapshot) {
  return Uri(
    queryParameters: <String, String>{
      'completed': snapshot.completed ? '1' : '0',
      'name': snapshot.name,
      'startProject': snapshot.startProject ? '1' : '0',
    },
  ).query;
}

FirstRunSnapshot _decode(String? raw) {
  if (raw == null || raw.isEmpty) {
    return _fresh;
  }
  final Map<String, String> query = Uri.splitQueryString(raw);
  return (
    completed: query['completed'] == '1',
    name: query['name'] ?? '',
    startProject: query['startProject'] == '1',
    busy: false,
  );
}
