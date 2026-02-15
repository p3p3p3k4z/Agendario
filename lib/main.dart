import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/local_db/isar_service.dart';
import 'providers/journal_provider.dart';
import 'screens/home_screen.dart';
import 'screens/editor_nota_screen.dart';
import 'screens/agenda_screen.dart';
import 'screens/event_editor_screen.dart';
import 'models/enums/entry_type.dart';
import 'config/theme.dart';

// secuencia de arranque: enlaza el engine nativo, abre la bd isar
// y monta el arbol de providers antes de pintar la primera pantalla
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // isar debe estar listo antes de inyectar providers que lo consumen
  await IsarService.init();

  // inicializa datos de locale para formateo de fechas
  await initializeDateFormatting('es_ES', null);

  // multiprovider envuelve toda la app para que cualquier widget
  // pueda acceder al estado de journal sin pasarlo manualmente
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => JournalProvider())],
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
      appBar: AppBar(title: Text(_titles[_selectedIndex]), elevation: 0),
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
                  Text(
                    'Agendario',
                    style: TextStyle(
                      color: GruvboxColors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'tratando de organizar ;-;',
                    style: TextStyle(color: GruvboxColors.yellow, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.book_outlined,
                color: GruvboxColors.blue,
              ),
              title: const Text('Diario'),
              selected: _selectedIndex == 0,
              onTap: () => _onSelectItem(0),
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_today_outlined,
                color: GruvboxColors.aqua,
              ),
              title: const Text('Agenda'),
              selected: _selectedIndex == 1,
              onTap: () => _onSelectItem(1),
            ),
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline,
                color: GruvboxColors.green,
              ),
              title: const Text('Hábitos'),
              selected: _selectedIndex == 2,
              onTap: () => _onSelectItem(2),
            ),
            const Divider(color: GruvboxColors.bg1),
            ListTile(
              leading: const Icon(
                Icons.settings_outlined,
                color: GruvboxColors.purple,
              ),
              title: const Text('Ajustes'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          AgendaScreen(),
          Center(child: Text('Hábitos Próximamente')),
        ],
      ),
      // fab contextual: cada seccion tiene su accion principal
      floatingActionButton: _buildFab(),
    );
  }

  // fab contextual segun la seccion activa
  Widget? _buildFab() {
    switch (_selectedIndex) {
      case 0:
        // diario: crear nueva nota
        return FloatingActionButton(
          backgroundColor: GruvboxColors.orange,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditorNotaScreen()),
          ),
          child: const Icon(Icons.edit_note, color: GruvboxColors.bg0),
        );
      case 1:
        // agenda: menu rapido con opciones de creacion
        return FloatingActionButton(
          backgroundColor: GruvboxColors.aqua,
          onPressed: () => _showAgendaQuickAdd(),
          child: const Icon(Icons.add, color: Colors.white),
        );
      default:
        return null;
    }
  }

  // bottom sheet con opciones rapidas para crear en la agenda
  void _showAgendaQuickAdd() {
    final provider = context.read<JournalProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GruvboxColors.bg1.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Crear nuevo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GruvboxColors.bg0,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1A458588),
                child: Icon(Icons.event, color: GruvboxColors.blue, size: 20),
              ),
              title: const Text('Evento'),
              subtitle: const Text(
                'Con fecha y hora',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventEditorScreen(
                      initialType: EntryType.event,
                      initialDate: provider.selectedDate,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1A98971A),
                child: Icon(
                  Icons.check_circle_outline,
                  color: GruvboxColors.green,
                  size: 20,
                ),
              ),
              title: const Text('Pendiente'),
              subtitle: const Text(
                'Tarea por hacer',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventEditorScreen(
                      initialType: EntryType.todo,
                      initialDate: provider.selectedDate,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1AB16286),
                child: Icon(
                  Icons.notifications_outlined,
                  color: GruvboxColors.purple,
                  size: 20,
                ),
              ),
              title: const Text('Recordatorio'),
              subtitle: const Text(
                'No olvidar',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventEditorScreen(
                      initialType: EntryType.reminder,
                      initialDate: provider.selectedDate,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
