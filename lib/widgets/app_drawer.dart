import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entities/vault_definition.dart';
import '../providers/journal_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/vaults_manager_screen.dart';
import '../config/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final journalProvider = context.watch<JournalProvider>();
    final vaults = journalProvider.vaults;
    final currentSection = journalProvider.currentSection;

    // Determines the selected index based on section
    int selectedIndex = 0;
    if (currentSection == 'agenda') selectedIndex = 1;

    return Drawer(
      backgroundColor: context.theme.bgSoft,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: context.theme.bg1),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Agendario',
                    style: TextStyle(
                      color: context.theme.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'tratando de organizar ;-;',
                    style: TextStyle(color: context.theme.yellow, fontSize: 14),
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
                  leading: Icon(Icons.book_outlined, color: context.theme.blue),
                  title: Text(
                    'Diario',
                    style: TextStyle(color: context.theme.fg0),
                  ),
                  selected:
                      selectedIndex == 0 &&
                      (currentSection == null || currentSection == 'diario'),
                  onTap: () => _onSelectItem(context, 0, sectionId: 'diario'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.calendar_today_outlined,
                    color: context.theme.aqua,
                  ),
                  title: Text(
                    'Agenda',
                    style: TextStyle(color: context.theme.fg0),
                  ),
                  selected: selectedIndex == 1,
                  onTap: () => _onSelectItem(context, 1, sectionId: 'agenda'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: context.theme.green,
                  ),
                  title: Text(
                    'Hábitos',
                    style: TextStyle(color: context.theme.fg0),
                  ),
                  selected: selectedIndex == 2,
                  onTap: () => _onSelectItem(context, 2, sectionId: 'habitos'),
                ),
                Divider(color: context.theme.bg1),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 4),
                  child: Text(
                    'MIS BAÚLES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.theme.fg1,
                    ),
                  ),
                ),
                ...vaults.where((v) => v.isPinned).map((vault) {
                  return ListTile(
                    leading: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        vault.colorValue != null
                            ? Color(vault.colorValue!)
                            : context.theme.yellow,
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
                    title: Text(
                      vault.name,
                      style: TextStyle(color: context.theme.fg0),
                    ),
                    selected: currentSection == vault.uuid,
                    onTap: () => _onSelectVault(context, vault),
                  );
                }),
                ListTile(
                  leading: Icon(
                    Icons.inventory_2_outlined,
                    color: context.theme.fg1,
                  ),
                  title: Text(
                    'Administrar Baúles',
                    style: TextStyle(color: context.theme.fg0),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Cierra el drawer
                    Navigator.pushReplacement(
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
          Divider(color: context.theme.bg1, height: 1),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: context.theme.purple),
            title: Text('Ajustes', style: TextStyle(color: context.theme.fg0)),
            onTap: () {
              Navigator.pop(context);
              _showThemeSettings(context);
            },
          ),
        ],
      ),
    );
  }

  void _onSelectItem(BuildContext context, int index, {String? sectionId}) {
    Navigator.pop(context);
    // If not on Home/Agenda, pop entirely tracking to Home
    if (ModalRoute.of(context)?.settings.name != '/') {
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    }

    // We only manage Journal's section. The Main Screen stack controls what is shown.
    if (sectionId != null) {
      context.read<JournalProvider>().setSection(sectionId);
    }

    // Habitos screen requires a local index dispatch, but the easiest implementation
    // is to just ignore it here since they were global, but we should make sure they
    // navigate properly if needed.
  }

  void _onSelectVault(BuildContext context, VaultDefinition vault) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name != '/') {
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    }
    context.read<JournalProvider>().setSection(vault.uuid);
  }

  void _showThemeSettings(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: sheetContext.theme.bg0,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Apariencia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: sheetContext.theme.fg0,
                      ),
                    ),
                  ),
                  Consumer<ThemeProvider>(
                    builder: (consumerCtx, provider, child) => ListTile(
                      title: Text(
                        'Modo Oscuro',
                        style: TextStyle(color: consumerCtx.theme.fg0),
                      ),
                      trailing: Switch(
                        value: provider.isDarkMode,
                        activeThumbColor: consumerCtx.theme.orange,
                        onChanged: (val) {
                          provider.setThemeMode(
                            val ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ),
                  ),
                  Divider(color: sheetContext.theme.bg1),
                  _buildThemeTile(sheetContext, 'Gruvbox', ThemeType.gruvbox),
                  _buildThemeTile(
                    sheetContext,
                    'Solarized',
                    ThemeType.solarized,
                  ),
                  _buildThemeTile(sheetContext, 'Nord', ThemeType.nord),
                  _buildThemeTile(sheetContext, 'Dracula', ThemeType.dracula),
                  _buildThemeTile(
                    sheetContext,
                    'Tokyo Night',
                    ThemeType.tokyioNight,
                  ),
                  _buildThemeTile(sheetContext, 'OLED / Paper', ThemeType.oled),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeTile(
    BuildContext sheetContext,
    String title,
    ThemeType type,
  ) {
    return Consumer<ThemeProvider>(
      builder: (consumerCtx, provider, child) {
        final isSelected = provider.themeType == type;
        return ListTile(
          title: Text(title, style: TextStyle(color: sheetContext.theme.fg0)),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: sheetContext.theme.green)
              : null,
          onTap: () {
            provider.setThemeType(type);
          },
        );
      },
    );
  }
}
