import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_section_header.dart';

/// Advanced settings revealed for this screen session, without saving a setting.
class SettingsDisclosure extends ConsumerWidget {
  /// [id] is stable across locale, theme and width changes.
  const SettingsDisclosure({
    super.key,
    required this.id,
    required this.title,
    required this.children,
    this.summary,
  });

  final String id;
  final String title;
  final String? summary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool expanded = ref.watch(_disclosureProvider(id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: title,
          expanded: expanded,
          onToggle: ref.read(_disclosureProvider(id).notifier).toggle,
        ),
        if (!expanded && summary != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4),
            child: Text(
              summary!,
              style: AppText.caption.copyWith(color: context.colors.onSurface),
            ),
          ),
        if (expanded) ...children,
      ],
    );
  }
}

final _disclosureProvider = NotifierProvider.autoDispose
    .family<_Disclosure, bool, String>(_Disclosure.new);

class _Disclosure extends Notifier<bool> {
  _Disclosure(String _);

  @override
  bool build() => false;

  void toggle() => state = !state;
}
