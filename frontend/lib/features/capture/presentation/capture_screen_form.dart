part of 'capture_screen.dart';

extension _CaptureForm on _CaptureScreenState {
  Future<void> _manualForm(String key, String projectId) => showAppSheet<void>(
    context,
    title: Copy.of(context).captureManualForm,
    builder: (BuildContext sheetContext) => Consumer(
      builder: (BuildContext context, WidgetRef formRef, Widget? _) {
        final CaptureSession session = formRef.watch(
          captureControllerProvider(key),
        );
        final List<TemplateDef> templates =
            formRef.watch(captureProjectTemplatesProvider(projectId)).value ??
            const <TemplateDef>[];
        final TemplateDef? template = templates
            .where((TemplateDef template) => template.id == session.templateId)
            .firstOrNull;
        final TemplateDef? shape = template == null
            ? null
            : session.templateVersion == null
            ? template
            : TemplateVersioning.shapeFor(template, session.templateVersion!);
        final List<FieldDef> fields = <FieldDef>[
          for (final FieldDef field in shape?.fields ?? const <FieldDef>[])
            if (!field.hidden) field,
        ];
        final CaptureController controller = formRef.read(
          captureControllerProvider(key).notifier,
        );
        return SingleChildScrollView(
          key: const ValueKey<String>('capture-manual-form-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(Space.x3),
          child: InlineFieldsSection(
            key: ValueKey<String>('manual-${session.id}-${session.templateId}'),
            fields: fields,
            values: <String, Object?>{
              ...session.contextSnapshot,
              ...session.values,
            },
            onChanged: (String fieldKey, Object? value) =>
                unawaited(_manualValue(context, controller, fieldKey, value)),
            onLookup: (FieldDef field) =>
                unawaited(_lookup(field, sessionKey: key)),
            onScan: (FieldDef field) =>
                unawaited(_scan(field, sessionKey: key)),
            linkedFields: session.lookupRows.keys.toSet(),
          ),
        );
      },
    ),
  );

  Future<void> _manualValue(
    BuildContext formContext,
    CaptureController controller,
    String fieldKey,
    Object? value,
  ) async {
    final Result<void> written = await controller.setValue(fieldKey, value);
    if (!formContext.mounted) return;
    if (written case FailureResult<void>(:final Failure failure)) {
      showAppSnack(
        formContext,
        failure.message,
        localizedMessage: failure.explanation,
        tone: SnackTone.error,
      );
    }
  }
}
