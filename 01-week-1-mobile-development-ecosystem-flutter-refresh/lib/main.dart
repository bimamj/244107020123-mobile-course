import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Icon(Icons.person, size: 72),
              SizedBox(height: 16),
              Text(
                'Muhammad Bima Juliansyah', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 8),
              Text('NIM: 244107020123', style: TextStyle(fontSize: 24)),
              Text('Dream Profession: Data Scientist / Entrepreneur', style: TextStyle(fontSize: 16)),
              Text('Pemrograman Mobile — Minggu 1'),
            ]
          ),
        ),
      ),
    );
  }
}