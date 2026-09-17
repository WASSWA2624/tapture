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

  test('fromStored reads initials and contact and leaves accountId null', () {
    final OperatorProfile profile = OperatorProfile.fromStored(
      name: 'Ada',
      preferences:
          '{"${AppConstants.operator.initialsKey}":"AL",'
          '"${AppConstants.operator.contactKey}":"ada@x"}',
      accountId: null,
    );
    expect(profile.name, 'Ada');
    expect(profile.initials, 'AL');
    expect(profile.contact, 'ada@x');
    expect(profile.accountId, isNull);
  });

  test('fromStored defaults initials from the name when they are missing', () {
    final OperatorProfile profile = OperatorProfile.fromStored(
      name: 'Ada Lovelace',
      preferences: '{}',
    );
    expect(profile.initials, 'AL');
    expect(profile.contact, isNull);
  });

  test('mergePreferences keeps unknown keys and writes initials', () {
    const OperatorProfile profile = OperatorProfile(
      name: 'Ada',
      initials: 'A',
      contact: 'ada@x',
    );
    expect(jsonDecode(profile.mergePreferences('{"theme":"dark"}')), {
      'theme': 'dark',
      AppConstants.operator.initialsKey: 'A',
      AppConstants.operator.contactKey: 'ada@x',
    });
  });
}
