class PitchResult {
  final double frequency;
  final double confidence;

  PitchResult({required this.frequency, required this.confidence});
}

class PitchDetector {
  final double minFreq;
  final double maxFreq;
  final double minConfidence;

  PitchDetector({
    this.minFreq = 70,
    this.maxFreq = 1400,
    this.minConfidence = 0.15,
  });

  PitchResult? detect(List<double> buffer, int sampleRate) {
    final len = buffer.length;
    final minLag = (sampleRate / maxFreq).ceil().clamp(1, len - 1);
    final maxLag = (sampleRate / minFreq).floor().clamp(1, len - 1);

    double energy = 0;
    for (int i = 0; i < len; i++) { energy += buffer[i] * buffer[i]; }
    if (energy < 0.005) { return null; }

    final norm = energy;
    double bestVal = -1;
    double bestLag = minLag.toDouble();

    for (int lag = minLag; lag <= maxLag; lag++) {
      double sum = 0;
      final n = len - lag;
      for (int i = 0; i < n; i++) { sum += buffer[i] * buffer[i + lag]; }
      final v = sum / norm;
      if (v > bestVal) {
        bestVal = v;
        bestLag = lag.toDouble();
      }
    }

    if (bestVal < minConfidence) return null;

    // Octave correction
    for (final divisor in [2.0, 3.0, 4.0]) {
      final cand = bestLag / divisor;
      if (cand >= minLag) {
        final c = _corrAt(buffer, norm, cand.round());
        if (c > bestVal * 0.88) {
          bestLag = cand;
          bestVal = c;
        }
      }
    }

    // Parabolic interpolation
    if (bestLag > minLag && bestLag < maxLag) {
      final l0 = bestLag.floor();
      final v0 = _corrAt(buffer, norm, l0 - 1);
      final v1 = _corrAt(buffer, norm, l0);
      final v2 = _corrAt(buffer, norm, l0 + 1);
      final a = 0.5 * (v0 + v2) - v1;
      final b = 0.5 * (v2 - v0);
      if (a != 0) bestLag += -b / (2 * a);
    }

    final freq = (sampleRate / bestLag)
        .clamp(minFreq, maxFreq);

    return PitchResult(frequency: freq, confidence: bestVal);
  }

  double _corrAt(List<double> buffer, double norm, int lag) {
    if (lag < 1 || lag >= buffer.length) return 0;
    double sum = 0;
    final n = buffer.length - lag;
    for (int i = 0; i < n; i++) { sum += buffer[i] * buffer[i + lag]; }
    return sum / norm;
  }
}
