import 'package:flutter/material.dart';
import '../detection/note_utils.dart';

class ChromaticIndicator extends StatelessWidget {
  final List<double> noteCounts;
  final int? sustainedNote;

  const ChromaticIndicator({
    super.key,
    required this.noteCounts,
    this.sustainedNote,
  });

  @override
  Widget build(BuildContext context) {
    final maxCnt = noteCounts.reduce((a, b) => a > b ? a : b).clamp(0.001, 999999);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: List.generate(12, (i) {
          final cnt = noteCounts[i];
          final ratio = cnt / maxCnt;
          final isLit = cnt > 0.01;
          final isHot = ratio > 0.5;
          final isCurrentSustained = sustainedNote == i;

          Color bg;
          Color fg;
          if (isCurrentSustained) {
            bg = const Color(0xFF2A1A0A);
            fg = const Color(0xFFFF8844);
          } else if (isHot) {
            bg = const Color(0xFF1A3A2A);
            fg = const Color(0xFF44DD88);
          } else if (isLit) {
            bg = const Color(0xFF1E2A4A);
            fg = const Color(0xFF66AAFF);
          } else {
            bg = const Color(0xFF111128);
            fg = const Color(0xFF333344);
          }

          final opacity = isCurrentSustained
              ? 1.0
              : isLit
                  ? 0.5 + ratio * 0.5
                  : 0.3;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isCurrentSustained
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF8844).withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : isHot
                        ? [
                            BoxShadow(
                              color: const Color(0xFF44DD88).withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                border: isCurrentSustained
                    ? Border.all(
                        color: const Color(0xFFFF8844).withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Center(
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      NoteUtils.noteNames[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
