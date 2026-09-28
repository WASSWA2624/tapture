import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/background/background_policy.dart';
import 'package:tapture/core/network/connectivity_service.dart';

void main() {
  const BackgroundPolicy policy = BackgroundPolicy();

  test(
    'foreground work never runs, and on-device reading needs charge and idle',
    () {
      expect(
        policy.mayRun(
          charging: true,
          idle: true,
          net: NetworkState.offline,
          foreground: true,
        ),
        isFalse,
      );
      expect(
        policy.mayRun(
          charging: true,
          idle: true,
          net: NetworkState.offline,
          foreground: false,
        ),
        isTrue,
      );
      expect(
        policy.mayRun(
          charging: false,
          idle: true,
          net: NetworkState.offline,
          foreground: false,
        ),
        isFalse,
      );
    },
  );

  test('automatic processing stops when the network does not allow it', () {
    expect(
      policy.mayRun(
        charging: true,
        idle: true,
        net: NetworkState.offline,
        foreground: false,
        automatic: true,
      ),
      isFalse,
    );
    expect(
      policy.mayRun(
        charging: false,
        idle: false,
        net: NetworkState.online,
        foreground: false,
        automatic: true,
      ),
      isTrue,
    );
  });
}
