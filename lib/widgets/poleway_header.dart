import 'package:flutter/material.dart';
import '../theme.dart';

/// AppBar com fundo em degradê laranja e a logo centralizada.
/// A logo tem "way" escrito em branco, então precisa de um fundo colorido
/// atrás dela para não sumir — o degradê cumpre esse papel.
class PolewayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;

  const PolewayAppBar({super.key, this.leading, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AppBar(
      leading: leading,
      actions: actions,
      centerTitle: true,
      title: Image.asset('assets/poleway.png', height: 26, fit: BoxFit.contain),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.laranja, const Color(0xFFB94E1F)],
          ),
        ),
      ),
      elevation: 0,
    );
  }
}
