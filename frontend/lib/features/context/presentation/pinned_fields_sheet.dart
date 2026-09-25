import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/templates/templates.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_state.dart';
import 'context_providers.dart';

/// Opens the pinned-fields sheet.
Future<void> showPinnedFieldsSheet({
  required BuildContext context,
  required String projectId,
  Failure? failure,
}) {
  return showAppSheet<void>(
    context,
    title: Copy.contextPinnedTitle,
    builder: (BuildContext context) {
      return PinnedFieldsSheet(projectId: projectId, failure: failure);
    },
  );
}

/// Pins stickable non-hierarchical fields.
class PinnedFieldsSheet extends ConsumerStatefulWidget {
  /// Creates the sheet body.
  const PinnedFieldsSheet({super.key, required this.projectId, this.failure});

  /// Owning project.
  final String projectId;

  /// Injected failure for tests.
  final Failure? failure;

  @override
  ConsumerState<PinnedFieldsSheet> createState() => _PinnedFieldsSheetState();
}

class _PinnedFieldsSheetState extends ConsumerState<PinnedFieldsSheet> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  List<FieldDef> _fields = const <FieldDef>[];
  Failure? _error;
  bool _busy = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure ?? _error;
    if (failure != null) {
      return AsyncValueView<void>(
        value: AsyncValue<void>.error(failure, StackTrace.empty),
        data: (_) => const SizedBox.shrink(),
        onRetry: () => setState(() => _error = null),
      );
    }
    if (!_ready) {
      return const SizedBox.shrink();
    }
    if (_fields.isEmpty) {
      final bool hasTemplates =
          (ref
                      .watch(_attachedTemplatesProvider(widget.projectId))
                      .asData
                      ?.value ??
                  const <TemplateDef>[])
              .isNotEmpty;
      return AppEmptyState(
        icon: AppIcons.pin,
        headline: Copy.contextPinnedEmptyHeadline,
        message: hasTemplates
            ? Copy.contextPinnedEmptyMessage
            : Copy.contextNoTemplatesMessage,
        actionLabel: hasTemplates
            ? Copy.contextMarkPinnable
            : Copy.contextOpenTemplates,
        onAction: () => context.push(
          hasTemplates
              ? RoutePaths.projectTemplates(widget.projectId)
              : RoutePaths.templateLibrary(projectId: widget.projectId),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        const Text(Copy.contextPinnedRelevance),
        const SizedBox(height: Space.x3),
        for (final FieldDef field in _fields)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x2),
            child: AppTextField(
              label: field.label,
              controller: _controllers[field.fieldKey]!,
            ),
          ),
        AppButton(
          label: Copy.ok,
          busy: _busy,
          onPressed: _busy ? null : () => unawaited(_save()),
        ),
      ],
    );
  }

  Future<void> _load() async {
    try {
      final ContextState state =
          ref.read(projectContextProvider(widget.projectId)).asData?.value ??
          const ContextState();
      final Set<String> levelKeys = <String>{
        for (final ContextLevel level in state.levels) level.fieldKey,
      };
      final List<TemplateDef> templates = await ref
          .read(templateRepositoryProvider)
          .watchByProject(widget.projectId)
          .first;
      final List<FieldDef> stickable = <FieldDef>[];
      final Set<String> seen = <String>{};
      for (final TemplateDef template in templates) {
        for (final FieldDef field in template.fields) {
          if (field.stickable &&
              !levelKeys.contains(field.fieldKey) &&
              seen.add(field.fieldKey)) {
            stickable.add(field);
          }
        }
      }
      for (final FieldDef field in stickable) {
        _controllers[field.fieldKey] = TextEditingController(
          text: state.pinned[field.fieldKey] ?? '',
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _fields = stickable;
        _ready = true;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ready = true;
        _error = Failure.from(error);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final Map<String, String> pinned = <String, String>{
      for (final MapEntry<String, TextEditingController> e
          in _controllers.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    };
    final Result<ContextState> result = await ref
        .read(contextRepositoryProvider)
        .savePinned(widget.projectId, pinned);
    if (!mounted) {
      return;
    }
    switch (result) {
      case FailureResult<ContextState>(:final Failure failure):
        setState(() {
          _busy = false;
          _error = failure;
        });
      case Success<ContextState>():
        Navigator.of(context).maybePop();
    }
  }
}

final _attachedTemplatesProvider =
    StreamProvider.family<List<TemplateDef>, String>((
      Ref ref,
      String projectId,
    ) {
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);
