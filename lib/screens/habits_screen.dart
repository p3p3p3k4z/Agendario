import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../providers/theme_provider.dart';
import 'habit_detail_screen.dart';
import 'habit_editor_screen.dart';

// lista de habitos con progreso del dia
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        if (provider.habits.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 80),
          itemCount: provider.habits.length + 1, // +1 para el header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildDaySummary(context, provider);
            }
            final habit = provider.habits[index - 1];
            final todayValue = provider.todayRecords[habit.uuid];
            return HabitCard(
              habit: habit,
              todayValue: todayValue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HabitDetailScreen(habit: habit),
                ),
              ),
              onRecord: (value) {
                provider.recordHabit(habit.uuid, value);
                provider.invalidateCache(habit.uuid);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDaySummary(BuildContext context, HabitProvider provider) {
    final total = provider.habits.length;
    final completed = provider.habits
        .where((h) => provider.todayRecords.containsKey(h.uuid))
        .length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.theme.green.withValues(alpha: 0.08),
            context.theme.aqua.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.theme.green.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // progreso circular grande
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: context.theme.bg1.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(context.theme.green),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.theme.green,
                ),
              ),
            ],
          ),
          SizedBox(width: 20),
          // texto resumen
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso de hoy',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.theme.fg0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$completed de $total hábitos registrados',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.theme.fg1.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 80,
            color: context.theme.green.withValues(alpha: 0.3),
          ),
          SizedBox(height: 24),
          Text(
            '¡Crea tu primer hábito!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.theme.fg0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Empieza a trackear lo que importa',
            style: TextStyle(
              fontSize: 14,
              color: context.theme.fg1.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HabitEditorScreen()),
            ),
            icon: Icon(Icons.add),
            label: Text('Nuevo Hábito'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.green,
              foregroundColor: context.theme.bg0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
