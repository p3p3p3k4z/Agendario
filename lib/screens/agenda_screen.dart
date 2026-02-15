import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/journal_provider.dart';
import '../models/entities/journal_entry.dart';
import '../models/enums/entry_type.dart';
import '../config/theme.dart';
import '../widgets/day_entry_tile.dart';
import '../widgets/calendar_cell_builder.dart';
import 'event_editor_screen.dart';

// pantalla principal del modulo agenda: combina un calendario mensual
// interactivo con una lista de entradas del dia seleccionado debajo
// consumer escucha cambios en el provider para actualizar ambas vistas
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  // formato actual del calendario: mes, dos semanas, o semana
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // dia con foco visual (outline) controlado por table_calendar
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final selectedDay = provider.selectedDate;
        final dayEntries = provider.dayEntries;

        // separa las entradas del dia por tipo para agrupar visualmente
        final events = dayEntries
            .where((e) => e.type == EntryType.event)
            .toList();
        final todos = dayEntries
            .where((e) => e.type == EntryType.todo)
            .toList();
        final reminders = dayEntries
            .where((e) => e.type == EntryType.reminder)
            .toList();
        final notes = dayEntries
            .where(
              (e) => e.type == EntryType.note || e.type == EntryType.journal,
            )
            .toList();

        return Column(
          children: [
            // --- calendario mensual ---
            _buildCalendar(provider, selectedDay),
            const SizedBox(height: 8),
            // --- lista de entradas del dia ---
            Expanded(
              child: dayEntries.isEmpty
                  ? _buildEmptyDay(selectedDay)
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // secciones ordenadas: eventos primero por relevancia temporal
                        if (events.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Eventos',
                            Icons.event,
                            GruvboxColors.blue,
                            events.length,
                          ),
                          ...events.map((e) => _buildTile(e, provider)),
                        ],
                        if (todos.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Pendientes',
                            Icons.check_circle_outline,
                            GruvboxColors.green,
                            todos.length,
                          ),
                          ...todos.map((e) => _buildTile(e, provider)),
                        ],
                        if (reminders.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Recordatorios',
                            Icons.notifications_outlined,
                            GruvboxColors.purple,
                            reminders.length,
                          ),
                          ...reminders.map((e) => _buildTile(e, provider)),
                        ],
                        if (notes.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Notas',
                            Icons.note_outlined,
                            GruvboxColors.yellow,
                            notes.length,
                          ),
                          ...notes.map((e) => _buildTile(e, provider)),
                        ],
                        const SizedBox(height: 80), // espacio para el FAB
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  // construye el calendario con table_calendar y celdas personalizadas
  Widget _buildCalendar(JournalProvider provider, DateTime selectedDay) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GruvboxColors.bg0.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<JournalEntry>(
        // rango permitido de navegacion
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        locale: 'es_ES',
        startingDayOfWeek: StartingDayOfWeek.monday,

        // seleccion de dia: compara solo fecha sin hora
        selectedDayPredicate: (day) => isSameDay(day, selectedDay),
        onDaySelected: (selected, focused) {
          provider.selectDate(selected);
          setState(() => _focusedDay = focused);
        },

        // cuando el usuario hace swipe a otro mes, recarga entradas
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          provider.loadMonth(focusedDay);
        },

        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },

        // alimenta los marcadores: convierte el mapa del provider en eventos por dia
        eventLoader: (day) {
          final key = DateTime(day.year, day.month, day.day);
          return provider.monthEntries[key] ?? [];
        },

        // --- estilo visual personalizado con gruvbox ---
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(color: GruvboxColors.orange),
            ),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          formatButtonTextStyle: TextStyle(
            color: GruvboxColors.orange,
            fontSize: 12,
          ),
          titleTextStyle: TextStyle(
            color: GruvboxColors.bg0,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: GruvboxColors.orange,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: GruvboxColors.orange,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: GruvboxColors.bg1,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: GruvboxColors.red,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        // usa el CalendarCellBuilder custom para celdas con stickers y dots
        calendarBuilders: CalendarBuilders<JournalEntry>(
          defaultBuilder: (context, day, focusedDay) {
            final key = DateTime(day.year, day.month, day.day);
            return CalendarCellBuilder(
              day: day,
              isSelected: false,
              isToday: false,
              entries: provider.monthEntries[key],
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            final key = DateTime(day.year, day.month, day.day);
            return CalendarCellBuilder(
              day: day,
              isSelected: true,
              isToday: isSameDay(day, DateTime.now()),
              entries: provider.monthEntries[key],
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final key = DateTime(day.year, day.month, day.day);
            return CalendarCellBuilder(
              day: day,
              isSelected: isSameDay(day, selectedDay),
              isToday: true,
              entries: provider.monthEntries[key],
            );
          },
          // oculta los marcadores default porque ya pintamos dots en el cell builder
          markerBuilder: (context, day, events) => const SizedBox.shrink(),
        ),

        // estilo minimo para dejar que el cell builder controle la apariencia
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: EdgeInsets.all(2),
        ),
      ),
    );
  }

  // tile individual con callbacks conectados al provider
  Widget _buildTile(JournalEntry entry, JournalProvider provider) {
    return DayEntryTile(
      entry: entry,
      onToggleCompleted: () => provider.toggleTodoCompleted(entry.id),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventEditorScreen(entry: entry)),
      ),
      onDismissed: () => provider.deleteEntry(entry.id),
    );
  }

  // header de seccion con icono, titulo y contador
  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // estado vacio: sugiere al usuario crear algo en el dia
  Widget _buildEmptyDay(DateTime date) {
    final formatter = DateFormat.MMMEd('es');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 48,
            color: GruvboxColors.yellow.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Nada para ${formatter.format(date)}',
            style: TextStyle(fontSize: 16, color: GruvboxColors.bg1),
          ),
          const SizedBox(height: 4),
          Text(
            'Toca + para agregar algo',
            style: TextStyle(
              fontSize: 13,
              color: GruvboxColors.bg1.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
