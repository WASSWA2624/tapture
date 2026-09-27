import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/record_filter.dart';
import 'package:tapture/features/records/domain/record_flag.dart';

void main() {
  final RecordFilter full = RecordFilter(
    statuses: const <RecordStatus>{
      RecordStatus.needsReview,
      RecordStatus.approved,
    },
    templateIds: const <String>{'template-2', 'template-1'},
    context: const <String, Set<String>>{
      'site': <String>{'North', 'East'},
      'room': <String>{'Theatre'},
    },
    capturedFrom: DateTime.utc(2026, 9, 1),
    capturedTo: DateTime.utc(2026, 9, 30, 23, 59, 59),
    operators: const <String>{'device-1'},
    conditions: const <String>{'good', 'poor'},
    flags: const <RecordFlag>{RecordFlag.hasPhotos, RecordFlag.hasConflict},
    search: 'autoclave',
  );

  group('none', () {
    test('narrows nothing and counts no chips', () {
      expect(RecordFilter.none.isEmpty, isTrue);
      expect(RecordFilter.none.activeCount, 0);
      expect(RecordFilter.none.hasCapturedRange, isFalse);
      expect(const RecordFilter(), RecordFilter.none);
    });

    test('writes an empty JSON object', () {
      expect(RecordFilter.none.toJson(), isEmpty);
    });
  });

  group('listedStatuses', () {
    test('an empty status set lists everything but archived and deleted', () {
      expect(RecordFilter.none.listedStatuses, <RecordStatus>{
        RecordStatus.draft,
        RecordStatus.captured,
        RecordStatus.queued,
        RecordStatus.processing,
        RecordStatus.extracted,
        RecordStatus.needsReview,
        RecordStatus.approved,
        RecordStatus.failed,
      });
    });

    test('a chosen archived status is listed', () {
      expect(
        RecordFilter.forStatus(RecordStatus.archived).listedStatuses,
        <RecordStatus>{RecordStatus.archived},
      );
    });

    test('deleted is never listed, even when chosen', () {
      final RecordFilter filter = const RecordFilter().copyWith(
        statuses: <RecordStatus>{RecordStatus.deleted, RecordStatus.approved},
      );
      expect(filter.listedStatuses, <RecordStatus>{RecordStatus.approved});
      expect(
        RecordFilter.forStatus(RecordStatus.deleted).listedStatuses,
        isEmpty,
      );
    });
  });

  group('activeCount and isEmpty', () {
    test('count one chip per value and one for the date range', () {
      // 2 statuses, 2 templates, 3 context values, 1 range, 1 operator,
      // 2 conditions, 2 flags.
      expect(full.activeCount, 13);
      expect(full.isEmpty, isFalse);
    });

    test('search alone is not a chip but does make the filter non-empty', () {
      const RecordFilter search = RecordFilter(search: 'pump');
      expect(search.activeCount, 0);
      expect(search.isEmpty, isFalse);
      expect(const RecordFilter(search: '   ').isEmpty, isTrue);
    });

    test('one bound is enough to count the range', () {
      final RecordFilter from = RecordFilter(capturedFrom: DateTime.utc(2026));
      expect(from.hasCapturedRange, isTrue);
      expect(from.activeCount, 1);
    });
  });

  group('JSON', () {
    test('a full filter survives a round-trip through encoded text', () {
      final Object? decoded = jsonDecode(jsonEncode(full.toJson()));
      expect(RecordFilter.fromJson(decoded! as Map<String, Object?>), full);
    });

    test('lists are written in a stable order', () {
      final Map<String, Object?> json = full.toJson();
      expect(json['statuses'], <String>['needsReview', 'approved']);
      expect(json['templateIds'], <String>['template-1', 'template-2']);
      expect(json['context'], <String, Object?>{
        'room': <String>['Theatre'],
        'site': <String>['East', 'North'],
      });
      // Statuses and flags follow their enum order, the rest sort by text.
      expect(json['flags'], <String>['hasPhotos', 'hasConflict']);
      expect(json['capturedFrom'], '2026-09-01T00:00:00.000Z');
    });

    test('unknown keys, statuses, flags and wrong types are dropped', () {
      final RecordFilter read = RecordFilter.fromJson(<String, Object?>{
        'statuses': <Object?>['NEEDS_REVIEW', 'exported', 3, null],
        'templateIds': 'template-1',
        'context': <String, Object?>{
          'site': <Object?>['North', ''],
          'room': 'Theatre',
          'floor': <Object?>[],
        },
        'capturedFrom': 'not a date',
        'capturedTo': 42,
        'operators': <Object?>['device-1', 7],
        'conditions': null,
        'flags': <Object?>['has_photos', 'notInRegister'],
        'search': 12,
        'sortOrder': 'ignored',
      });
      expect(read.statuses, <RecordStatus>{RecordStatus.needsReview});
      expect(read.templateIds, isEmpty);
      expect(read.context, <String, Set<String>>{
        'site': <String>{'North'},
      });
      expect(read.capturedFrom, isNull);
      expect(read.capturedTo, isNull);
      expect(read.operators, <String>{'device-1'});
      expect(read.conditions, isEmpty);
      expect(read.flags, <RecordFlag>{RecordFlag.hasPhotos});
      expect(read.search, isEmpty);
    });

    test('an empty object reads as none', () {
      expect(
        RecordFilter.fromJson(const <String, Object?>{}),
        RecordFilter.none,
      );
    });

    test('dates read back as UTC instants and compare as instants', () {
      final DateTime local = DateTime(2026, 9, 17, 10);
      final RecordFilter filter = RecordFilter(capturedFrom: local);
      final RecordFilter read = RecordFilter.fromJson(filter.toJson());
      expect(read.capturedFrom!.isUtc, isTrue);
      expect(read, filter);
      expect(read.hashCode, filter.hashCode);
    });
  });

  group('removing one filter', () {
    test('each value comes off on its own', () {
      expect(full.withoutStatus(RecordStatus.approved).statuses, <RecordStatus>{
        RecordStatus.needsReview,
      });
      expect(full.withoutTemplate('template-1').templateIds, <String>{
        'template-2',
      });
      expect(full.withoutOperator('device-1').operators, isEmpty);
      expect(full.withoutCondition('good').conditions, <String>{'poor'});
      expect(full.withoutFlag(RecordFlag.hasPhotos).flags, <RecordFlag>{
        RecordFlag.hasConflict,
      });
      expect(full.withoutStatus(RecordStatus.approved).activeCount, 12);
    });

    test('a context value comes off, and an emptied level goes', () {
      final RecordFilter oneSite = full.withoutContextValue('site', 'East');
      expect(oneSite.context['site'], <String>{'North'});
      expect(oneSite.context['room'], <String>{'Theatre'});
      final RecordFilter noRoom = full.withoutContextValue('room', 'Theatre');
      expect(noRoom.context.containsKey('room'), isFalse);
      expect(noRoom.context['site'], <String>{'North', 'East'});
    });

    test('the date range comes off as one chip', () {
      final RecordFilter undated = full.withoutCapturedRange();
      expect(undated.capturedFrom, isNull);
      expect(undated.capturedTo, isNull);
      expect(undated.activeCount, 12);
    });

    test('removing a value that is not there changes nothing', () {
      expect(full.withoutTemplate('template-9'), full);
    });

    test('one tap clears every chip and keeps the search', () {
      final RecordFilter cleared = full.withoutCriteria();
      expect(cleared.activeCount, 0);
      expect(cleared.search, 'autoclave');
      expect(cleared, const RecordFilter(search: 'autoclave'));
    });

    test('withoutSearch keeps the chips for persisting', () {
      final RecordFilter stored = full.withoutSearch();
      expect(stored.search, isEmpty);
      expect(stored.activeCount, full.activeCount);
      expect(stored.toJson().containsKey('search'), isFalse);
    });
  });

  test(
    'copyWith replaces only what it is given and clears bounds on request',
    () {
      expect(full.copyWith(), full);
      expect(full.copyWith(search: 'pump').statuses, full.statuses);
      final RecordFilter open = full.copyWith(clearCapturedTo: true);
      expect(open.capturedFrom, full.capturedFrom);
      expect(open.capturedTo, isNull);
      expect(full.copyWith(clearCapturedFrom: true).capturedFrom, isNull);
    },
  );

  test('forStatus lists exactly one status', () {
    expect(
      RecordFilter.forStatus(RecordStatus.needsReview).statuses,
      <RecordStatus>{RecordStatus.needsReview},
    );
  });

  test(
    'filters with the same values are equal whatever the insertion order',
    () {
      final RecordFilter reordered = RecordFilter(
        statuses: const <RecordStatus>{
          RecordStatus.approved,
          RecordStatus.needsReview,
        },
        templateIds: const <String>{'template-1', 'template-2'},
        context: const <String, Set<String>>{
          'room': <String>{'Theatre'},
          'site': <String>{'East', 'North'},
        },
        capturedFrom: DateTime.utc(2026, 9, 1),
        capturedTo: DateTime.utc(2026, 9, 30, 23, 59, 59),
        operators: const <String>{'device-1'},
        conditions: const <String>{'poor', 'good'},
        flags: const <RecordFlag>{RecordFlag.hasConflict, RecordFlag.hasPhotos},
        search: 'autoclave',
      );
      expect(reordered, full);
      expect(reordered.hashCode, full.hashCode);
      expect(full.copyWith(search: 'other'), isNot(full));
    },
  );

  test('the condition dimension matches both shipped condition keys', () {
    expect(RecordFilter.conditionFieldKeys, <String>{
      'condition',
      'condition_grade',
    });
  });

  test('toString counts chips and never prints a value', () {
    expect(full.toString(), 'RecordFilter(13 active)');
    expect(full.toString(), isNot(contains('autoclave')));
  });
}
