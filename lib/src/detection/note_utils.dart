import 'dart:math' as math;

class NoteInfo {
  final int noteClass;
  final int octave;
  final double cents;
  final int midiNumber;
  final double frequency;

  NoteInfo({
    required this.noteClass,
    required this.octave,
    required this.cents,
    required this.midiNumber,
    required this.frequency,
  });

  String get noteName => NoteUtils.noteNames[noteClass];
  String get fullName => '$noteName$octave';
}

class NoteUtils {
  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  static const List<int> majorPattern = [0, 2, 4, 5, 7, 9, 11];
  static const List<int> minorPattern = [0, 2, 3, 5, 7, 8, 10];

  static String keyLabel(int root, bool isMajor) =>
      isMajor ? noteNames[root] : '${noteNames[root]}m';

  static NoteInfo frequencyToNote(double freq) {
    final nn = 12 * (math.log(freq / 440.0) / math.log(2)) + 69;
    final rounded = nn.round();
    final noteClass = ((rounded % 12) + 12) % 12;
    final octave = (rounded ~/ 12) - 1;
    final expectedFreq = 440.0 * math.pow(2, (rounded - 69) / 12.0);
    final cents = 1200 * (math.log(freq / expectedFreq) / math.log(2));
    return NoteInfo(
      noteClass: noteClass,
      octave: octave,
      cents: cents,
      midiNumber: rounded,
      frequency: freq,
    );
  }
}
