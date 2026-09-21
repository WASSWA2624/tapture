import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/files/volume_stats.dart';

void main() {
  test('parsePosixDf reads 1024-blocks, used and available', () {
    const String stdout =
        'Filesystem 1024-blocks Used Available Capacity Mounted\n'
        '/dev/sda1 1048576 262144 786432 25% /\n';
    final VolumeStats stats = VolumeStats.parsePosixDf(stdout);
    expect(stats.totalBytes, 1048576 * 1024);
    expect(stats.usedBytes, 262144 * 1024);
    expect(stats.freeBytes, 786432 * 1024);
  });

  test('parsePosixDf accepts a wrapped filesystem line', () {
    const String stdout =
        'Filesystem 1024-blocks Used Available Capacity Mounted\n'
        '/dev/mapper/very-long-volume-name\n'
        '1048576 100 1048476 1% /\n';
    final VolumeStats stats = VolumeStats.parsePosixDf(stdout);
    expect(stats.totalBytes, 1048576 * 1024);
    expect(stats.usedBytes, 100 * 1024);
    expect(stats.freeBytes, 1048476 * 1024);
  });

  test('parsePosixDf rejects a header-only listing', () {
    expect(
      () => VolumeStats.parsePosixDf('Filesystem 1024-blocks Used Available'),
      throwsFormatException,
    );
  });

  test('parseWindowsPsDrive sums Used and Free', () {
    final VolumeStats stats = VolumeStats.parseWindowsPsDrive('1000 3000\n');
    expect(stats.usedBytes, 1000);
    expect(stats.freeBytes, 3000);
    expect(stats.totalBytes, 4000);
  });

  test('parseWindowsPsDrive rejects a non-numeric line', () {
    expect(
      () => VolumeStats.parseWindowsPsDrive('Used Free'),
      throwsFormatException,
    );
  });

  test('fromChannel reads the three figures', () {
    final VolumeStats stats = VolumeStats.fromChannel(<Object?, Object?>{
      'totalBytes': 80,
      'usedBytes': 30,
      'freeBytes': 50,
    });
    expect(stats.totalBytes, 80);
    expect(stats.usedBytes, 30);
    expect(stats.freeBytes, 50);
  });

  test('fromChannel rejects a partial map', () {
    expect(
      () => VolumeStats.fromChannel(<Object?, Object?>{'totalBytes': 80}),
      throwsFormatException,
    );
  });
}
