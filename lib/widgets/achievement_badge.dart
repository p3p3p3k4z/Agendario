import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../providers/theme_provider.dart';

// badge circular para mostrar logros/medallas
// cuando esta bloqueado muestra icono gris y aspecto apagado
// cuando esta desbloqueado muestra color + brillo sutil
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked
                ? achievement.color.withValues(alpha: 0.15)
                : context.theme.bg1.withValues(alpha: 0.08),
            border: Border.all(
              color: unlocked
                  ? achievement.color
                  : context.theme.bg1.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: achievement.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            achievement.icon,
            size: 28,
            color: unlocked
                ? achievement.color
                : context.theme.bg1.withValues(alpha: 0.3),
          ),
        ),
        SizedBox(height: 8),
        Text(
          achievement.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: unlocked
                ? context.theme.bg0
                : context.theme.bg1.withValues(alpha: 0.4),
          ),
        ),
        Text(
          achievement.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: context.theme.fg1.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
