import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'template_list_screen.dart' show templateListProvider;
import 'template_locations.dart';

/// Per-template signals that decide how a photo is matched to a template.
class DetectionProfileScreen extends ConsumerWidget {
  /// Creates the editor for [templateId].
  const DetectionProfileScreen({super.key, required this.templateId});

  /// Template whose detection profile this screen edits.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TemplateDef?> value = ref
        .watch(templateListProvider)
        .whenData(_pick);
    final _ProfileView view = ref.watch(_detectionProfileProvider(templateId));
    return AppPage(
      key: const ValueKey<String>('route-detection-profile'),
      title: Copy.detectionProfileTitle,
      scrollable: false,
      footer: value.asData?.value == null
          ? null
          : AppPrimaryAction(
              label: Copy.save,
              onPressed: () => unawaited(_commit(context, ref)),
            ),
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) => row == null,
        empty: () => const AppEmptyState(
          icon: AppIcons.detection,
          headline: Copy.detectionProfileEmptyHeadline,
          message: Copy.detectionProfileEmptyMessage,
        ),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (TemplateDef? row) => _form(ref, row!, view),
      ),
    );
  }

  Widget _form(WidgetRef ref, TemplateDef template, _ProfileView view) {
    final _DetectionProfile controller = ref.read(
      _detectionProfileProvider(templateId).notifier,
    );
    final List<FieldDef> patterned = _patterned(template.fields);
    final List<String> datasets = _datasetsOf(template.fields);
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x4),
      children: <Widget>[
        const AppBanner(
          message: Copy.detectionProfileExplain,
          icon: AppIcons.info,
          tone: SnackTone.info,
        ),
        if (view.saveError != null)
          AppBanner(
            message: view.saveError!,
            icon: AppIcons.error,
            tone: SnackTone.error,
          ),
        _TokenField(
          key: const ValueKey<String>('detection-classes'),
          label: Copy.detectionProfileClasses,
          value: view.objectClasses.join(', '),
          onChanged: controller.setClasses,
        ),
        _TokenField(
          key: const ValueKey<String>('detection-keywords'),
          label: Copy.detectionProfileKeywords,
          value: view.keywords.join(', '),
          onChanged: controller.setKeywords,
        ),
        const AppSectionHeader(
          title: Copy.detectionProfilePatterns,
          dense: true,
        ),
        if (patterned.isEmpty)
          const AppBanner(
            message: Copy.detectionProfileNoPatterns,
            icon: AppIcons.info,
            tone: SnackTone.info,
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, 0),
            child: AppCheckboxGroup<String>(
              label: Copy.detectionProfilePatterns,
              showLabel: false,
              value: view.identifierFields,
              options: <Choice<String>>[
                for (final FieldDef field in patterned)
                  Choice<String>(field.fieldKey, field.label),
              ],
              onChanged: controller.setIdentifierFields,
            ),
          ),
        const AppSectionHeader(
          title: Copy.detectionProfileDatasets,
          dense: true,
        ),
        if (datasets.isEmpty)
          const AppBanner(
            message: Copy.detectionProfileNoDatasets,
            icon: AppIcons.info,
            tone: SnackTone.info,
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, 0),
            child: AppCheckboxGroup<String>(
              label: Copy.detectionProfileDatasets,
              showLabel: false,
              value: view.datasets,
              options: <Choice<String>>[
                for (final String dataset in datasets)
                  Choice<String>(dataset, dataset),
              ],
              onChanged: controller.setDatasets,
            ),
          ),
        _TokenField(
          key: const ValueKey<String>('detection-negative'),
          label: Copy.detectionProfileNegative,
          value: view.negativeKeywords.join(', '),
          onChanged: controller.setNegative,
        ),
      ],
    );
  }

  TemplateDef? _pick(List<TemplateDef> rows) {
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return row;
      }
    }
    return null;
  }

  Future<void> _commit(BuildContext context, WidgetRef ref) async {
    final bool saved = await ref
        .read(_detectionProfileProvider(templateId).notifier)
        .commit();
    if (saved && context.mounted) {
      GoRouter.maybeOf(
        context,
      )?.go(TemplateLocations.detail(context, templateId));
    }
  }
}

/// Whether [text] matches [template]'s detection profile.
///
/// A negative keyword excludes a profile the positives would have matched.
/// An empty profile matches nothing and still lets capture continue.
bool detectionProfileMatches(TemplateDef template, String text) {
  final _Profile profile = _profileOf(template);
  final String haystack = text.toLowerCase();
  if (_containsAny(profile.negativeKeywords, haystack)) {
    return false;
  }
  if (_containsAny(profile.objectClasses, haystack) ||
      _containsAny(profile.keywords, haystack) ||
      _containsAny(profile.datasets.toList(), haystack)) {
    return true;
  }
  for (final String pattern in _patternsOf(
    template,
    profile.identifierFields,
  )) {
    if (_patternHits(pattern, text)) {
      return true;
    }
  }
  return false;
}

