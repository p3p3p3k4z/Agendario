import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';

extension ThemeContextExtension on BuildContext {
  // Atajo magico: context.theme.bg0 en cualquier lugar de la app
  // Este getter ESCUCHA cambios (ideal para build)
  AppColors get theme => Provider.of<ThemeProvider>(this).colors;

  // Atajo para lectura puntual sin suscripcion (ideal para event handlers)
  AppColors get readTheme => Provider.of<ThemeProvider>(this, listen: false).colors;
}

class ThemeProvider extends ChangeNotifier {
  static const String keyThemeType = 'agendario_theme_type';
  static const String keyThemeMode = 'agendario_theme_mode';

  ThemeType _themeType = ThemeType.oled;
  ThemeMode _themeMode = ThemeMode.dark;
  late final SharedPreferences _prefs;

  ThemeType get themeType => _themeType;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider(this._prefs) {
    _loadFromPrefs();
  }

  static ThemeProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<ThemeProvider>(context, listen: listen);
  }

  void _loadFromPrefs() {
    final tIdx = _prefs.getInt(keyThemeType) ?? ThemeType.oled.index;
    final mIdx = _prefs.getInt(keyThemeMode) ?? ThemeMode.dark.index;

    // Fallbacks de seguridad
    _themeType = ThemeType.values.elementAt(
      tIdx < ThemeType.values.length ? tIdx : 0,
    );
    _themeMode = ThemeMode.values.elementAt(
      mIdx < ThemeMode.values.length ? mIdx : 2,
    ); // default oscuro si falla
  }

  Future<void> setThemeType(ThemeType type) async {
    _themeType = type;
    await _prefs.setInt(keyThemeType, type.index);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(keyThemeMode, mode.index);
    notifyListeners();
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Ignorando el modo del sistema y asumiendo oscuro de forma predeterminada para el setup original temporalmente
      // idealmente, esto se leería de MediaQueryData.fromView(view).platformBrightness
      return true;
    }
    return _themeMode == ThemeMode.dark;
  }

  AppColors get colors {
    switch (_themeType) {
      case ThemeType.gruvbox:
        return isDarkMode ? GruvboxDarkColors() : GruvboxLightColors();
      case ThemeType.solarized:
        return isDarkMode ? SolarizedDarkColors() : SolarizedLightColors();
      case ThemeType.nord:
        return isDarkMode ? NordDarkColors() : NordLightColors();
      case ThemeType.dracula:
        return isDarkMode ? DraculaDarkColors() : DraculaLightColors();
      case ThemeType.tokyioNight:
        return isDarkMode ? TokyoNightDarkColors() : TokyoNightLightColors();
      case ThemeType.oled:
        return isDarkMode ? OledDarkColors() : PaperLightColors();
    }
  }
}
