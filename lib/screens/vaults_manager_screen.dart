import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/journal_provider.dart';
import '../models/entities/vault_definition.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_drawer.dart';

class VaultsManagerScreen extends StatelessWidget {
  const VaultsManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg0,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Tus Baúles',
          style: TextStyle(
            color: context.theme.fg0,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.theme.bg0,
        elevation: 0,
        iconTheme: IconThemeData(color: context.theme.fg0),
      ),
      body: Consumer<JournalProvider>(
        builder: (context, provider, _) {
          final vaults = provider.vaults;

          return Column(
            children: [
              SizedBox(height: 16),
              // Botón de Crear Nuevo Baúl al estilo de la imagen
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showCreateOrEditVaultDialog(context, null);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF4CAF50), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Crear Nuevo Baúl',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 24),

              if (vaults.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No tienes baúles aún',
                      style: TextStyle(color: context.theme.fg1, fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Cuadricula 3x3 solicitada
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio:
                          0.8, // Ajuste para acomodar imagen y texto
                    ),
                    itemCount: vaults.length,
                    itemBuilder: (context, index) {
                      final vault = vaults[index];
                      return _VaultGridItem(vault: vault, provider: provider);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Dialogo extendido con más colores
  static void _showCreateOrEditVaultDialog(
    BuildContext context,
    VaultDefinition? vaultToEdit,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: vaultToEdit?.name ?? '',
    );
    int selectedColor =
        vaultToEdit?.colorValue ??
        Colors.purple.toARGB32(); // Por defecto un color fuerte

    // Paleta de colores extendida (Primarios y Acentos combinados)
    final List<Color> palette = [
      ...Colors.primaries,
      ...Colors.accents,
      Colors.white,
      Colors.black,
      Colors.grey,
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: context.theme.bg1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              vaultToEdit == null ? 'Nuevo Baúl' : 'Modificar Baúl',
              style: TextStyle(
                color: context.theme.fg0,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Nombre del Baúl',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: vaultToEdit == null,
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Color del Baúl:',
                      style: TextStyle(
                        color: context.theme.fg0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: palette.map((col) {
                      final bool isSelected = selectedColor == col.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            selectedColor = col.toARGB32();
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: context.theme.fg0, width: 3)
                                : Border.all(color: Colors.transparent),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: col.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: col.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  // Opcion de Pin adentro del editor para no saturar la tarjeta UI
                  if (vaultToEdit != null)
                    SwitchListTile(
                      title: Text(
                        'Fijar en barra lateral',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: vaultToEdit.isPinned,
                      activeThumbColor: Color(selectedColor),
                      onChanged: (val) {
                        setState(() {
                          vaultToEdit.isPinned = val;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: context.theme.fg1),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final val = nameController.text.trim();
                  if (val.isNotEmpty) {
                    HapticFeedback.mediumImpact();
                    final provider = context.read<JournalProvider>();
                    if (vaultToEdit == null) {
                      provider.createVault(
                        name: val,
                        colorValue: selectedColor,
                      );
                    } else {
                      vaultToEdit.name = val;
                      vaultToEdit.colorValue = selectedColor;
                      provider.updateVault(vaultToEdit);
                    }
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(selectedColor),
                  foregroundColor: Color(selectedColor).computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
                child: Text(
                  vaultToEdit == null ? 'Crear' : 'Guardar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VaultGridItem extends StatelessWidget {
  final VaultDefinition vault;
  final JournalProvider provider;

  const _VaultGridItem({required this.vault, required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = vault.colorValue != null
        ? Color(vault.colorValue!)
        : Colors.purple;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Entrar a las notas
            provider.setSection(vault.uuid);
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          onLongPress: () {
            HapticFeedback.heavyImpact();
            VaultsManagerScreen._showCreateOrEditVaultDialog(context, vault);
          },
          child: Container(
            decoration: BoxDecoration(
              color: context.theme.bg1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Contenido base de la tarjeta
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 24.0,
                          left: 8.0,
                          right: 8.0,
                          bottom: 8.0,
                        ),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            color,
                            BlendMode.modulate,
                          ),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              // Matriz de escala de grises para neutralizar el color original
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                            child: Image.asset(
                              'assets/vault.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8.0,
                        left: 4,
                        right: 4,
                      ),
                      child: Text(
                        vault.name.toLowerCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900, // Extra bold
                          fontSize: 15, // Letra más grande
                          shadows: const [
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 2.0,
                              color: Colors
                                  .black54, // Sombreado oscuro para contrastar cian/amarillo
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Contador de Notas (Dato util)
                    Consumer<JournalProvider>(
                      builder: (context, ref, _) {
                        final count = ref.monthEntries.values
                            .expand((e) => e)
                            .where((nt) => nt.sectionId == vault.uuid)
                            .length;
                        if (count == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            '$count notas',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.theme.fg1,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Boton de Opciones (Hamburguesa / Tres Puntos) Superior Derecho
                Positioned(
                  top: 0,
                  right: 0,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: context.theme.fg1,
                    ),
                    padding: EdgeInsets.zero,
                    color: context.theme.bgSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        VaultsManagerScreen._showCreateOrEditVaultDialog(
                          context,
                          vault,
                        );
                      } else if (value == 'pin') {
                        HapticFeedback.lightImpact();
                        provider.toggleVaultPin(vault);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: context.theme.blue),
                          title: Text(
                            'Editar aparencia',
                            style: TextStyle(color: context.theme.fg0),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pin',
                        child: ListTile(
                          leading: Icon(
                            vault.isPinned
                                ? Icons.push_pin_outlined
                                : Icons.push_pin,
                            color: context.theme.orange,
                          ),
                          title: Text(
                            vault.isPinned
                                ? 'Desfijar de inicio'
                                : 'Fijar baúl rápido',
                            style: TextStyle(color: context.theme.fg0),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: context.theme.red,
                          ),
                          title: Text(
                            'Eliminar baúl',
                            style: TextStyle(color: context.theme.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicador visual de fijado (Top Left) para saber si esta pineado
                if (vault.isPinned)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(Icons.push_pin, size: 16, color: color),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    bool deleteNotes = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.theme.bg1,
              title: Text(
                'Borrar Baúl',
                style: TextStyle(color: context.theme.red),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Borrar "${vault.name}" permanentemente?',
                    style: TextStyle(color: context.theme.fg0),
                  ),
                  SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: context.theme.red,
                    checkColor: Colors.white,
                    title: Text(
                      'Destruir de igual manera TODAS sus notas',
                      style: TextStyle(color: context.theme.fg0, fontSize: 13),
                    ),
                    value: deleteNotes,
                    onChanged: (val) {
                      setState(() {
                        deleteNotes = val ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: context.theme.fg1),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    provider.deleteVault(vault, deleteNotes: deleteNotes);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(
                    'Eliminar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
