import 'package:flutter/material.dart';

enum ThemeType { gruvbox, solarized, nord, dracula, tokyioNight, oled }

abstract class AppColors {
  // Backgrounds
  Color get bg0; // Background base (Scaffolds)
  Color get bg1; // Background surface (Cards, Dialogs)
  Color get bgSoft; // Soft background (Highlights)

  // Foregrounds
  Color get fg0; // Primary Text
  Color get fg1; // Secondary Text (Subtitles)

  // Accents / Semantics
  Color get red;
  Color get green;
  Color get yellow;
  Color get blue;
  Color get purple;
  Color get aqua;
  Color get orange;
}

// ----------------------------------------------------
// 1. Gruvbox (Warm, Retro, Earthy)
// ----------------------------------------------------
class GruvboxDarkColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFF282828);
  @override
  Color get bg1 => const Color(0xFF3C3836);
  @override
  Color get bgSoft => const Color(0xFF504945);
  @override
  Color get fg0 => const Color(0xFFEBDBB2);
  @override
  Color get fg1 => const Color(0xFFA89984);
  @override
  Color get red => const Color(0xFFCC241D);
  @override
  Color get green => const Color(0xFF98971A);
  @override
  Color get yellow => const Color(0xFFD79921);
  @override
  Color get blue => const Color(0xFF458588);
  @override
  Color get purple => const Color(0xFFB16286);
  @override
  Color get aqua => const Color(0xFF689D6A);
  @override
  Color get orange => const Color(0xFFD65D0E);
}

class GruvboxLightColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFFFBF1C7);
  @override
  Color get bg1 => const Color(0xFFEBDBB2);
  @override
  Color get bgSoft => const Color(0xFFD5C4A1);
  @override
  Color get fg0 => const Color(0xFF3C3836);
  @override
  Color get fg1 => const Color(0xFF7C6F64);
  @override
  Color get red => const Color(0xFF9D0006);
  @override
  Color get green => const Color(0xFF79740E);
  @override
  Color get yellow => const Color(0xFFB57614);
  @override
  Color get blue => const Color(0xFF076678);
  @override
  Color get purple => const Color(0xFF8F3F71);
  @override
  Color get aqua => const Color(0xFF427B58);
  @override
  Color get orange => const Color(0xFFAF3A03);
}

// ----------------------------------------------------
// 2. Solarized (Iconic Unix beige/teal contrast)
// ----------------------------------------------------
class SolarizedDarkColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFF002b36); // base03
  @override
  Color get bg1 => const Color(0xFF073642); // base02
  @override
  Color get bgSoft => const Color(0xFF586e75); // base01
  @override
  Color get fg0 => const Color(0xFF839496); // base0
  @override
  Color get fg1 => const Color(0xFF93a1a1); // base1
  @override
  Color get red => const Color(0xFFdc322f); // red
  @override
  Color get green => const Color(0xFF859900); // green
  @override
  Color get yellow => const Color(0xFFb58900); // yellow
  @override
  Color get blue => const Color(0xFF268bd2); // blue
  @override
  Color get purple => const Color(0xFFd33682); // magenta
  @override
  Color get aqua => const Color(0xFF2aa198); // cyan
  @override
  Color get orange => const Color(0xFFcb4b16); // orange
}

class SolarizedLightColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFFfdf6e3); // base3
  @override
  Color get bg1 => const Color(0xFFeee8d5); // base2
  @override
  Color get bgSoft => const Color(0xFF93a1a1); // base1
  @override
  Color get fg0 => const Color(0xFF657b83); // base00
  @override
  Color get fg1 => const Color(0xFF586e75); // base01
  @override
  Color get red => const Color(0xFFdc322f); // red
  @override
  Color get green => const Color(0xFF859900); // green
  @override
  Color get yellow => const Color(0xFFb58900); // yellow
  @override
  Color get blue => const Color(0xFF268bd2); // blue
  @override
  Color get purple => const Color(0xFFd33682); // magenta
  @override
  Color get aqua => const Color(0xFF2aa198); // cyan
  @override
  Color get orange => const Color(0xFFcb4b16); // orange
}

