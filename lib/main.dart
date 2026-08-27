import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/selecionar_cliente_screen.dart';

void main() {
  runApp(const PolewayApp());
}

class PolewayApp extends StatefulWidget {
  const PolewayApp({super.key});

  @override
  State<PolewayApp> createState() => _PolewayAppState();
}

class _PolewayAppState extends State<PolewayApp> {
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Pole Way',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: buildPolewayLightTheme(),
          darkTheme: buildPolewayDarkTheme(),
          home: SelecionarClienteScreen(themeMode: themeMode),
        );
      },
    );
  }
}
