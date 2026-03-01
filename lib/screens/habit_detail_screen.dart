import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entities/habit_definition.dart';
import '../models/enums/habit_type.dart';
import '../models/achievement.dart';
import '../providers/habit_provider.dart';
import '../widgets/stats_chart.dart';
import '../widgets/achievement_badge.dart';
import '../providers/theme_provider.dart';

// graficas, estadisticas y logros
class HabitDetailScreen extends StatefulWidget {
  final HabitDefinition habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  HabitStats? _stats;
  List<Achievement>? _achievements;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<HabitProvider>();
    final stats = await provider.refreshStats(widget.habit.uuid);
    final achievements = await provider.getAchievements(widget.habit.uuid);
    if (mounted) {
      setState(() {
        _stats = stats;
        _achievements = achievements;
        _loading = false;
      });
    }
  }

  Color get _habitColor {
    switch (widget.habit.type) {
      case HabitType.boolean:
        return context.theme.green;
      case HabitType.counter:
        return context.theme.blue;
      case HabitType.scale_1_5:
        return context.theme.purple;
      case HabitType.time:
        return context.theme.aqua;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.habit.iconCodePoint != null
        ? IconData(widget.habit.iconCodePoint!, fontFamily: 'MaterialIcons')
        : Icons.check_circle_outline;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.title),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.theme.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(icon),
                  SizedBox(height: 24),

                  // cards de estadisticas rapidas
                  _buildStatsCards(),
                  SizedBox(height: 24),

                  // grafica de linea
                  _buildSection('Últimos 30 días', _buildLineChart()),
                  SizedBox(height: 24),

                  // grafica de barras
                  _buildSection('Promedio semanal', _buildBarChart()),
                  SizedBox(height: 24),

                  _buildSection('Logros', _buildAchievements()),
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _habitColor.withValues(alpha: 0.08),
            _habitColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _habitColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: _habitColor),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.habit.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.theme.fg0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _typeLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    color: context.theme.fg1.withValues(alpha: 0.6),
                  ),
                ),
                if (widget.habit.goal != null)
                  Text(
                    'Meta: ${widget.habit.goal!.toInt()} diario',
                    style: TextStyle(
                      fontSize: 13,
                      color: _habitColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        _statCard(
          '🔥',
          '${_stats?.currentStreak ?? 0}',
          'Racha actual',
          context.theme.orange,
        ),
        SizedBox(width: 12),
        _statCard(
          '⭐',
          '${_stats?.bestStreak ?? 0}',
          'Mejor racha',
          context.theme.yellow,
        ),
        SizedBox(width: 12),
        _statCard(
          '📊',
          '${((_stats?.completionRate ?? 0) * 100).toInt()}%',
          'Cumplimiento',
          context.theme.blue,
        ),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 24)),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.theme.fg1.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.theme.fg0,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.theme.bg1,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    return StatsLineChart(
      values: _stats?.dailyValues ?? [],
      color: _habitColor,
      goal: widget.habit.goal,
    );
  }

  Widget _buildBarChart() {
    return StatsBarChart(
      weeklyAverages: _stats?.weeklyAverages ?? [],
      color: _habitColor,
    );
  }

  Widget _buildAchievements() {
    if (_achievements == null || _achievements!.isEmpty) {
      return Center(child: Text('Sin logros disponibles'));
    }
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: _achievements!
          .map((a) => AchievementBadge(achievement: a))
          .toList(),
    );
  }

  String _typeLabel() {
    switch (widget.habit.type) {
      case HabitType.boolean:
        return 'Sí / No';
      case HabitType.counter:
        return 'Contador';
      case HabitType.scale_1_5:
        return 'Escala 1-5';
      case HabitType.time:
        return 'Tiempo (minutos)';
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar hábito'),
        content: Text(
          '¿Eliminar "${widget.habit.title}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.theme.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<HabitProvider>().deleteHabit(widget.habit.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
