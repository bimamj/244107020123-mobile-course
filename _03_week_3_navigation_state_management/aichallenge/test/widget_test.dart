import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sesuaikan path import file stats_page kamu
import 'package:aichallenge/stats_page.dart';

class FakeSuccessStatsRepository implements StatsRepository {
  @override
  Future<List<StatItem>> fetchStats({Random? customRandom}) async {
    return [
      StatItem(title: 'Item 1', value: '100', icon: Icons.star),
      StatItem(title: 'Item 2', value: '200', icon: Icons.favorite),
      StatItem(title: 'Item 3', value: '300', icon: Icons.check),
    ];
  }
}

class FakeFailureStatsRepository implements StatsRepository {
  @override
  // Perhatikan: Tidak menggunakan keyword "async" dan tidak menggunakan "throw"
  Future<List<StatItem>> fetchStats({Random? customRandom}) {
    // Solusi Emas: Menggunakan Future.error mencegah test runner crash & timeout
    return Future.error(Exception('Simulasi gagal mengambil data'));
  }
}

void main() {
  group('StatsNotifier Unit Test', () {
    
    test('Mengembalikan state Loading lalu Data (Sukses) dengan 3 item', () async {
      final container = ProviderContainer(
        overrides: [
          statsRepositoryProvider.overrideWithValue(FakeSuccessStatsRepository()),
        ],
      );
      addTearDown(container.dispose);

      final states = <AsyncValue<List<StatItem>>>[];
      
      container.listen(
        statsNotifierProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      // Beri waktu sistem untuk menyelesaikan eksekusi asinkron
      await Future.delayed(const Duration(milliseconds: 10));

      // Cek riwayat state
      expect(states.first.isLoading, true);
      expect(states.last.hasValue, true);
      expect(states.last.value?.length, 3);
    });

    test('Mengembalikan state Error ketika fetchStats melempar exception', () async {
      final container = ProviderContainer(
        overrides: [
          statsRepositoryProvider.overrideWithValue(FakeFailureStatsRepository()),
        ],
      );
      addTearDown(container.dispose);

      final states = <AsyncValue<List<StatItem>>>[];
      
      container.listen(
        statsNotifierProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      // Cukup tunggu 10 milidetik agar Riverpod memproses Future.error di latar belakang
      // Tanpa perlu menyentuh .future atau try-catch sama sekali!
      await Future.delayed(const Duration(milliseconds: 10));

      // Pastikan awalnya Loading, dan state terakhirnya adalah Error
      expect(states.first.isLoading, true);
      expect(states.last.hasError, true);
    });
  });
}