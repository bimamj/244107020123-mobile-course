import 'package:flutter/material.dart';

void main() => runApp(const ProfileApp());

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: ProfileCard()),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Nama Mahasiswa',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('...ketik nama Anda di sini...'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(children: [
            Expanded(child: Text('NIM')),
            Text('...ketik NIM Anda di sini...'),
          ]),
          const Row(children: [
            Expanded(child: Text('Kelas')),
            Text('...ketik kelas Anda di sini...'),
          ]),
          const Row(children: [
            Expanded(child: Text('Email')),
            Text('...ketik email Anda di sini...'),
          ]),
        ],
      ),
    );
  }
}

//failed expanded app test
class FailedExpandedApp extends StatelessWidget {
  const FailedExpandedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Expanded Error Test')),
        // This is where the failed code goes
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal, 
          child: Row(
            children: [
              const Icon(Icons.info),
              Expanded( 
                // ERROR: This crashes the app because it tries 
                // to expand into infinite horizontal space.
                child: const Text('This text will crash the layout.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}