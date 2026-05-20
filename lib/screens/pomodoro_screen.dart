import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../models/entities/habit_definition.dart';
import '../models/enums/habit_type.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  // Timer states
  int _workMinutes = 25;
  int _breakMinutes = 5;
  
  bool _isWorking = true;
  bool _isRunning = false;
  int _secondsRemaining = 25 * 60;
  Timer? _timer;

  HabitDefinition? _selectedHabit;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = (_isWorking ? _workMinutes : _breakMinutes) * 60;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _completeOrSkip();
        }
      });
    }
  }

  void _completeOrSkip({bool isManualStop = false, bool isSkip = false}) {
    _timer?.cancel();
    setState(() => _isRunning = false);
    
    final totalSeconds = (_isWorking ? _workMinutes : _breakMinutes) * 60;
    final elapsedSeconds = totalSeconds - _secondsRemaining;
    
    // Si fue manual, calcula lo que ha transcurrido. Si fue automático o skip, asume el tiempo completo (o calcula igual)
    int elapsedMinutes;
    if (isManualStop) {
      elapsedMinutes = (elapsedSeconds / 60).round();
    } else {
      elapsedMinutes = _workMinutes;
    }
    
    if (_isWorking && _selectedHabit != null && elapsedMinutes > 0) {
      // Registrar tiempo en el hábito
      final provider = context.read<HabitProvider>();
      final currentValue = provider.todayRecords[_selectedHabit!.uuid] ?? 0.0;
      provider.recordHabit(
        _selectedHabit!.uuid,
        currentValue + elapsedMinutes.toDouble(),
      );
      provider.invalidateCache(_selectedHabit!.uuid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡$elapsedMinutes minutos registrados en ${_selectedHabit!.title}!'),
          backgroundColor: context.theme.green,
        ),
      );
    }
    
    // Cambiar de modo si se completó o skipeó. Si se detuvo manualmente, reiniciar.
    setState(() {
      if (isManualStop) {
        _isWorking = true;
      } else {
        _isWorking = !_isWorking;
      }
      _resetTimer();
    });
  }

  String get _timerDisplay {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showSettingsDialog() {
    final workCtrl = TextEditingController(text: _workMinutes.toString());
    final breakCtrl = TextEditingController(text: _breakMinutes.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.theme.bg1,
        title: Text('Configurar Pomodoro', style: TextStyle(color: ctx.theme.fg0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: workCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: ctx.theme.fg0),
              decoration: InputDecoration(
                labelText: 'Tiempo de trabajo (min)',
                labelStyle: TextStyle(color: ctx.theme.fg1),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: breakCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: ctx.theme.fg0),
              decoration: InputDecoration(
                labelText: 'Tiempo de descanso (min)',
                labelStyle: TextStyle(color: ctx.theme.fg1),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: ctx.theme.fg1)),
          ),
          TextButton(
            onPressed: () {
              final w = int.tryParse(workCtrl.text) ?? 25;
              final b = int.tryParse(breakCtrl.text) ?? 5;
              setState(() {
                _workMinutes = w > 0 ? w : 1;
                _breakMinutes = b > 0 ? b : 1;
              });
              _resetTimer();
              Navigator.pop(ctx);
            },
            child: Text('Guardar', style: TextStyle(color: ctx.theme.orange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _isWorking ? context.theme.orange : context.theme.aqua;
    final habits = context.watch<HabitProvider>().habits.where(
      (h) => h.type == HabitType.time || h.type == HabitType.counter
    ).toList();

    return Scaffold(
      backgroundColor: context.theme.bg0,
      appBar: AppBar(
        title: Text(
          'Pomodoro',
          style: TextStyle(color: context.theme.fg0, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.theme.bg0,
        elevation: 0,
        iconTheme: IconThemeData(color: context.theme.fg0),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: context.theme.fg1),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Modo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _isWorking ? 'TIEMPO DE TRABAJO' : 'DESCANSO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Temporizador
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: _secondsRemaining / ((_isWorking ? _workMinutes : _breakMinutes) * 60),
                      strokeWidth: 12,
                      backgroundColor: context.theme.bg1,
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                    ),
                  ),
                  Text(
                    _timerDisplay,
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: context.theme.fg0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Controles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => _completeOrSkip(isManualStop: true),
                        icon: Icon(Icons.stop, size: 32),
                        color: context.theme.red.withValues(alpha: 0.8),
                      ),
                      Text('Terminar', style: TextStyle(color: context.theme.fg1, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: _toggleTimer,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => _completeOrSkip(isSkip: true),
                        icon: Icon(Icons.skip_next, size: 32),
                        color: context.theme.fg1,
                      ),
                      Text('Saltar', style: TextStyle(color: context.theme.fg1, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Selección de hábito
              if (_isWorking)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.theme.bg1,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<HabitDefinition?>(
                      value: _selectedHabit,
                      hint: Text('Asignar tiempo a un hábito...', style: TextStyle(color: context.theme.fg1)),
                      isExpanded: true,
                      dropdownColor: context.theme.bg1,
                      icon: Icon(Icons.keyboard_arrow_down, color: context.theme.fg1),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Sin asignar', style: TextStyle(color: context.theme.fg1)),
                        ),
                        ...habits.map((h) => DropdownMenuItem(
                          value: h,
                          child: Text(h.title, style: TextStyle(color: context.theme.fg0)),
                        )),
                      ],
                      onChanged: (val) => setState(() => _selectedHabit = val),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
