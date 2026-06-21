import 'package:flutter/material.dart';
import '../detection/key_detector.dart';

class NoteHistoryRow extends StatelessWidget {
  final KeyDetector detector;

  const NoteHistoryRow({super.key, required this.detector});

  @override
  Widget build(BuildContext context) {
    final counts = detector.noteCounts;
    final hasNotes = counts.any((c) => c > 0.01);
    if (!hasNotes) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF151530)),
        ),
        child: const Center(
          child: Text(
            'Notas detectadas aparecerán aquí',
            style: TextStyle(fontSize: 12, color: Color(0xFF444455)),
          ),
        ),
      );
    }

    // Show last ~50 notes from history - we need to access it
    // For simplicity, show which note classes have been detected
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF151530)),
      ),
      child: Center(
        child: Text(
          '${detector.totalEvents} eventos · ${detector.uniqueNotes} notas únicas',
          style: const TextStyle(fontSize: 12, color: Color(0xFF555566)),
        ),
      ),
    );
  }
}
