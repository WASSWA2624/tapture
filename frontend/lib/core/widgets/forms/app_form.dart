import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_email_field.dart';
import 'package:tapture/core/widgets/fields/app_phone_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/focus_actions.dart';
import 'package:tapture/core/widgets/forms/keep_focused_visible.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';

/// The form frame every editing screen composes: spaced fields, an error
/// summary, a submit bar, and an unsaved-changes guard.
///
/// Given a bounded height (an [AppPage] with `scrollable: false`), the
/// fields scroll in a readable column and the submit bar stays pinned
/// below them. Given an unbounded one, the bar follows the last field.
class AppForm extends StatefulWidget {
  /// Creates a form. [onSubmit] runs once even if the bar is pressed twice.
  const AppForm({
    super.key,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.guardUnsaved = false,
    this.errors = const <String>[],
    this.dirty = false,
    this.compact = false,
  });

  /// Controls in visual order. Traversal follows this list (FE-A11Y-06).
  final List<Widget> fields;

  /// Verb on the submit bar. Also the semantic name of that control.
  final String submitLabel;

  /// Persist or apply. Ignored while a previous call is still running.
  final Future<void> Function() onSubmit;

  /// When true, leaving a dirty form prompts before popping.
  final bool guardUnsaved;

  /// Invalid-field lines shown at the top. Text, email and phone
  /// [errorText] values on [fields] are listed as well.
  final List<String> errors;

  /// Marks the form dirty for non-text edits (choice, date). Text fields
  /// also mark dirty on the first edit.
  final bool dirty;

  /// When true, field gaps and the submit bar use the compact spacing.
  final bool compact;

  @override
  State<AppForm> createState() => _AppFormState();
}

class _AppFormState extends State<AppForm> {
  bool _busy = false;
  bool _edited = false;
  final List<TextEditingController> _listened = <TextEditingController>[];

  bool get _isDirty => widget.dirty || _edited;

  bool get _shouldGuard => widget.guardUnsaved && _isDirty;

  List<String> get _summary {
    final List<String> lines = <String>[...widget.errors];
    for (final Widget field in widget.fields) {
      final _FormField? editable = _formField(field);
      final String? error = editable?.errorText;
      if (editable != null && error != null && error.isNotEmpty) {
        lines.add(Copy.fieldError(editable.label, error));
      }
    }
    final Set<String> seen = <String>{};
    return <String>[
      for (final String line in lines)
        if (seen.add(line)) line,
    ];
  }

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(AppForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields) {
      _listen();
    }
  }

  @override
  void dispose() {
    _unlisten();
    super.dispose();
  }

  void _listen() {
    _unlisten();
    for (final Widget field in widget.fields) {
      final _FormField? editable = _formField(field);
      if (editable != null) {
        editable.controller.addListener(_onEdit);
        _listened.add(editable.controller);
      }
    }
  }

  void _unlisten() {
    for (final TextEditingController controller in _listened) {
      controller.removeListener(_onEdit);
    }
    _listened.clear();
  }

  void _onEdit() {
    if (!_edited && mounted) {
      setState(() => _edited = true);
    }
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _onPop(bool didPop, Object? result) async {
    if (didPop) {
      return;
    }
    final bool discard = await showAppConfirm(
      context,
      title: Copy.discardChangesTitle,
      message: Copy.unsavedChanges,
      confirmLabel: Copy.discard,
      destructive: true,
    );
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      context.dismissKeyboard();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_shouldGuard,
      onPopInvokedWithResult: _onPop,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.hasBoundedHeight) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: KeepFocusedVisible(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScroll,
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            Space.x4,
                            widget.compact ? Space.x2 : Space.x4,
                            Space.x4,
                            widget.compact ? Space.x1 : Space.x2,
                          ),
                          child: ContentConstraint(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _fieldSlate(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _submitBar(widget.fields.length, inset: true),
                ],
              );
            }
            return KeepFocusedVisible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ..._fieldSlate(),
                  const SizedBox(height: Space.x4),
                  _submitBar(widget.fields.length),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _fieldSlate() {
    final List<String> summary = _summary;
    final List<Widget> children = <Widget>[
      if (summary.isNotEmpty) ...<Widget>[
        _ErrorSummary(errors: summary),
        const SizedBox(height: Space.x4),
      ],
    ];
    for (int i = 0; i < widget.fields.length; i++) {
      if (i > 0) {
        children.add(SizedBox(height: widget.compact ? Space.x2 : Space.x3));
      }
      children.add(
        FocusTraversalOrder(
          order: NumericFocusOrder(i.toDouble()),
          child: widget.fields[i],
        ),
      );
    }
    return children;
  }

  Widget _submitBar(int fieldCount, {bool inset = false}) {
    final Widget action = FocusTraversalOrder(
      order: NumericFocusOrder(fieldCount.toDouble()),
      child: AppPrimaryAction(
        label: widget.submitLabel,
        busy: _busy,
        compact: widget.compact,
        onPressed: _submit,
      ),
    );
    if (!inset) {
      return action;
    }
    final BorderSide side = BorderSide(
      color: context.colors.outline,
      width: Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2,
    );
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: side)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Space.x4,
          widget.compact ? Space.x1 : Space.x3,
          Space.x4,
          widget.compact ? Space.x2 : Space.x4,
        ),
        child: ContentConstraint(child: action),
      ),
    );
  }
}

class _ErrorSummary extends StatelessWidget {
  const _ErrorSummary({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String heading = Copy.fixFields(errors.length);
    return Semantics(
      liveRegion: true,
      container: true,
      label: Copy.validationAnnouncement(heading, errors),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: colors.warning,
            width: Space.x0 / 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.x3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(AppIcons.error, color: colors.warning, size: Space.x6),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      heading,
                      style: AppText.bodyStrong.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: Space.x2),
                    for (final String line in errors)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.x1),
                        child: Text(
                          line,
                          style: AppText.body.copyWith(color: colors.onSurface),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _FormField = ({
  TextEditingController controller,
  String label,
  String? errorText,
});

_FormField? _formField(Widget field) {
  if (field is AppTextField) {
    return (
      controller: field.controller,
      label: field.label,
      errorText: field.errorText,
    );
  }
  if (field is AppEmailField) {
    return (
      controller: field.controller,
      label: field.label,
      errorText: field.errorText,
    );
  }
  if (field is AppPhoneField) {
    return (
      controller: field.controller,
      label: field.label,
      errorText: field.errorText,
    );
  }
  return null;
}
