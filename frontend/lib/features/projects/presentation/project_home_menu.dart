part of 'project_home_screen.dart';

List<AppOverflowAction> _projectHomeMenu(
  BuildContext context,
  WidgetRef ref,
  Project project,
) {
  final LocalizedCopy localCopy = Copy.of(context);

  final AppOverflowAction? open = projectOpenExternallyMenuItem(
    context,
    ref,
    project,
  );
  return <AppOverflowAction>[
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuCaptureReview,
      key: const ValueKey<String>('project-transcribe'),
      label: localCopy.transcribeTitle,
      icon: AppIcons.transcript,
      onTap: () =>
          unawaited(context.push(RoutePaths.projectTranscripts(project.id))),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuCaptureReview,
      key: const ValueKey<String>('project-start-meeting'),
      label: localCopy.meetingStartEntry,
      icon: AppIcons.recordAudio,
      onTap: () =>
          unawaited(context.push(RoutePaths.projectMeetingCreate(project.id))),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuCaptureReview,
      key: const ValueKey<String>('project-quality'),
      label: localCopy.qualitySummaryTitle,
      icon: AppIcons.verified,
      onTap: () =>
          unawaited(context.push(RoutePaths.projectQuality(project.id))),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuSetup,
      label: localCopy.navTemplates,
      icon: AppIcons.template,
      onTap: () => context.push(_templates(project.id)),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuSetup,
      key: const ValueKey<String>('project-datasets'),
      label: localCopy.navDatasets,
      icon: AppIcons.dataset,
      onTap: () =>
          unawaited(context.push(RoutePaths.projectDatasets(project.id))),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuSetup,
      label: localCopy.contextPinnedTitle,
      icon: AppIcons.pin,
      onTap: () => unawaited(
        showPinnedFieldsSheet(context: context, projectId: project.id),
      ),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuSetup,
      label: localCopy.contextHierarchyTitle,
      icon: AppIcons.context,
      onTap: () => unawaited(context.push(_context(project.id))),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuExchange,
      label: localCopy.projectExport,
      icon: AppIcons.export,
      onTap: () => context.push(RoutePaths.projectExports(project.id)),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuExchange,
      key: const ValueKey<String>('project-merge-package'),
      label: localCopy.mergePackage,
      icon: AppIcons.import,
      onTap: () => unawaited(
        startPackageImport(context, ref, intoProjectId: project.id),
      ),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuExchange,
      key: const ValueKey<String>('project-merge-history'),
      label: localCopy.mergeHistoryTitle,
      icon: AppIcons.history,
      onTap: () =>
          unawaited(context.push(RoutePaths.projectMergeHistory(project.id))),
    ),
    if (open != null)
      AppOverflowAction(
        key: open.key,
        icon: open.icon,
        label: open.label,
        onTap: open.onTap,
        sectionLabel: localCopy.projectMenuExchange,
      ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuManage,
      label: localCopy.projectEditTitle,
      icon: AppIcons.info,
      onTap: () =>
          unawaited(context.push(RoutePaths.projectDetails(project.id))),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuManage,
      label: localCopy.projectSettingsTitle,
      icon: AppIcons.settings,
      onTap: () => context.go(_settings(project.id)),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuManage,
      label: localCopy.projectsDuplicate,
      icon: AppIcons.duplicate,
      onTap: () => ProjectDuplicateAction.open(
        context,
        sourceId: project.id,
        sourceName: project.name,
      ),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuManage,
      label: project.status == ProjectStatus.archived
          ? localCopy.projectUnarchive
          : localCopy.projectArchive,
      icon: project.status == ProjectStatus.archived
          ? AppIcons.unarchive
          : AppIcons.archive,
      onTap: () => unawaited(_archiveThenList(context, ref, project)),
    ),
    AppOverflowAction(
      sectionLabel: localCopy.projectMenuManage,
      label: localCopy.projectDeleteMenu,
      icon: AppIcons.delete,
      onTap: () => unawaited(_deleteThenList(context, ref, project)),
    ),
  ];
}

Future<void> _archiveThenList(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  await ProjectArchiveAction.apply(ref, project);
  if (context.mounted) {
    context.go(RoutePaths.projects);
  }
}

Future<void> _deleteThenList(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  await ProjectDeleteAction.confirm(context, ref, project);
  if (!context.mounted) {
    return;
  }
  if (ref.read(currentProjectProvider) != project.id) {
    context.go(RoutePaths.projects);
  }
}
