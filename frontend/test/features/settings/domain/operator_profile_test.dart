import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/features/settings/domain/operator_profile.dart';

void main() {
  test('initialsFrom takes the first letter of each word up to three', () {
    expect(OperatorProfile.initialsFrom('Ada'), 'A');
    expect(OperatorProfile.initialsFrom('Ada Lovelace'), 'AL');
    expect(OperatorProfile.initialsFrom('Jean Luc Picard'), 'JLP');
    expect(OperatorProfile.initialsFrom('Anne Marie Claire Smith'), 'AMC');
    expect(OperatorProfile.initialsFrom('  '), '');
  });

  test('name and initials validate against the published limits', () {
    const OperatorProfile empty = OperatorProfile(name: '  ', initials: '');
    expect(empty.hasName, isFalse);
    expect(empty.hasInitials, isFalse);

    const OperatorProfile valid = OperatorProfile(name: 'Ada', initials: 'AL');
    expect(valid.hasName, isTrue);
    expect(valid.hasInitials, isTrue);

    const OperatorProfile tooLong = OperatorProfile(
      name: 'Ada',
      initials: 'ABCD',
    );
    expect(tooLong.hasInitials, isFalse);
  });

  test('fromStored migrates a leftover contact with @ to email', () {
    final OperatorProfile profile = OperatorProfile.fromStored(
      name: 'Ada',
      preferences:
          '{"${AppConstants.operator.initialsKey}":"AL",'
          '"${AppConstants.operator.contactKey}":"ada@x"}',
      accountId: null,
    );
    expect(profile.name, 'Ada');
    expect(profile.initials, 'AL');
    expect(profile.email, 'ada@x');
    expect(profile.phone, isNull);
    expect(profile.contact, 'ada@x');
    expect(profile.accountId, isNull);
  });

  test('fromStored migrates a leftover contact without @ to phone', () {
    final OperatorProfile profile = OperatorProfile.fromStored(
      name: 'Ada',
      preferences:
          '{"${AppConstants.operator.initialsKey}":"AL",'
          '"${AppConstants.operator.contactKey}":"+256700"}',
    );
    expect(profile.email, isNull);
    expect(profile.phone, '+256700');
    expect(profile.contact, '+256700');
  });

  test('fromStored prefers the new keys over a leftover contact', () {
    final OperatorProfile profile = OperatorProfile.fromStored(
      name: 'Ada',
      preferences:
          '{"${AppConstants.operator.emailKey}":"new@x",'
          '"${AppConstants.operator.phoneKey}":"0711",'
          '"${AppConstants.operator.contactKey}":"old@x"}',
    );
    expect(profile.email, 'new@x');
    expect(profile.phone, '0711');
    expect(profile.contact, 'new@x');
  });

  test('fromStored defaults initials from the name when they are missing', () {
    final OperatorProfile profile = OperatorProfile.fromStored(
      name: 'Ada Lovelace',
      preferences: '{}',
    );
    expect(profile.initials, 'AL');
    expect(profile.email, isNull);
    expect(profile.phone, isNull);
    expect(profile.contact, isNull);
  });

  test('mergePreferences writes email and phone and drops the old key', () {
    const OperatorProfile profile = OperatorProfile(
      name: 'Ada',
      initials: 'A',
      email: 'ada@x',
      phone: '0711',
    );
    expect(
      jsonDecode(
        profile.mergePreferences(
          '{"theme":"dark","${AppConstants.operator.contactKey}":"old@x"}',
        ),
      ),
      {
        'theme': 'dark',
        AppConstants.operator.initialsKey: 'A',
        AppConstants.operator.emailKey: 'ada@x',
        AppConstants.operator.phoneKey: '0711',
      },
    );
  });

  test(
    'a migrated email save keeps unknown keys and stops writing contact',
    () {
      final OperatorProfile profile = OperatorProfile.fromStored(
        name: 'Ada',
        preferences:
            '{"theme":"dark","${AppConstants.operator.contactKey}":"ada@x"}',
      );
      expect(profile.email, 'ada@x');
      expect(
        jsonDecode(
          profile.mergePreferences(
            '{"theme":"dark","${AppConstants.operator.contactKey}":"ada@x"}',
          ),
        ),
        {
          'theme': 'dark',
          AppConstants.operator.initialsKey: 'A',
          AppConstants.operator.emailKey: 'ada@x',
        },
      );
    },
  );
}
