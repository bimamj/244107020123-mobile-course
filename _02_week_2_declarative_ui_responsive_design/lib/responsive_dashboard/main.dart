import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

void main() => runApp(const AcademicApp());

class AcademicApp extends StatefulWidget {
  const AcademicApp({super.key});

  @override
  State<AcademicApp> createState() => _AcademicAppState();
}

class _AcademicAppState extends State<AcademicApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: AcademicOverviewPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class AcademicOverviewPage extends StatelessWidget {
  const AcademicOverviewPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });
  
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              ),
              const SizedBox(width: 4),
              Semantics(
                label: 'Toggle dark mode',
                child: CupertinoSwitch(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Profile
          Semantics(
            label: 'Student Profile: Muh Bima J, NIM 244107020XXX, Informatics Engineering Major',
            container: true,
            excludeSemantics: true,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Muh Bima J',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text('NIM: 244107020XXX'),
                        const Text('Informatics Engineering Major'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // GRID KARTU INFORMASI (Responsive Layout)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Breakpoint: 1 kolom jika < 600, 2 kolom jika >= 600
                final columns = constraints.maxWidth >= 600 ? 2 : 1;
                
                return GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3.0,
                  children: const [
                    InfoCard(title: 'GPA', value: '4'),
                    InfoCard(title: 'Total Credit', value: '110'),
                    InfoCard(title: 'Attendance', value: '95%'),
                    InfoCard(title: 'Active Tasks', value: '3'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.value, super.key});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $value',
      container: true,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}