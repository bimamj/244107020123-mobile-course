import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// -----------------------------------------------------------------------------
// 1. MODEL DATA
// -----------------------------------------------------------------------------
/// Model data sederhana untuk item statistik
class StatItem {
  final String title;
  final String value;
  final IconData icon;

  StatItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

// -----------------------------------------------------------------------------
// 2. REPOSITORY / SERVICE LOGIC
// -----------------------------------------------------------------------------
/// Class yang bertugas melakukan simulasi panggailan API / fetch data
class StatsRepository {
  Future<List<StatItem>> fetchStats({Random? customRandom}) async {
    // Simulasi delay jaringan 2 detik
    await Future.delayed(const Duration(seconds: 2));

    final random = customRandom ?? Random();
    // Simulasi error dengan probabilitas 30% (jika angka random < 0.3)
    if (random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik dari server.');
    }

    // Mengembalikan 3 item data jika sukses
    return [
      StatItem(
        title: 'Total Pengguna',
        value: '12.450',
        icon: Icons.people,
      ),
      StatItem(
        title: 'Pendapatan',
        value: 'Rp 45.000.000',
        icon: Icons.attach_money,
      ),
      StatItem(
        title: 'Sesi Aktif',
        value: '1.230',
        icon: Icons.bolt,
      ),
    ];
  }
}

/// Provider untuk Repository agar mudah di-override saat unit testing
final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository();
});

// -----------------------------------------------------------------------------
// 3. ASYNC NOTIFIER & PROVIDER
// -----------------------------------------------------------------------------
/// AsyncNotifier mengelola status asinkron (AsyncValue: loading, error, data)
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  @override
  Future<List<StatItem>> build() async {
    // Mengambil repository dari provider dan melakukan fetch data
    final repository = ref.watch(statsRepositoryProvider);
    return repository.fetchStats();
  }
}

/// Provider global untuk StatsNotifier
final statsNotifierProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(
  StatsNotifier.new,
);

// -----------------------------------------------------------------------------
// 4. UI PAGE (ConsumerWidget)
// -----------------------------------------------------------------------------
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau status AsyncValue dari statsNotifierProvider
    final statsAsync = ref.watch(statsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Sistem'),
      ),
      // statsAsync.when() menangani 3 state utama Riverpod: loading, error, data
      body: statsAsync.when(
        // State 1: Loading -> Tampilkan indikator putar (spinner)
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // State 2: Error -> Tampilkan pesan error & tombol retry
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // ref.invalidate memaksa provider untuk me-rebuild & fetch ulang data
                    ref.invalidate(statsNotifierProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),

        // State 3: Success -> Tampilkan ListView dengan 3 item
        data: (stats) => ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final item = stats[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColorLight,
                  child: Icon(item.icon, color: Theme.of(context).primaryColor),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}