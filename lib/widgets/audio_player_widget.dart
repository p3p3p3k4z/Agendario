import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/theme_provider.dart';

// Genera un componente de barra horizontal (tipo Whatsapp) interactivo
// capaz de cargar y parsear una pista de audio incrustrada en la nota local.
class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final VoidCallback onDelete;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    required this.onDelete,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isFileValid = true;
  bool _isSupported = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isLinux || Platform.isWindows) {
      _isSupported = false;
    } else {
      _player = AudioPlayer();
      _initAudio();
    }
  }

  Future<void> _initAudio() async {
    try {
      if (!File(widget.audioPath).existsSync()) {
        setState(() => _isFileValid = false);
        return;
      }

      await _player!.setFilePath(widget.audioPath);

      _player!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            // Si llego al final, resetear
            if (state.processingState == ProcessingState.completed) {
              _player!.seek(Duration.zero);
              _player!.pause();
            }
          });
        }
      });

      _player!.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });

      _player!.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
    } catch (e) {
      setState(() => _isFileValid = false);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_player == null) return;
    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60);
    final minutes = duration.inMinutes;
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFileValid) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.theme.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.broken_image, color: context.theme.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Archivo de audio extraviado o corrupto.',
                style: TextStyle(color: context.theme.fg0),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: context.theme.fg1),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      );
    }

    if (!_isSupported) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.theme.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.theme.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.desktop_access_disabled, color: context.theme.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Audio no sportado en PC (Linux).',
                style: TextStyle(color: context.theme.fg0),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: context.theme.fg1),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.theme.bg1,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: context.theme.fg1.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _togglePlay,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: context.theme.blue,
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: context.theme.bg0,
              ),
            ),
          ),
          SizedBox(width: 8),

          // Times
          Text(
            _formatTime(_position),
            style: TextStyle(fontSize: 12, color: context.theme.fg1),
          ),

          // Progress Slider
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: context.theme.blue,
                inactiveTrackColor: context.theme.blue.withValues(alpha: 0.2),
                thumbColor: context.theme.blue,
              ),
              child: Slider(
                min: 0,
                max: _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 100,
                value: _position.inMilliseconds
                    .clamp(0, _duration.inMilliseconds)
                    .toDouble(),
                onChanged: (v) {
                  _player!.seek(Duration(milliseconds: v.toInt()));
                },
              ),
            ),
          ),

          Text(
            _formatTime(_duration),
            style: TextStyle(fontSize: 12, color: context.theme.fg1),
          ),

          // Delete Track Action
          IconButton(
            icon: Icon(Icons.close, color: context.theme.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              _player?.stop();
              widget.onDelete();
            },
          ),
        ],
      ),
    );
  }
}