// ----------------------------------------------------
// 3. Nord (Arctic, Frosty & Minimal)
// ----------------------------------------------------
class NordDarkColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFF2E3440); // Polar Night
  @override
  Color get bg1 => const Color(0xFF3B4252);
  @override
  Color get bgSoft => const Color(0xFF4C566A);
  @override
  Color get fg0 => const Color(0xFFD8DEE9); // Snow Storm Text
  @override
  Color get fg1 => const Color(0xFFE5E9F0);
  @override
  Color get red => const Color(0xFFBF616A); // Aurora Red
  @override
  Color get green => const Color(0xFFA3BE8C); // Aurora Green
  @override
  Color get yellow => const Color(0xFFEBCB8B); // Aurora Yellow
  @override
  Color get blue => const Color(0xFF81A1C1); // Frost Blue
  @override
  Color get purple => const Color(0xFFB48EAD); // Aurora Purple
  @override
  Color get aqua => const Color(0xFF88C0D0); // Frost Aqua
  @override
  Color get orange => const Color(0xFFD08770); // Aurora Orange
}

class NordLightColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFFECEFF4); // Snow Storm Lightest
  @override
  Color get bg1 => const Color(0xFFE5E9F0);
  @override
  Color get bgSoft => const Color(0xFFD8DEE9);
  @override
  Color get fg0 => const Color(0xFF2E3440); // Polar Night Darkest Text
  @override
  Color get fg1 => const Color(0xFF3B4252);
  @override
  Color get red => const Color(0xFFBF616A);
  @override
  Color get green => const Color(0xFFA3BE8C);
  @override
  Color get yellow => const Color(0xFFD08770);
  @override
  Color get blue => const Color(0xFF5E81AC); // Frost Dark Blue
  @override
  Color get purple => const Color(0xFFB48EAD);
  @override
  Color get aqua => const Color(0xFF8FBCBB);
  @override
  Color get orange => const Color(0xFFD08770);
}

// ----------------------------------------------------
// 4. Dracula (Vibrant Neons & Deep Purple Backing)
// ----------------------------------------------------
class DraculaDarkColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFF282A36); // Very Dark Purple/Grey
  @override
  Color get bg1 => const Color(0xFF44475A); // Soft Purple Grey
  @override
  Color get bgSoft => const Color(0xFF6272A4);
  @override
  Color get fg0 => const Color(0xFFF8F8F2); // Off white
  @override
  Color get fg1 => const Color(0xFFF1FA8C); // Pastel Yellow for subs
  @override
  Color get red => const Color(0xFFFF5555); // Neon Red
  @override
  Color get green => const Color(0xFF50FA7B); // Neon Green
  @override
  Color get yellow => const Color(0xFFF1FA8C); // Neon Yellow
  @override
  Color get blue => const Color(0xFF8BE9FD); // Neon Cyan
  @override
  Color get purple => const Color(0xFFBD93F9); // Neon Purple
  @override
  Color get aqua => const Color(0xFF8BE9FD); // Cyan
  @override
  Color get orange => const Color(0xFFFFB86C); // Neon Orange
}

class DraculaLightColors implements AppColors {
  // "Alucard"
  @override
  Color get bg0 => const Color(0xFFF8F8F2); // Off white background
  @override
  Color get bg1 => const Color(0xFFE9E9E4);
  @override
  Color get bgSoft => const Color(0xFFD4D4CE);
  @override
  Color get fg0 => const Color(0xFF282A36); // Dark purple text
  @override
  Color get fg1 => const Color(0xFF6272A4);
  @override
  Color get red => const Color(0xFFFF5555);
  @override
  Color get green => const Color(0xFF2CA051); // Darker Green
  @override
  Color get yellow => const Color(0xFFE8CA0C);
  @override
  Color get blue => const Color(0xFF00BBE2);
  @override
  Color get purple => const Color(0xFF914BFF);
  @override
  Color get aqua => const Color(0xFF00BBE2);
  @override
  Color get orange => const Color(0xFFFF951C);
}

