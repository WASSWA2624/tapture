import 'package:tapture/core/ids/uuid_service.dart';

/// An [IdService] that mints `<prefix>-1`, `<prefix>-2`, … and counts how
/// many it handed out, so a test can assert an id was or was not taken
/// (FE-TEST-03).
final class FakeIdService implements IdService {
  /// Creates the fake. Ids start with [prefix].
  FakeIdService({this.prefix = 'id'});

  /// The text every id starts with.
  final String prefix;

  int _minted = 0;

  /// How many ids [newId] has handed out.
  int get minted => _minted;

  @override
  String newId() => '$prefix-${++_minted}';
}
