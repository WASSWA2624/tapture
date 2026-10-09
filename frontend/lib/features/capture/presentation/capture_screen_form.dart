part of 'capture_screen.dart';

extension _CaptureForm on _CaptureScreenState {
  Future<void> _manualForm(String key, String projectId) => showAppSheet<void>(
    Navigator.of(context, rootNavigator: true).context,
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
        final String deviceId = formRef.watch(captureDeviceIdProvider) ?? '';
        final String operator =
            formRef.watch(currentOperatorProvider)?.name.trim() ?? '';
        final Map<String, Object?> automatic = AutoFields.forTemplate(
          fields: fields,
          nowUtc: formRef.read(captureClockProvider).nowUtc(),
          operatorName: operator.isEmpty ? deviceId : operator,
          deviceId: deviceId,
          sequence: null,
          context: session.contextSnapshot,
          location: session.location,
          autoFillDates: formRef.watch(captureDateFillProvider),
          localAddress: formRef
              .read(captureDeviceSourceProvider(key))
              .snapshot(session),
        );
        return CaptureManualForm(
          key: ValueKey<String>(
            'manual-${session.id}-${session.templateId}-${session.templateVersion}',
          ),
          fields: fields,
          values: <String, Object?>{
            ...session.contextSnapshot,
            ...session.values,
          },
          automaticValues: automatic,
          valueSources: <String, String>{
            for (final String fieldKey in session.contextSnapshot.keys)
              fieldKey: 'CONTEXT',
            for (final String fieldKey in session.values.keys)
              fieldKey: session.valueSources[fieldKey] ?? 'TYPED',
          },
          onChanged: (String fieldKey, Object? value) => _manualValue(
            context,
            controller,
            session,
            fields,
            fieldKey,
            value,
          ),
          onLookup: (FieldDef field) =>
              unawaited(_lookup(field, sessionKey: key)),
          onScan: (FieldDef field) => unawaited(_scan(field, sessionKey: key)),
          linkedFields: session.lookupRows.keys.toSet(),
        );
      },
    ),
  );

  Future<Result<void>> _manualValue(
    BuildContext formContext,
    CaptureController controller,
    CaptureSession session,
    List<FieldDef> fields,
    String fieldKey,
    Object? value,
  ) async {
    final FieldDef? field = fields
        .where((FieldDef field) => field.fieldKey == fieldKey)
        .firstOrNull;
    final Object? stored = value is DateTime && field != null
        ? storedTextOf(field.type, value)
        : value;
    final Result<void> written = await controller.setValue(
      fieldKey,
      stored,
      owner: (
        sessionId: session.id,
        templateId: session.templateId,
        templateVersion: session.templateVersion,
      ),
    );
    if (!formContext.mounted) return written;
    if (written case FailureResult<void>(:final Failure failure)) {
      showAppSnack(
        formContext,
        failure.message,
        localizedMessage: failure.explanation,
        tone: SnackTone.error,
      );
    }
    return written;
  }
}
