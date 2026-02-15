import 'package:flutter/material.dart';

class GruvboxColors {
  static const Color bg0 = Color(0xFF282828);
  static const Color bg1 = Color(0xFF3C3836);
  static const Color bg_soft = Colors.white;
  static const Color fg0 = Color(0xFF282828);
  static const Color fg1 = Color(0xFF3C3836);
  static const Color red = Color(0xFFCC241D);
  static const Color green = Color(0xFF98971A);
  static const Color yellow = Color(0xFFD79921);
  static const Color blue = Color(0xFF458588);
  static const Color purple = Color(0xFFB16286);
  static const Color aqua = Color(0xFF689D6A);
  static const Color orange = Color(0xFFD65D0E);
}

// construye el themedata global, orange como color semilla para que
// material3 genere variantes automaticas coherentes con la identidad
ThemeData gruvboxTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: GruvboxColors.orange,
      primary: GruvboxColors.orange,
      secondary: GruvboxColors.yellow,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: GruvboxColors.bg0),
      titleTextStyle: TextStyle(
        color: GruvboxColors.bg0,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: GruvboxColors.bg0),
      bodyMedium: TextStyle(color: GruvboxColors.bg0),
    ),
  );
}
