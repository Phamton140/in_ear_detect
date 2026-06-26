import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/audio_service.dart';
import '../detection/pitch_detector.dart';
import '../detection/note_utils.dart';
import '../detection/key_detector.dart';
import '../widgets/note_display.dart';
import '../widgets/chromatic_indicator.dart';
import '../widgets/key_results_card.dart';
import '../widgets/note_history_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioBufferService _audio = AudioBufferService();
  final PitchDetector _pitch = PitchDetector();
  final KeyDetector _key = KeyDetector();
  Timer? _timer;

  bool _isListening = false;
  bool _hasError = false;

  NoteInfo? _currentNote;
  bool _isStable = false;

  // Pitch stability tracking
  int _stableNoteClass = -1;
  int _stableFrames = 0;
  final List<double> _lastPitches = [];

  // Sustain duration tracking
  int? _sustainedNote;
  int? _sustainStartTime;
  double _sustainDuration = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isListening) {
      _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    setState(() {
      _hasError = false;
    });
    final ok = await _audio.start();
    if (!ok) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }
    _key.reset();
    _currentNote = null;
    _stableNoteClass = -1;
    _stableFrames = 0;
    _lastPitches.clear();
    _sustainedNote = null;
    _sustainStartTime = null;
    _sustainDuration = 0;

    setState(() => _isListening = true);

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _process());
  }

  void _stop() {
    _finalizeSustainedNote();
    _timer?.cancel();
    _timer = null;
    _audio.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _currentNote = null;
        _sustainDuration = 0;
      });
    }
  }

  void _process() {
    if (!_audio.isRecording) return;

    final buf = _audio.workingBuffer;
    final result = _pitch.detect(buf, 44100);

    NoteInfo? note;
    bool stable = false;

    if (result != null && result.confidence >= 0.2) {
      note = NoteUtils.frequencyToNote(result.frequency);

      _lastPitches.add(result.frequency);
      if (_lastPitches.length > 6) _lastPitches.removeAt(0);

      if (_lastPitches.length >= 3) {
        final avg =
            _lastPitches.reduce((a, b) => a + b) / _lastPitches.length;
        final variance = _lastPitches
                .map((p) => (p - avg) * (p - avg))
                .reduce((a, b) => a + b) /
            _lastPitches.length;
        final stability = variance.sqrt() / avg;

        final nc = NoteUtils.frequencyToNote(avg).noteClass;

        if (stability < 0.03) {
          if (nc == _stableNoteClass) {
            _stableFrames++;

            if (_stableFrames >= 3 && _sustainedNote == null) {
              // Note just became sustained
              _sustainedNote = nc;
              _sustainStartTime = DateTime.now().millisecondsSinceEpoch;
              _sustainDuration = 0;
            }

            if (_sustainedNote != null && _sustainStartTime != null) {
              _sustainDuration =
                  (DateTime.now().millisecondsSinceEpoch - _sustainStartTime!) /
                      1000.0;
            }

            stable = true;
          } else {
            // Note changed – finalize previous sustained note
            _finalizeSustainedNote();
            _stableNoteClass = nc;
            _stableFrames = 1;
          }
        } else {
          _finalizeSustainedNote();
          _stableFrames = 0;
        }
      }
    } else {
      _finalizeSustainedNote();
      _stableFrames = 0;
      _lastPitches.clear();
    }

    if (mounted) {
      setState(() {
        _currentNote = note;
        _isStable = stable;
      });
    }
  }

  void _finalizeSustainedNote() {
    if (_sustainedNote == null || _sustainStartTime == null) {
      _sustainedNote = null;
      _sustainStartTime = null;
      _sustainDuration = 0;
      return;
    }
    final duration =
        DateTime.now().millisecondsSinceEpoch - _sustainStartTime!;
    if (duration >= 200) {
      _key.addNote(_sustainedNote!, weight: duration / 200.0);
    }
    _sustainedNote = null;
    _sustainStartTime = null;
    _sustainDuration = 0;
  }

  void _reset() {
    _finalizeSustainedNote();
    _key.reset();
    _currentNote = null;
    _stableNoteClass = -1;
    _stableFrames = 0;
    _lastPitches.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final topKeys = _key.computeTopKeys(4);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: NoteDisplay(
                      noteInfo: _currentNote,
                      isStable: _isStable,
                      sustainDuration: _sustainDuration,
                    ),
                  ),
                  ChromaticIndicator(
                    noteCounts: _key.noteCounts,
                    sustainedNote: _sustainedNote,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: NoteHistoryRow(detector: _key),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: KeyResultsCard(
                      scores: topKeys,
                      totalNotes: _key.totalEvents,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _buildStatusBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E1E3A)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '◈ in ear detect',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8899DD),
            ),
          ),
          const Spacer(),
          if (_isListening)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF555566)),
              onPressed: _reset,
              tooltip: 'Reiniciar',
            ),
          _buildToggleButton(),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: _isListening
              ? const Color(0xFF22AA66)
              : const Color(0xFF2A2A5A),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isListening
              ? [
                  BoxShadow(
                    color: const Color(0xFF22AA66).withValues(alpha: 0.25),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Text(
          _isListening ? 'Detener' : 'Iniciar',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _isListening ? Colors.white : const Color(0xFF8899DD),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_hasError) ...[
            const Icon(Icons.error_outline, size: 14, color: Color(0xFFDD5544)),
            const SizedBox(width: 6),
            const Text(
              'Error al acceder al micrófono',
              style: TextStyle(fontSize: 12, color: Color(0xFFDD5544)),
            ),
          ] else if (_isListening) ...[
            const Icon(Icons.mic, size: 14, color: Color(0xFF22AA66)),
            const SizedBox(width: 6),
            const Text(
              'Escuchando...',
              style: TextStyle(fontSize: 12, color: Color(0xFF22AA66)),
            ),
            if (_key.totalEvents > 0) ...[
              const SizedBox(width: 16),
              Text(
                '${_key.totalEvents} eventos · ${_key.uniqueNotes} notas únicas',
                style: const TextStyle(fontSize: 12, color: Color(0xFF555566)),
              ),
            ],
          ] else ...[
            const Icon(Icons.mic_none, size: 14, color: Color(0xFF444455)),
            const SizedBox(width: 6),
            const Text(
              'Presiona "Iniciar" y comienza a cantar',
              style: TextStyle(fontSize: 12, color: Color(0xFF444455)),
            ),
          ],
        ],
      ),
    );
  }
}

extension _DoubleSqrt on double {
  double sqrt() => this < 0 ? 0 : _sqrt(this);
  static double _sqrt(double x) {
    double r = x;
    for (int i = 0; i < 10; i++) {
      r = (r + x / r) * 0.5;
    }
    return r;
  }
}