typedef _ProfileView = ({
  List<String> objectClasses,
  List<String> keywords,
  Set<String> identifierFields,
  Set<String> datasets,
  List<String> negativeKeywords,
  String? saveError,
  bool dirty,
});

typedef _Profile = ({
  List<String> objectClasses,
  List<String> keywords,
  Set<String> identifierFields,
  Set<String> datasets,
  List<String> negativeKeywords,
});

final class _DetectionProfile extends Notifier<_ProfileView> {
  _DetectionProfile(this.templateId);

  final String templateId;

  _ProfileView? _held;

  @override
  _ProfileView build() {
    ref.onDispose(() => _held = null);
    final _ProfileView? held = _held;
    if (held != null && held.dirty) {
      return held;
    }
    final TemplateDef? template = _source();
    if (template == null) {
      return (
        objectClasses: const <String>[],
        keywords: const <String>[],
        identifierFields: const <String>{},
        datasets: const <String>{},
        negativeKeywords: const <String>[],
        saveError: null,
        dirty: false,
      );
    }
    final _Profile profile = _profileOf(template);
    return (
      objectClasses: profile.objectClasses,
      keywords: profile.keywords,
      identifierFields: profile.identifierFields,
      datasets: profile.datasets,
      negativeKeywords: profile.negativeKeywords,
      saveError: null,
      dirty: false,
    );
  }

  void setClasses(String raw) => _set(objectClasses: _split(raw));

  void setKeywords(String raw) => _set(keywords: _split(raw));

  void setNegative(String raw) => _set(negativeKeywords: _split(raw));

  void setIdentifierFields(Set<String> next) => _set(identifierFields: next);

  void setDatasets(Set<String> next) => _set(datasets: next);

  Future<bool> commit() async {
    final TemplateDef? source = _source();
    if (source == null) {
      const StorageFailure missing = StorageFailure(
        message: Copy.detectionProfileMissing,
        recoveryAction: Copy.detectionProfileMissingRecovery,
      );
      state = (
        objectClasses: state.objectClasses,
        keywords: state.keywords,
        identifierFields: state.identifierFields,
        datasets: state.datasets,
        negativeKeywords: state.negativeKeywords,
        saveError: missing.message,
        dirty: state.dirty,
      );
      _held = state;
      return false;
    }
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(source.copyWith(detection: _write(source)));
    switch (result) {
      case Success<TemplateDef>():
        _held = null;
        state = (
          objectClasses: state.objectClasses,
          keywords: state.keywords,
          identifierFields: state.identifierFields,
          datasets: state.datasets,
          negativeKeywords: state.negativeKeywords,
          saveError: null,
          dirty: false,
        );
        return true;
      case FailureResult<TemplateDef>(:final Failure failure):
        state = (
          objectClasses: state.objectClasses,
          keywords: state.keywords,
          identifierFields: state.identifierFields,
          datasets: state.datasets,
          negativeKeywords: state.negativeKeywords,
          saveError: failure.message,
          dirty: true,
        );
        _held = state;
        return false;
    }
  }

  void _set({
    List<String>? objectClasses,
    List<String>? keywords,
    Set<String>? identifierFields,
    Set<String>? datasets,
    List<String>? negativeKeywords,
  }) {
    state = (
      objectClasses: objectClasses ?? state.objectClasses,
      keywords: keywords ?? state.keywords,
      identifierFields: identifierFields ?? state.identifierFields,
      datasets: datasets ?? state.datasets,
      negativeKeywords: negativeKeywords ?? state.negativeKeywords,
      saveError: null,
      dirty: true,
    );
    _held = state;
  }

  Map<String, Object?> _write(TemplateDef template) {
    final Map<String, Object?> next = Map<String, Object?>.of(
      template.detection,
    );
    next[_classesKey] = state.objectClasses;
    next[_keywordsKey] = state.keywords;
    next[_identifierFieldsKey] = state.identifierFields.toList();
    next[_patternsKey] = _patternsOf(template, state.identifierFields);
    next[_datasetsKey] = state.datasets.toList();
    next[_negativeKey] = state.negativeKeywords;
    return next;
  }

  TemplateDef? _source() {
    final List<TemplateDef> rows =
        ref.read(templateListProvider).asData?.value ?? const <TemplateDef>[];
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return row;
      }
    }
    return null;
  }
}

final _detectionProfileProvider = NotifierProvider.autoDispose
    .family<_DetectionProfile, _ProfileView, String>(
      _DetectionProfile.new,
      retry: (int _, Object _) => null,
    );

class _TokenField extends StatefulWidget {
  const _TokenField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TokenField> createState() => _TokenFieldState();
}

