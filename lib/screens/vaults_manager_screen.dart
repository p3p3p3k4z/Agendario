import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../providers/journal_provider.dart';
import '../models/entities/vault_definition.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_drawer.dart';

import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class VaultsManagerScreen extends StatefulWidget {
  const VaultsManagerScreen({super.key});



  @override
  State<VaultsManagerScreen> createState() => _VaultsManagerScreenState();
}

class _VaultsManagerScreenState extends State<VaultsManagerScreen> {
  bool _showHiddenVaults = false;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  DateTime _lastShakeTime = DateTime.now();
  static const double shakeThreshold = 25.0; // Exageradamente fuerte

  @override
  void initState() {
    super.initState();
    _accelSubscription = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inSeconds > 2) {
          _lastShakeTime = now;
          if (mounted) {
            setState(() {
              _showHiddenVaults = !_showHiddenVaults;
            });
            HapticFeedback.heavyImpact();
            final fg0 = Provider.of<ThemeProvider>(context, listen: false).colors.fg0;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_showHiddenVaults ? 'Baúles ocultos revelados' : 'Baúles ocultados'),
                backgroundColor: fg0,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg0,
      appBar: AppBar(
        title: Text(
          'Tus Baúles',
          style: TextStyle(
            color: context.theme.fg0,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.theme.bg0,
        elevation: 0,
        iconTheme: IconThemeData(color: context.theme.fg0),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          showCreateOrEditVaultDialog(context, null);
        },
        backgroundColor: context.theme.fg0,
        elevation: 2,
        child: Icon(Icons.add, color: context.theme.bg0),
      ),
      body: Consumer<VaultProvider>(
        builder: (context, provider, _) {
          final allVaults = provider.vaults;
          final vaults = allVaults.where((v) => !v.isHidden || _showHiddenVaults).toList();

          if (vaults.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: context.theme.fg1.withValues(alpha: 0.5)),
                  SizedBox(height: 16),
                  Text(
                    'Aún no hay baúles',
                    style: TextStyle(color: context.theme.fg1, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Crea uno para organizar tus notas',
                    style: TextStyle(color: context.theme.fg1.withValues(alpha: 0.7), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: vaults.length,
            itemBuilder: (context, index) {
              final vault = vaults[index];
              return _VaultGridItem(vault: vault, provider: provider);
            },
          );
        },
      ),
    );
  }
}

void showCreateOrEditVaultDialog(
  BuildContext context,
  VaultDefinition? vaultToEdit,
) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final themeColors = themeProvider.colors;

    final TextEditingController nameController = TextEditingController(
      text: vaultToEdit?.name ?? '',
    );
    final TextEditingController passwordController = TextEditingController(
      text: vaultToEdit?.password ?? '',
    );
    int selectedColor = vaultToEdit?.colorValue ?? Colors.purple.toARGB32();

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
            backgroundColor: themeColors.bg1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              vaultToEdit == null ? 'Nuevo Baúl' : 'Modificar Baúl',
              style: TextStyle(
                color: themeColors.fg0,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: themeColors.fg0),
                    decoration: InputDecoration(
                      hintText: 'Nombre del Baúl',
                      hintStyle: TextStyle(color: themeColors.fg1),
                      filled: true,
                      fillColor: themeColors.bgSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autofocus: vaultToEdit == null,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    style: TextStyle(color: themeColors.fg0),
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Contraseña (Opcional)',
                      hintStyle: TextStyle(color: themeColors.fg1),
                      filled: true,
                      fillColor: themeColors.bgSoft,
                      prefixIcon: Icon(Icons.lock_outline, color: themeColors.fg1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Color del Baúl:',
                      style: TextStyle(
                        color: themeColors.fg0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: palette.map((col) {
                      final theme = Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).colors;
                      final bool isSelected = selectedColor == col.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            selectedColor = col.toARGB32();
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: isSelected ? 42 : 36,
                          height: isSelected ? 42 : 36,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: theme.fg0, width: 3)
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
                  if (vaultToEdit != null)
                    Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            'Fijar en barra lateral',
                            style: TextStyle(fontWeight: FontWeight.w600, color: themeColors.fg0),
                          ),
                          value: vaultToEdit.isPinned,
                          activeColor: Color(selectedColor),
                          onChanged: (val) {
                            setState(() {
                              vaultToEdit.isPinned = val;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: Text(
                            'Ocultar baúl',
                            style: TextStyle(fontWeight: FontWeight.w600, color: themeColors.fg0),
                          ),
                          subtitle: Text(
                            'Agita el dispositivo para revelarlo',
                            style: TextStyle(color: themeColors.fg1, fontSize: 12),
                          ),
                          value: vaultToEdit.isHidden,
                          activeColor: Color(selectedColor),
                          onChanged: (val) {
                            setState(() {
                              vaultToEdit.isHidden = val;
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: themeColors.fg1),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final val = nameController.text.trim();
                  final pass = passwordController.text.trim();
                  if (val.isNotEmpty) {
                    HapticFeedback.mediumImpact();
                    final provider = context.read<VaultProvider>();
                    if (vaultToEdit == null) {
                      provider.createVault(
                        name: val,
                        colorValue: selectedColor,
                        password: pass.isNotEmpty ? pass : null,
                      );
                    } else {
                      vaultToEdit.name = val;
                      vaultToEdit.colorValue = selectedColor;
                      vaultToEdit.password = pass.isNotEmpty ? pass : null;
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
class _VaultGridItem extends StatefulWidget {
  final VaultDefinition vault;
  final VaultProvider provider;

  const _VaultGridItem({
    super.key,
    required this.vault,
    required this.provider,
  });

  @override
  State<_VaultGridItem> createState() => _VaultGridItemState();
}

class _VaultGridItemState extends State<_VaultGridItem> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward(from: 0.0);
  }

  void _showDeleteConfirmation() {
    bool deleteNotes = false;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final themeColors = themeProvider.colors;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            return AlertDialog(
              backgroundColor: themeColors.bg1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Borrar Baúl',
                style: TextStyle(color: themeColors.red, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Borrar "${widget.vault.name}" permanentemente?',
                    style: TextStyle(color: themeColors.fg0),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: themeColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColors.red.withValues(alpha: 0.3)),
                    ),
                    child: CheckboxListTile(
                      activeColor: themeColors.red,
                      checkColor: Colors.white,
                      title: Text(
                        'Destruir de igual manera TODAS sus notas',
                        style: TextStyle(color: themeColors.fg0, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      value: deleteNotes,
                      onChanged: (val) {
                        setState(() {
                          deleteNotes = val ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: themeColors.fg1),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    widget.provider.deleteVault(
                      widget.vault,
                      deleteNotes: deleteNotes,
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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

  void _showPasswordPrompt() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final themeColors = themeProvider.colors;

    final TextEditingController passController = TextEditingController();
    bool error = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {
          return AlertDialog(
            backgroundColor: themeColors.bg1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.lock, color: themeColors.fg0),
                SizedBox(width: 8),
                Text('Baúl Bloqueado', style: TextStyle(color: themeColors.fg0)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingresa la contraseña para acceder a "${widget.vault.name}".',
                  style: TextStyle(color: themeColors.fg1),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passController,
                  obscureText: true,
                  style: TextStyle(color: themeColors.fg0),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    hintStyle: TextStyle(color: themeColors.fg1.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: themeColors.bgSoft,
                    errorText: error ? 'Contraseña incorrecta' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val == widget.vault.password) {
                      Navigator.pop(ctx);
                      _openVault();
                    } else {
                      setState(() => error = true);
                      _shake();
                      HapticFeedback.heavyImpact();
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: TextStyle(color: themeColors.fg1)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (passController.text == widget.vault.password) {
                    Navigator.pop(ctx);
                    _openVault();
                  } else {
                    setState(() => error = true);
                    _shake();
                    HapticFeedback.heavyImpact();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Desbloquear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _openVault() {
    context.read<JournalProvider>().setSection(widget.vault.uuid);
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _showVaultOptions() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final themeColors = themeProvider.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: themeColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: themeColors.fg1.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: themeColors.fg0),
              title: Text('Editar', style: TextStyle(color: themeColors.fg0)),
              onTap: () {
                Navigator.pop(ctx);
                showCreateOrEditVaultDialog(context, widget.vault);
              },
            ),
            ListTile(
              leading: Icon(
                widget.vault.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: themeColors.fg0,
              ),
              title: Text(widget.vault.isPinned ? 'Desfijar' : 'Fijar', style: TextStyle(color: themeColors.fg0)),
              onTap: () {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                widget.provider.toggleVaultPin(widget.vault);
              },
            ),
            ListTile(
              leading: Icon(
                widget.vault.isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: themeColors.fg0,
              ),
              title: Text(widget.vault.isHidden ? 'Mostrar baúl' : 'Ocultar baúl', style: TextStyle(color: themeColors.fg0)),
              onTap: () {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                widget.vault.isHidden = !widget.vault.isHidden;
                widget.provider.updateVault(widget.vault);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: themeColors.red),
              title: Text('Eliminar', style: TextStyle(color: themeColors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vault = widget.vault;
    final color = vault.colorValue != null
        ? Color(vault.colorValue!)
        : Colors.purple;
    final bool hasPassword = vault.password != null && vault.password!.isNotEmpty;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double offset = 10 * _shakeController.value * (1 - _shakeController.value) * 4 * (1 - (_shakeController.value * 2).floor());
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (hasPassword) {
                _showPasswordPrompt();
              } else {
                _openVault();
              }
            },
            onLongPress: () {
              HapticFeedback.heavyImpact();
              _showVaultOptions();
            },
            child: Container(
              decoration: BoxDecoration(
                color: context.theme.bg1,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.theme.bgSoft,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              left: 12.0,
                              right: 12.0,
                              bottom: 8.0,
                            ),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                color,
                                BlendMode.modulate,
                              ),
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.matrix(<double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0,      0,      0,      1, 0,
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
                          padding: const EdgeInsets.only(bottom: 12.0, left: 4.0, right: 4.0),
                          child: Text(
                            vault.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (vault.isPinned)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Icon(Icons.push_pin, size: 14, color: color),
                      ),
                    if (hasPassword)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Icon(Icons.lock, size: 12, color: color),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
