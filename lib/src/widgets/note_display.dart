import 'package:flutter/material.dart';
import '../detection/note_utils.dart';

class NoteDisplay extends StatelessWidget {
  final NoteInfo? noteInfo;
  final bool isStable;
  final double sustainDuration;

  const NoteDisplay({
    super.key,
    this.noteInfo,
    this.isStable = false,
    this.sustainDuration = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isSustained = isStable && sustainDuration >= 0.15;

    // Glow intensity grows with sustain duration (caps at ~4s)
    final glowIntensity = (sustainDuration / 4.0).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (noteInfo != null && isSustained)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _SustainBar(duration: sustainDuration),
          ),
        Text(
          noteInfo?.noteName ?? '--',
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w800,
            color: noteInfo != null
                ? (isSustained
                    ? const Color(0xFF66DDFF)
                    : isStable
                        ? const Color(0xFFCCDDFF)
                        : const Color(0xFF8899AA))
                : const Color(0xFF444455),
            shadows: noteInfo != null && isSustained
                ? [
                    Shadow(
                      color: Color.lerp(
                        const Color(0xFF66DDFF),
                        const Color(0xFFFF8844),
                        glowIntensity,
                      )!.withValues(alpha: 0.2 + glowIntensity * 0.4),
                      blurRadius: 30 + glowIntensity * 50,
                    ),
                    Shadow(
                      color: Color.lerp(
                        const Color(0xFF4488CC),
                        const Color(0xFFCC4400),
                        glowIntensity,
                      )!.withValues(alpha: 0.1 + glowIntensity * 0.2),
                      blurRadius: 60 + glowIntensity * 60,
                    ),
                  ]
                : null,
          ),
        ),
        if (noteInfo != null) ...[
          const SizedBox(height: 2),
          Text(
            '${noteInfo!.octave}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Color(0xFF666677),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${noteInfo!.frequency.toStringAsFixed(1)} Hz',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF444455),
            ),
          ),
        ],
        if (noteInfo != null) ...[
          const SizedBox(height: 8),
          _CentsBar(cents: noteInfo!.cents),
        ],
      ],
    );
  }
}

class _SustainBar extends StatelessWidget {
  final double duration;
  const _SustainBar({required this.duration});

  @override
  Widget build(BuildContext context) {
    final barWidth = (duration / 6.0).clamp(0.0, 1.0);

    Color barColor;
    if (duration < 1.0) {
      barColor = const Color(0xFF4488CC);
    } else if (duration < 3.0) {
      barColor = const Color(0xFF66DDFF);
    } else {
      barColor = const Color(0xFFFF8844);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              color: const Color(0xFF1A1A35),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: barWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${duration.toStringAsFixed(1)}s',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: barColor,
          ),
        ),
      ],
    );
  }
}

class _CentsBar extends StatelessWidget {
  final double cents;
  const _CentsBar({required this.cents});

  @override
  Widget build(BuildContext context) {
    final absCents = cents.abs();
    final width = (absCents / 50.0 * 100.0).clamp(0, 100);
    final isPositive = cents > 0;
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Text(
            '${cents > 0 ? '+' : ''}${cents.toStringAsFixed(0)}¢',
            style: const TextStyle(fontSize: 13, color: Color(0xFF666677)),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 4,
              color: const Color(0xFF1E1E3A),
              child: LayoutBuilder(
                builder: (_, constraints) {
                  return Stack(
                    children: [
                      Positioned(
                        left: isPositive
                            ? constraints.maxWidth / 2
                            : constraints.maxWidth / 2 -
                                width / 100 * constraints.maxWidth,
                        top: 0,
                        width: width / 100 * constraints.maxWidth,
                        height: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF66DDFF),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