class _TokenFieldState extends State<_TokenField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(_TokenField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(text: widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, 0),
      child: AppTextField(
        label: widget.label,
        controller: _controller,
        hint: Copy.detectionProfileHint,
        onChanged: widget.onChanged,
      ),
    );
  }
}

_Profile _profileOf(TemplateDef template) {
  if (!_hasProfile(template.detection) && template.source == _shippedSource) {
    return (
      objectClasses: _filled(<String>[template.kind]),
      keywords: <String>[
        for (final FieldDef field in template.fields)
          if (template.identityFieldKeys.contains(field.fieldKey)) field.label,
      ],
      identifierFields: <String>{
        for (final FieldDef field in _patterned(template.fields))
          field.fieldKey,
      },
      datasets: _datasetsOf(template.fields).toSet(),
      negativeKeywords: const <String>[],
    );
  }
  return (
    objectClasses: _stringsOf(template.detection[_classesKey]),
    keywords: _stringsOf(template.detection[_keywordsKey]),
    identifierFields: _identifierFieldsOf(template),
    datasets: _stringsOf(template.detection[_datasetsKey]).toSet(),
    negativeKeywords: _stringsOf(template.detection[_negativeKey]),
  );
}

Set<String> _identifierFieldsOf(TemplateDef template) {
  final List<String> stored = _stringsOf(
    template.detection[_identifierFieldsKey],
  );
  if (stored.isNotEmpty) {
    return stored.toSet();
  }
  final List<String> patterns = _stringsOf(template.detection[_patternsKey]);
  if (patterns.isEmpty) {
    return <String>{};
  }
  return <String>{
    for (final FieldDef field in template.fields)
      if (patterns.contains(_patternOf(field))) field.fieldKey,
  };
}

List<String> _patternsOf(TemplateDef template, Set<String> fieldKeys) {
  if (fieldKeys.isNotEmpty) {
    return <String>[
      for (final FieldDef field in template.fields)
        if (fieldKeys.contains(field.fieldKey))
          if (_patternOf(field) case final String pattern) pattern,
    ];
  }
  return _stringsOf(template.detection[_patternsKey]);
}

List<FieldDef> _patterned(List<FieldDef> fields) {
  return <FieldDef>[
    for (final FieldDef field in fields)
      if (_patternOf(field) != null) field,
  ];
}

List<String> _datasetsOf(List<FieldDef> fields) {
  final List<String> found = <String>[];
  for (final FieldDef field in fields) {
    final String? dataset = _datasetOf(field);
    if (dataset != null && !found.contains(dataset)) {
      found.add(dataset);
    }
  }
  return found;
}

String? _patternOf(FieldDef field) {
  final Object? raw = field.validation[_patternKey];
  if (raw is String && raw.trim().isNotEmpty) {
    return raw.trim();
  }
  return null;
}

String? _datasetOf(FieldDef field) {
  final Object? raw = field.lookup[_datasetIdKey];
  if (raw is String && raw.trim().isNotEmpty) {
    return raw.trim();
  }
  return null;
}

bool _hasProfile(Map<String, Object?> detection) {
  for (final String key in _profileKeys) {
    if (detection.containsKey(key)) {
      return true;
    }
  }
  return false;
}

bool _containsAny(List<String> needles, String haystack) {
  for (final String needle in needles) {
    if (needle.isNotEmpty && haystack.contains(needle.toLowerCase())) {
      return true;
    }
  }
  return false;
}

bool _patternHits(String pattern, String text) {
  try {
    return RegExp(pattern).hasMatch(text);
  } on FormatException {
    return false;
  }
}

List<String> _stringsOf(Object? raw) {
  if (raw is List) {
    return _filled(<String>[
      for (final Object? value in raw)
        if (value is String) value,
    ]);
  }
  if (raw is String) {
    return _split(raw);
  }
  return const <String>[];
}

List<String> _split(String raw) {
  return _filled(raw.split(_tokenSplit));
}

List<String> _filled(Iterable<String> values) {
  return <String>[
    for (final String value in values)
      if (value.trim().isNotEmpty) value.trim(),
  ];
}

final RegExp _tokenSplit = RegExp(r'[,;\n]');
const String _shippedSource = 'shipped';
const String _classesKey = 'object_classes';
const String _keywordsKey = 'keywords';
const String _identifierFieldsKey = 'identifier_fields';
const String _patternsKey = 'identifier_patterns';
const String _datasetsKey = 'reference_datasets';
const String _negativeKey = 'negative_keywords';
const String _patternKey = 'pattern';
const String _datasetIdKey = 'datasetId';
const List<String> _profileKeys = <String>[
  _classesKey,
  _keywordsKey,
  _identifierFieldsKey,
  _patternsKey,
  _datasetsKey,
  _negativeKey,
];
