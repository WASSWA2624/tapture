import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/grant_cache.dart';
import 'package:tapture/core/backend/offline_authority.dart';

void main() {
  test('every capability is answered for every authority state', () {
    const Map<AuthorityState, Set<WorkCapability>> allowed =
        <AuthorityState, Set<WorkCapability>>{
          AuthorityState.fresh: <WorkCapability>{
            WorkCapability.capture,
            WorkCapability.review,
            WorkCapability.edit,
            WorkCapability.export,
            WorkCapability.relay,
            WorkCapability.aiProxy,
            WorkCapability.roleChange,
          },
          AuthorityState.cachedValid: <WorkCapability>{
            WorkCapability.capture,
            WorkCapability.review,
            WorkCapability.edit,
            WorkCapability.export,
            WorkCapability.relay,
            WorkCapability.aiProxy,
            WorkCapability.roleChange,
          },
          AuthorityState.cachedExpired: <WorkCapability>{
            WorkCapability.capture,
            WorkCapability.review,
            WorkCapability.edit,
            WorkCapability.export,
          },
          AuthorityState.neverSignedIn: <WorkCapability>{},
        };
    for (final AuthorityState state in AuthorityState.values) {
      final OfflineAuthority authority = OfflineAuthority(state);
      for (final WorkCapability capability in WorkCapability.values) {
        expect(
          authority.may(capability),
          allowed[state]!.contains(capability),
          reason: '$state $capability',
        );
      }
    }
  });

  test('forty-five days offline still captures and exports', () {
    final Map<String, String> secrets = <String, String>{};
    final GrantCache cache = GrantCache(
      secrets: secrets,
      now: () => DateTime.utc(2026, 1, 1),
    );
    cache.save(
      accessToken: 'access',
      refreshToken: 'refresh',
      organisationId: 'org-1',
      refreshedAt: DateTime.utc(2026, 1, 1),
    );
    final AuthorityState state = cache.read(at: DateTime.utc(2026, 2, 15));
    expect(state, AuthorityState.cachedExpired);
    final OfflineAuthority authority = OfflineAuthority(state);
    expect(authority.may(WorkCapability.capture), isTrue);
    expect(authority.may(WorkCapability.export), isTrue);
    expect(authority.may(WorkCapability.relay), isFalse);
    expect(authority.may(WorkCapability.aiProxy), isFalse);
    expect(authority.may(WorkCapability.roleChange), isFalse);
    expect(authority.refusal(WorkCapability.relay), isNotNull);
  });
}