// ----------------------------------------------------
// 5. Tokyo Night (Deep Blue & Bright Cyberpunk Colors)
// ----------------------------------------------------
class TokyoNightDarkColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFF1a1b26); // Deep space blue
  @override
  Color get bg1 => const Color(0xFF24283b); // Slightly lighter
  @override
  Color get bgSoft => const Color(0xFF414868);
  @override
  Color get fg0 => const Color(0xFFc0caf5); // Cyan-tinted grey
  @override
  Color get fg1 => const Color(0xFFa9b1d6); // Darker text
  @override
  Color get red => const Color(0xFFf7768e); // Pink-red
  @override
  Color get green => const Color(0xFF9ece6a); // Acid green
  @override
  Color get yellow => const Color(0xFFe0af68); // Soft orange-yellow
  @override
  Color get blue => const Color(0xFF7aa2f7); // Sky blue
  @override
  Color get purple => const Color(0xFFbb9af7); // Lavender purple
  @override
  Color get aqua => const Color(0xFF7dcfff); // Cyan
  @override
  Color get orange => const Color(0xFFff9e64); // Bright orange
}

class TokyoNightLightColors implements AppColors {
  // "Tokyo Night Day"
  @override
  Color get bg0 => const Color(0xFFd5d6db); // Ash grey-white
  @override
  Color get bg1 => const Color(0xFFcbccd1);
  @override
  Color get bgSoft => const Color(0xFF9699a3); // Muted dark grey
  @override
  Color get fg0 => const Color(0xFF343b58); // Dark navy text
  @override
  Color get fg1 => const Color(0xFF565f89);
  @override
  Color get red => const Color(0xFFf52a65); // Bright pink-red
  @override
  Color get green => const Color(0xFF587539); // Forest green
  @override
  Color get yellow => const Color(0xFF8c6c3e); // Brown-yellow
  @override
  Color get blue => const Color(0xFF2e7de9); // Deep blue
  @override
  Color get purple => const Color(0xFF9854f1); // Strong purple
  @override
  Color get aqua => const Color(0xFF007197); // Deep cyan
  @override
  Color get orange => const Color(0xFFb15c00); // Burnt orange
}

// ----------------------------------------------------
// 6. OLED / Paper (100% White/Black + Vibrant Neons)
// ----------------------------------------------------
class OledDarkColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFF000000); // Pure Black
  @override
  Color get bg1 => const Color(0xFF000000);
  @override
  Color get bgSoft => const Color(0xFF000000);
  @override
  Color get fg0 => const Color(0xFFFFFFFF); // Pure White
  @override
  Color get fg1 => const Color(0xFFAAAAAA);

  // Vibrant Neon Accents
  @override
  Color get red => const Color(0xFFFF003C);
  @override
  Color get green => const Color(0xFF00FF66);
  @override
  Color get yellow => const Color(0xFFFFD500);
  @override
  Color get blue => const Color(0xFF00E5FF);
  @override
  Color get purple => const Color(0xFFD500F9);
  @override
  Color get aqua => const Color(0xFF00E5FF);
  @override
  Color get orange => const Color(0xFFFF3D00);
}

class PaperLightColors implements AppColors {
  @override
  Color get bg0 => const Color(0xFFFFFFFF); // Pure White
  @override
  Color get bg1 => const Color(0xFFFFFFFF);
  @override
  Color get bgSoft => const Color(0xFFFFFFFF);
  @override
  Color get fg0 => const Color(0xFF000000); // Pure Black
  @override
  Color get fg1 => const Color(0xFF555555);

  // Vibrant Flat Accents
  @override
  Color get red => const Color(0xFFD50000);
  @override
  Color get green => const Color(0xFF00C853);
  @override
  Color get yellow => const Color(0xFFFFAB00);
  @override
  Color get blue => const Color(0xFF2962FF);
  @override
  Color get purple => const Color(0xFFAA00FF);
  @override
  Color get aqua => const Color(0xFF00B8D4);
  @override
  Color get orange => const Color(0xFFFF6D00);
}
