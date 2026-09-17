import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/naming/domain_names.dart';

/// Near-synonyms [frontend/test/architecture/naming_test.dart] rejects as
/// type names, plus the banned whole words the naming checker flags.
const Map<String, String> _typeSynonyms = <String, String>{
  'ProjectModel': DomainNames.project,
  'ProjectData': DomainNames.project,
  'ProjectInfo': DomainNames.project,
  'ProjectItem': DomainNames.project,
  'TemplateModel': DomainNames.templateDef,
  'TemplateData': DomainNames.templateDef,
  'TemplateInfo': DomainNames.templateDef,
  'TemplateItem': DomainNames.templateDef,
  'FieldModel': DomainNames.fieldDef,
  'FieldData': DomainNames.fieldDef,
  'FieldInfo': DomainNames.fieldDef,
  'FieldItem': DomainNames.fieldDef,
  'RecordModel': DomainNames.recordEntry,
  'RecordData': DomainNames.recordEntry,
  'RecordInfo': DomainNames.recordEntry,
  'RecordItem': DomainNames.recordEntry,
  'FieldValueModel': DomainNames.fieldValue,
  'CaptureSessionModel': DomainNames.captureSession,
  'CaptureData': DomainNames.captureSession,
  'PhotoItem': DomainNames.photoAsset,
  'PhotoModel': DomainNames.photoAsset,
  'PhotoData': DomainNames.photoAsset,
  'PhotoInfo': DomainNames.photoAsset,
  'ContextModel': DomainNames.contextState,
  'ContextData': DomainNames.contextState,
  'ContextInfo': DomainNames.contextState,
  'ReferenceData': DomainNames.referenceDataset,
  'DatasetModel': DomainNames.referenceDataset,
  'ProcessingJobModel': DomainNames.processingJob,
  'JobModel': DomainNames.processingJob,
  'BundleModel': DomainNames.bundle,
  'BundleData': DomainNames.bundle,
  'MergeModel': DomainNames.mergeSession,
  'MergeSessionModel': DomainNames.mergeSession,
};

const List<String> _bannedWords = <String>[
  'manager',
  'helper',
  'util',
  'data',
  'info',
  'item',
];

void main() {
  test('recordsCount reads correctly at zero, one and many', () {
    expect(Copy.recordsCount(0), 'No records');
    expect(Copy.recordsCount(1), '1 record');
    expect(Copy.recordsCount(2), '2 records');
    expect(Copy.notDetected, 'Not detected');
    expect(Copy.notDetected, isNotEmpty);
  });

  test('no Copy value uses a synonym the naming checker rejects', () {
    for (final String value in _values) {
      expect(value, isNotEmpty);
      for (final MapEntry<String, String> synonym in _typeSynonyms.entries) {
        expect(
          value.contains(synonym.key),
          isFalse,
          reason:
              '"$value" uses ${synonym.key}; say ${synonym.value} '
              '(FE-CONS-07)',
        );
      }
      for (final String banned in _bannedWords) {
        expect(
          RegExp('\\b$banned\\b', caseSensitive: false).hasMatch(value),
          isFalse,
          reason: '"$value" uses "$banned", which the naming checker rejects',
        );
      }
    }
  });
}

/// Every catalogue string [Copy] currently publishes.
List<String> get _values {
  return <String>[
    Copy.notDetected,
    Copy.recordsCount(0),
    Copy.recordsCount(1),
    Copy.recordsCount(2),
    Copy.clearField('Name'),
    Copy.autoFilled,
    Copy.outOfRange,
    Copy.selectAll,
    Copy.clear,
    Copy.dismissChip('Water'),
    Copy.dismiss,
    Copy.cancel,
    Copy.ok,
    Copy.discardChangesTitle,
    Copy.unsavedChanges,
    Copy.discard,
    Copy.fixFields(1),
    Copy.fixFields(2),
    Copy.fieldError('Name', 'Required'),
    Copy.validationAnnouncement('Fix these fields', <String>['Name: Required']),
    Copy.missingPhoto,
    Copy.missingPhotoNamed('Front'),
    Copy.photo,
    Copy.photoThumbLabel(
      type: Copy.photoFront,
      missing: false,
      captioned: true,
      selected: true,
    ),
    Copy.photoFront,
    Copy.photoBack,
    Copy.photoSerial,
    Copy.photoRatingPlate,
    Copy.photoRatingPlateBadge,
    Copy.photoDamage,
    Copy.photoPanel,
    Copy.photoLocation,
    Copy.photoAttendance,
    Copy.photoAttendanceBadge,
    Copy.photoDocument,
    Copy.photoDocumentBadge,
    Copy.photoOther,
    Copy.stepDone,
    Copy.stepRunning,
    Copy.stepWaiting,
    Copy.failed,
    Copy.progressAnnouncement(label: 'Read text', state: Copy.stepWaiting),
    Copy.statusDraft,
    Copy.statusCaptured,
    Copy.statusQueued,
    Copy.statusProcessing,
    Copy.statusExtracted,
    Copy.statusNeedsReview,
    Copy.statusApproved,
    Copy.statusArchived,
    Copy.statusDeleted,
    Copy.emptyHeadline,
    Copy.emptyMessage,
    Copy.loading,
    Copy.busy,
    Copy.busyAction('Save'),
    Copy.tryAgain,
    Copy.save,
    Copy.undo,
    Copy.galleryTitle,
    Copy.galleryTheme,
    Copy.galleryWidth,
    Copy.galleryTextScale,
    Copy.galleryTokens,
    Copy.galleryLayout,
    Copy.galleryButtons,
    Copy.galleryFields,
    Copy.galleryContainers,
    Copy.galleryStates,
    Copy.galleryFeedback,
    Copy.galleryLight,
    Copy.galleryDark,
    Copy.galleryOutdoor,
    Copy.galleryCompact,
    Copy.galleryMedium,
    Copy.galleryExpanded,
    Copy.galleryScale100,
    Copy.galleryScale200,
    Copy.navProjects,
    Copy.navCapture,
    Copy.navRecords,
    Copy.navMore,
  ];
}
