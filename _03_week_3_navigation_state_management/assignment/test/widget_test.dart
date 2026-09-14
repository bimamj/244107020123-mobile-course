// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Ganti 'nama_project_anda' dengan nama package di pubspec.yaml
import 'package:assignment/main.dart'; 

void main() {
  testWidgets('Menampilkan loading screen lalu merender daftar tugas', (tester) async {
    // Build aplikasi ke dalam test environment
    await tester.pumpWidget(const ProviderScope(child: AsyncTodoApp()));

    // 1. Verifikasi UI menampilkan Loading saat pertama kali dibuka
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // 2. Tunggu semua animasi dan delay Future selesai (Provider punya delay 2 detik)
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // 3. Verifikasi loading hilang dan list tugas default muncul
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Belajar Riverpod AsyncNotifier'), findsOneWidget);
    expect(find.text('Setup GoRouter Navigation'), findsOneWidget);
  });
}