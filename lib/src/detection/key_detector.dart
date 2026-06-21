import 'note_utils.dart';

class KeyScore {
  final int root;
  final bool isMajor;
  final double score;

  KeyScore({required this.root, required this.isMajor, required this.score});

  String get label => NoteUtils.keyLabel(root, isMajor);
}

class KeyDetector {
  final List<double> noteCounts = List.filled(12, 0.0);
  final List<_NoteEvent> _history = [];
  static const int _windowMs = 30000;
  static const int _maxEvents = 300;

  int get totalEvents => _history.length;
  int get uniqueNotes => noteCounts.where((c) => c > 0.01).length;

  double get totalWeight =>
      _history.fold(0.0, (sum, e) => sum + e.weight);

  void addNote(int noteClass, {double weight = 1.0}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    noteCounts[noteClass] += weight;
    _history.add(_NoteEvent(noteClass: noteClass, time: now, weight: weight));
    _prune();
  }

  void reset() {
    noteCounts.fillRange(0, 12, 0.0);
    _history.clear();
  }

  void _prune() {
    final cutoff = DateTime.now().millisecondsSinceEpoch - _windowMs;
    while (_history.isNotEmpty && _history.first.time < cutoff) {
      final removed = _history.removeAt(0);
      noteCounts[removed.noteClass] =
          (noteCounts[removed.noteClass] - removed.weight).clamp(0.0, 999999);
    }
    while (_history.length > _maxEvents) {
      final removed = _history.removeAt(0);
      noteCounts[removed.noteClass] =
          (noteCounts[removed.noteClass] - removed.weight).clamp(0.0, 999999);
    }
  }

  List<KeyScore> computeTopKeys([int count = 3]) {
    if (_history.length < 2) return [];
    final scores = <KeyScore>[];
    for (int root = 0; root < 12; root++) {
      scores.add(_scoreKey(root, true));
      scores.add(_scoreKey(root, false));
    }
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores.take(count).toList();
  }

  KeyScore _scoreKey(int root, bool isMajor) {
    final pattern = isMajor ? NoteUtils.majorPattern : NoteUtils.minorPattern;
    double score = 0;
    for (int n = 0; n < 12; n++) {
      final cnt = noteCounts[n];
      if (cnt < 0.001) { continue; }
      final semitone = ((n - root) + 12) % 12;
      if (pattern.contains(semitone)) {
        double w = cnt;
        if (semitone == 0) {
          w += cnt * 0.5;
        } else if (semitone == 7) {
          w += cnt * 0.3;
        } else if (isMajor && semitone == 4) {
          w += cnt * 0.2;
        } else if (!isMajor && semitone == 3) {
          w += cnt * 0.2;
        }
        score += w;
      }
    }
    return KeyScore(root: root, isMajor: isMajor, score: score);
  }
}

class _NoteEvent {
  final int noteClass;
  final int time;
  final double weight;
  _NoteEvent({required this.noteClass, required this.time, required this.weight});
}
