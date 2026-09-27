/// A grant saved in secure storage. The clock is injected.
final class GrantCache {
  /// Creates a cache over [secrets]. [database], [logs] and [exports] are
  /// watched so a token cannot land in them.
  GrantCache({
    required this.secrets,
    this.database,
    this.logs,
    this.exports,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// How long a grant authorises relay and analysis without a refresh.
  static const Duration lifetime = Duration(days: 30);

  static const String _secret = 'tapture.backend.session';

  /// Secure-storage stand-in. Values written here never go anywhere else.
  final Map<String, String> secrets;

  /// Database stand-in, watched so a token cannot land in it.
  final Map<String, String>? database;

  /// Log stand-in, watched so a token cannot land in it.
  final List<String>? logs;

  /// Export stand-in, watched so a token cannot land in it.
  final List<String>? exports;

  final DateTime Function() _now;

  /// Reads the cached grant. Missing storage is [AuthorityState.neverSignedIn].
  AuthorityState read({DateTime? at, Duration freshFor = const Duration(hours: 1)}) {
    final String? raw = secrets[_secret];
    if (raw == null || raw.isEmpty) return AuthorityState.neverSignedIn;
    final DateTime now = at ?? _now();
    final DateTime? until = _until(raw);
    final DateTime? refreshed = _refreshed(raw);
    if (until == null) return AuthorityState.cachedExpired;
    if (!now.isBefore(until)) return AuthorityState.cachedExpired;
    if (refreshed != null && now.difference(refreshed) <= freshFor) {
      return AuthorityState.fresh;
    }
    return AuthorityState.cachedValid;
  }

  /// Saves a grant. The value is written only to secure storage.
  void save({
    required String accessToken,
    required String refreshToken,
    required String organisationId,
    required DateTime refreshedAt,
  }) {
    final String value =
        '$accessToken|$refreshToken|$organisationId|${refreshedAt.toIso8601String()}';
    _rejectLeak(value);
    secrets[_secret] = value;
  }

  void _rejectLeak(String value) {
    final Map<String, String>? stored = database;
    final List<String>? written = logs;
    final List<String>? shared = exports;
    if (stored != null && stored.values.contains(value)) {
      throw StateError('A session was written to the database.');
    }
    if (written != null && written.any((String line) => line.contains(value))) {
      throw StateError('A session was written to a log.');
    }
    if (shared != null && shared.any((String line) => line.contains(value))) {
      throw StateError('A session was written to an export.');
    }
  }

  DateTime? _until(String raw) {
    final DateTime? refreshed = _refreshed(raw);
    return refreshed?.add(lifetime);
  }

  DateTime? _refreshed(String raw) {
    final String stamp = raw.split('|').last;
    return DateTime.tryParse(stamp);
  }
}

/// How fresh a cached grant is. Ordinary work does not consult the network.
enum AuthorityState {
  /// A grant was refreshed on this run.
  fresh,

  /// The saved grant is still inside its window.
  cachedValid,

  /// The window has passed. Capture continues; relay and analysis do not.
  cachedExpired,

  /// This install has never signed in.
  neverSignedIn,
}
