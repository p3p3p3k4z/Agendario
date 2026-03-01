import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/local_db/isar_service.dart';
import 'providers/journal_provider.dart';
import 'providers/habit_provider.dart';
import 'screens/home_screen.dart';
import 'screens/editor_nota_screen.dart';
import 'screens/agenda_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/habit_editor_screen.dart';
import 'screens/event_editor_screen.dart';
import 'screens/vaults_manager_screen.dart';
import 'models/enums/entry_type.dart';
import 'models/entities/vault_definition.dart';
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
      providers: [
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
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
  // indice de la seccion (Diario, Agenda, Hábitos)
  int _selectedIndex = 0;

  // Cambia la sección global
  void _onSelectItem(int index, {String? sectionId}) {
    final provider = context.read<JournalProvider>();
    provider.setSection(sectionId); // null significa diario por defecto

    setState(() => _selectedIndex = index);
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  // Si seleccionamos un baul especifico
  void _onSelectVault(VaultDefinition vault) {
    final provider = context.read<JournalProvider>();
    provider.setSection(vault.uuid);

    // Forzamos la vista al Índice 0 (Diario/Tablero) para mostrar sus notas
    setState(() => _selectedIndex = 0);
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el provider para saber la sección activa y listar los baúles
    final provider = context.watch<JournalProvider>();
    final currentSection = provider.currentSection;
    final vaults = provider.vaults;

    // Configura titulo del Appbar según seccion actual
    String appBarTitle = 'Mi Diario';
    if (_selectedIndex == 1) {
      appBarTitle = 'Agenda';
    } else if (_selectedIndex == 2) {
      appBarTitle = 'Mis Hábitos';
    } else if (currentSection != null && currentSection != 'diario') {
      // Si es un UUID de baúl, buscar su nombre
      final activeVault = vaults
          .where((v) => v.uuid == currentSection)
          .firstOrNull;
      if (activeVault != null) {
        appBarTitle = 'Baúl: ${activeVault.name}';
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle), elevation: 0),
      drawer: Drawer(
        backgroundColor: GruvboxColors.bg_soft,
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: GruvboxColors.bg0),
              child: SizedBox(
                width: double.infinity,
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
                      style: TextStyle(
                        color: GruvboxColors.yellow,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.book_outlined,
                      color: GruvboxColors.blue,
                    ),
                    title: const Text('Diario'),
                    selected:
                        _selectedIndex == 0 &&
                        (currentSection == null || currentSection == 'diario'),
                    onTap: () => _onSelectItem(0, sectionId: 'diario'),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today_outlined,
                      color: GruvboxColors.aqua,
                    ),
                    title: const Text('Agenda'),
                    selected: _selectedIndex == 1,
                    onTap: () => _onSelectItem(1, sectionId: 'agenda'),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: GruvboxColors.green,
                    ),
                    title: const Text('Hábitos'),
                    selected: _selectedIndex == 2,
                    onTap: () =>
                        _onSelectItem(2), // los habitos son globales por ahora
                  ),
                  const Divider(color: GruvboxColors.bg1),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, top: 8, bottom: 4),
                    child: Text(
                      'MIS BAÚLES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: GruvboxColors.bg1,
                      ),
                    ),
                  ),
                  // Listar baules creados por el usuario que esten fajados
                  ...vaults.where((v) => v.isPinned).map((vault) {
                    return ListTile(
                      leading: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          vault.colorValue != null
                              ? Color(vault.colorValue!)
                              : GruvboxColors.yellow,
                          BlendMode.modulate,
                        ),
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                          child: Image.asset(
                            'assets/vault.png',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      title: Text(vault.name),
                      selected:
                          _selectedIndex == 0 && currentSection == vault.uuid,
                      onTap: () => _onSelectVault(vault),
                    );
                  }),
                  ListTile(
                    leading: const Icon(
                      Icons.inventory_2_outlined,
                      color: GruvboxColors.bg1,
                    ),
                    title: const Text('Administrar Baúles'),
                    onTap: () {
                      Navigator.pop(context); // Cierra el drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VaultsManagerScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: GruvboxColors.bg1, height: 1),
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
        children: const [HomeScreen(), AgendaScreen(), HabitsScreen()],
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
      case 2:
        // habitos: crear nuevo habito
        return FloatingActionButton(
          backgroundColor: GruvboxColors.green,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HabitEditorScreen()),
          ),
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
                      initialSectionId: 'agenda',
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
                      initialSectionId: 'agenda',
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
                      initialSectionId: 'agenda',
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
