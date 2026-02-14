import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/local_db/isar_service.dart';
import 'providers/journal_provider.dart';
import 'screens/home_screen.dart';
import 'screens/editor_nota_screen.dart';
import 'config/theme.dart';

// secuencia de arranque: enlaza el engine nativo, abre la bd isar
// y monta el arbol de providers antes de pintar la primera pantalla
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // isar debe estar listo antes de inyectar providers que lo consumen
  await IsarService.init();
  
  // multiprovider envuelve toda la app para que cualquier widget
  // pueda acceder al estado de journal sin pasarlo manualmente
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
      theme: gruvboxTheme(),
      home: const MainNavigationWrapper(),
    );
  }
}

// shell principal de la app: controla la navegacion lateral y el contenido
// usa stateful porque el indice de la seccion activa debe sobrevivir rebuilds
class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  // indice de la seccion activa: 0=diario, 1=agenda, 2=habitos
  int _selectedIndex = 0;

  final List<String> _titles = ['Mi Diario', 'Agenda', 'Mis Hábitos'];

  // cambia la seccion visible y cierra el drawer automaticamente
  void _onSelectItem(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: GruvboxColors.bg_soft,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: GruvboxColors.bg0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Agendario', style: TextStyle(color: GruvboxColors.green, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('tratando de organizar ;-;', style: TextStyle(color: GruvboxColors.yellow, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined, color: GruvboxColors.blue),
              title: const Text('Diario'),
              selected: _selectedIndex == 0,
              onTap: () => _onSelectItem(0),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined, color: GruvboxColors.aqua),
              title: const Text('Agenda'),
              selected: _selectedIndex == 1,
              onTap: () => _onSelectItem(1),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: GruvboxColors.green),
              title: const Text('Hábitos'),
              selected: _selectedIndex == 2,
              onTap: () => _onSelectItem(2),
            ),
            const Divider(color: GruvboxColors.bg1),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: GruvboxColors.purple),
              title: const Text('Ajustes'),
              onTap: () {},
            ),
          ],
        ),
      ),
      // indexedstack mantiene vivos todos los hijos aunque no esten visibles
      // asi el estado de cada seccion se preserva al cambiar de tab
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          Center(child: Text('Calendario Próximamente')),
          Center(child: Text('Hábitos Próximamente')),
        ],
      ),
      // fab solo visible en la seccion diario, para crear nueva nota
      // en las demas secciones la accion principal sera distinta
      floatingActionButton: _selectedIndex == 0 
        ? FloatingActionButton(
            backgroundColor: GruvboxColors.orange,
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const EditorNotaScreen())
            ),
            child: const Icon(Icons.edit_note, color: GruvboxColors.bg0),
          )
        : null,
    );
  }
}
