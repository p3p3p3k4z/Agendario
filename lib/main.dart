import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/local_db/isar_service.dart';
import 'providers/journal_provider.dart';

void main() async {
  // asegura que los bindings de flutter esten listos
  WidgetsFlutterBinding.ensureInitialized();
  
  // inicializa la base de datos local
  await IsarService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JournalProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agendario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// pantalla temporal para verificar que todo funciona
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendario')),
      body: Consumer<JournalProvider>(
        builder: (context, provider, child) {
          final entries = provider.entries;
          
          if (entries.isEmpty) {
            return const Center(child: Text('No hay entradas aún'));
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                title: Text(entry.title ?? 'Sin título'),
                subtitle: Text(entry.content ?? ''),
                trailing: Text(entry.scheduledDate.toString()),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<JournalProvider>().addTestEntry();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
