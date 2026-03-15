import 'package:flutter/material.dart';
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
import 'models/enums/entry_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'widgets/app_drawer.dart';

// secuencia de arranque: enlaza el engine nativo, abre la bd isar
// y monta el arbol de providers antes de pintar la primera pantalla
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // isar debe estar listo antes de inyectar providers que lo consumen
  await IsarService.init();

  // inicializa datos de locale para formateo de fechas
  await initializeDateFormatting('es_ES', null);

  // Inicializa db persistente pequeña para temas base
  final prefs = await SharedPreferences.getInstance();

  // multiprovider envuelve toda la app para que cualquier widget
  // pueda acceder al estado de journal sin pasarlo manualmente
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = ThemeProvider.of(context).isDarkMode;

    return MaterialApp(
      title: 'Agendario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: theme.bg0,
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.orange,
          primary: theme.orange,
          secondary: theme.yellow,
          surface: theme.bg0,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: theme.bg0,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.fg0),
          titleTextStyle: TextStyle(
            color: theme.fg0,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: theme.fg0),
          bodyMedium: TextStyle(color: theme.fg0),
        ),
      ),
      home: MainNavigationWrapper(),
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
  @override
  Widget build(BuildContext context) {
    // Escuchamos el provider para saber la sección activa y listar los baúles
    final provider = context.watch<JournalProvider>();
    final currentSection = provider.currentSection;
    final vaults = provider.vaults;

    int selectedIndex = 0;
    if (currentSection == 'agenda') {
      selectedIndex = 1;
    } else if (currentSection == 'habitos') {
      selectedIndex = 2;
    }

    // Configura titulo del Appbar según seccion actual
    String appBarTitle = 'Mi Diario';
    if (selectedIndex == 1) {
      appBarTitle = 'Agenda';
    } else if (selectedIndex == 2) {
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (provider.isSelectionMode) {
          provider.clearSelection();
          return;
        }
        final handled = provider.popSection();
        if (!handled) {
          if (context.mounted) {
            final NavigatorState navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        appBar: provider.isSelectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => provider.clearSelection(),
                ),
                title: Text('${provider.selectedIds.length} seleccionadas'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.folder_shared_outlined),
                    onPressed: () => _showBulkMoveDialog(context, provider),
                    tooltip: 'Mover a baúl',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmBulkDelete(context, provider),
                    tooltip: 'Eliminar seleccionadas',
                  ),
                ],
              )
            : AppBar(title: Text(appBarTitle), elevation: 0),
        drawer: provider.isSelectionMode ? null : const AppDrawer(),
        body: IndexedStack(
          index: selectedIndex,
          children: const [HomeScreen(), AgendaScreen(), HabitsScreen()],
        ),
        // fab contextual: cada seccion tiene su accion principal
        floatingActionButton: provider.isSelectionMode
            ? null
            : _buildFab(selectedIndex),
      ),
    );
  }

  void _confirmBulkDelete(BuildContext context, JournalProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.readTheme.bg1,
        title: Text(
          '¿Eliminar ${provider.selectedIds.length} notas?',
          style: TextStyle(color: ctx.readTheme.fg0),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: ctx.readTheme.fg1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: ctx.readTheme.fg1)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMultipleEntries(provider.selectedIds.toList());
              provider.clearSelection();
              Navigator.pop(ctx);
            },
            child: Text('Eliminar', style: TextStyle(color: ctx.readTheme.red)),
          ),
        ],
      ),
    );
  }

  void _showBulkMoveDialog(BuildContext context, JournalProvider provider) {
    final vaults = provider.vaults;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ctx.readTheme.bg1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mover ${provider.selectedIds.length} notas a...',
              style: TextStyle(
                color: ctx.readTheme.fg0,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: Icon(Icons.book_outlined, color: ctx.readTheme.blue),
                    title: Text(
                      'Diario (Sin baúl)',
                      style: TextStyle(color: ctx.readTheme.fg0),
                    ),
                    onTap: () {
                      provider.moveMultipleToVault(
                        provider.selectedIds.toList(),
                        'diario',
                      );
                      provider.clearSelection();
                      Navigator.pop(ctx);
                    },
                  ),
                  ...vaults.map(
                    (vault) => ListTile(
                      leading: Icon(
                        Icons.inventory_2_outlined,
                        color: vault.colorValue != null
                            ? Color(vault.colorValue!)
                            : ctx.readTheme.yellow,
                      ),
                      title: Text(
                        vault.name,
                        style: TextStyle(color: ctx.readTheme.fg0),
                      ),
                      onTap: () {
                        provider.moveMultipleToVault(
                          provider.selectedIds.toList(),
                          vault.uuid,
                        );
                        provider.clearSelection();
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // fab contextual segun la seccion activa
  Widget? _buildFab(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        // diario: crear nueva nota
        return FloatingActionButton(
          backgroundColor: context.theme.orange,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditorNotaScreen()),
          ),
          child: Icon(Icons.edit_note, color: context.theme.fg0),
        );
      case 1:
        // agenda: menu rapido con opciones de creacion
        return FloatingActionButton(
          backgroundColor: context.theme.aqua,
          onPressed: () => _showAgendaQuickAdd(),
          child: Icon(Icons.add, color: context.theme.bg0),
        );
      case 2:
        // habitos: crear nuevo habito
        return FloatingActionButton(
          backgroundColor: context.theme.green,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HabitEditorScreen()),
          ),
          child: Icon(Icons.add, color: context.theme.bg0),
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
        decoration: BoxDecoration(
          color: context.theme.bg1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.theme.bg1.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Crear nuevo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.theme.fg0,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: context.theme.blue.withValues(alpha: 0.15),
                child: Icon(Icons.event, color: context.theme.blue, size: 20),
              ),
              title: Text('Evento', style: TextStyle(color: context.theme.fg0)),
              subtitle: Text(
                'Con fecha y hora',
                style: TextStyle(fontSize: 12, color: context.theme.fg1),
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
              leading: CircleAvatar(
                backgroundColor: context.theme.green.withValues(alpha: 0.15),
                child: Icon(
                  Icons.check_circle_outline,
                  color: context.theme.green,
                  size: 20,
                ),
              ),
              title: Text(
                'Pendiente',
                style: TextStyle(color: context.theme.fg0),
              ),
              subtitle: Text(
                'Tarea por hacer',
                style: TextStyle(fontSize: 12, color: context.theme.fg1),
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
              leading: CircleAvatar(
                backgroundColor: context.theme.purple.withValues(alpha: 0.15),
                child: Icon(
                  Icons.notifications_outlined,
                  color: context.theme.purple,
                  size: 20,
                ),
              ),
              title: Text(
                'Recordatorio',
                style: TextStyle(color: context.theme.fg0),
              ),
              subtitle: Text(
                'No olvidar',
                style: TextStyle(fontSize: 12, color: context.theme.fg1),
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
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
