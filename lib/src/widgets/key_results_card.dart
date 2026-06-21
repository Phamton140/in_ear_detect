import 'package:flutter/material.dart';
import '../detection/key_detector.dart';

class KeyResultsCard extends StatelessWidget {
  final List<KeyScore> scores;
  final int totalNotes;

  const KeyResultsCard({
    super.key,
    required this.scores,
    required this.totalNotes,
  });

  static const _barColors = [
    [Color(0xFF66DDFF), Color(0xFF4488CC)],
    [Color(0xFF66DD99), Color(0xFF44AA77)],
    [Color(0xFFDD8866), Color(0xFFCC6644)],
    [Color(0xFFBB88EE), Color(0xFF8844CC)],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TONALIDADES MÁS PROBABLES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666677),
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (totalNotes > 0)
                Text(
                  '$totalNotes notas · ${scores.isNotEmpty ? (scores.first.score / (scores.first.score.isNaN ? 1 : 1)).toStringAsFixed(0) : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF555566),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (scores.isEmpty)
            const Text(
              'Canta algunas notas para detectar la tonalidad',
              style: TextStyle(fontSize: 13, color: Color(0xFF444455)),
            )
          else
            ...List.generate(scores.length, (i) {
              final s = scores[i];
              final maxScore = scores.first.score;
              final pct = maxScore > 0 ? (s.score / maxScore * 100) : 0.0;
              final colors = _barColors[i.clamp(0, 3)];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        s.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8899DD),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 20,
                          color: const Color(0xFF1A1A35),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: colors,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666677),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
