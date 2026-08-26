import 'package:flutter/material.dart';

class AppPalette {
  final Color laranja;
  final Color laranjaClaro;
  final Color laranjaSuave;
  final Color fundo;
  final Color superficie;
  final Color borda;
  final Color texto;
  final Color textoSuave;
  final Color verde;
  final Color vermelho;
  final Color azul;

  const AppPalette({
    required this.laranja,
    required this.laranjaClaro,
    required this.laranjaSuave,
    required this.fundo,
    required this.superficie,
    required this.borda,
    required this.texto,
    required this.textoSuave,
    required this.verde,
    required this.vermelho,
    required this.azul,
  });

  static const light = AppPalette(
    laranja: Color(0xFFFF7A33),
    laranjaClaro: Color(0xFFFFE8DA),
    laranjaSuave: Color(0xFFFFF3EC),
    fundo: Color(0xFFFAFAFA),
    superficie: Colors.white,
    borda: Color(0x0F000000),
    texto: Color(0xFF2E2A27),
    textoSuave: Color(0xFF8A8480),
    verde: Color(0xFF4CAF7D),
    vermelho: Color(0xFFE0644B),
    azul: Color(0xFF5B8DEF),
  );

  static const dark = AppPalette(
    laranja: Color(0xFFFF9257),
    laranjaClaro: Color(0xFF3D2A1E),
    laranjaSuave: Color(0xFF2E2119),
    fundo: Color(0xFF17151A),
    superficie: Color(0xFF211F24),
    borda: Color(0x1FFFFFFF),
    texto: Color(0xFFF3F1EE),
    textoSuave: Color(0xFF9C97A0),
    verde: Color(0xFF6BC998),
    vermelho: Color(0xFFE8836C),
    azul: Color(0xFF7DA3F5),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

ThemeData buildPolewayTheme(AppPalette p, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: p.fundo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.laranja,
      primary: p.laranja,
      surface: p.superficie,
      brightness: brightness,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.superficie,
      foregroundColor: p.texto,
      elevation: 0,
      surfaceTintColor: p.superficie,
    ),
    cardTheme: CardThemeData(
      color: p.superficie,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.borda),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: p.texto),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: p.texto),
      bodyMedium: TextStyle(color: p.texto),
      bodySmall: TextStyle(color: p.textoSuave),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.superficie,
      surfaceTintColor: p.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

ThemeData buildPolewayLightTheme() => buildPolewayTheme(AppPalette.light, Brightness.light);
ThemeData buildPolewayDarkTheme() => buildPolewayTheme(AppPalette.dark, Brightness.dark);
