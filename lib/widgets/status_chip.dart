import 'package:flutter/material.dart';
import '../theme.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  Color _cor(AppPalette p) {
    switch (status.toLowerCase()) {
      case 'faturado':
        return p.verde;
      case 'recusado':
        return p.vermelho;
      case 'em andamento':
        return p.laranja;
      default:
        return p.azul;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final cor = _cor(p);
    final label = status.isEmpty ? 'Sem status' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
