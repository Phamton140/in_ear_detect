import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:record/record.dart';

class AudioBufferService {
  final AudioRecorder _recorder = AudioRecorder();
  final List<double> _ringBuffer = List.filled(8192, 0.0);
  int _writeIndex = 0;
  StreamSubscription<Uint8List>? _sub;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  List<double> get workingBuffer {
    final buf = <double>[];
    for (int i = 0; i < 4096; i++) {
      final idx = (_writeIndex - 4096 + i) & 8191;
      buf.add(_ringBuffer[idx]);
    }
    return buf;
  }

  Future<bool> start() async {
    if (_isRecording) return true;
    try {
      if (!await _recorder.hasPermission()) {
        await _recorder.dispose();
        return false;
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          numChannels: 1,
          sampleRate: 44100,
        ),
      );
      _sub = stream.listen(_onData,
          onError: (e) => _log('Audio error: $e'));
      _isRecording = true;
      return true;
    } catch (e) {
      _log('Start error: $e');
      return false;
    }
  }

  void _onData(Uint8List data) {
    for (int i = 0; i < data.length - 1; i += 2) {
      int sample = data[i] | (data[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      _ringBuffer[_writeIndex & 8191] = sample / 32768.0;
      _writeIndex++;
    }
  }

  Future<void> stop() async {
    _isRecording = false;
    await _sub?.cancel();
    _sub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  void dispose() {
    stop();
    _recorder.dispose();
  }

  static void _log(String msg) => dev.log(msg, name: 'AudioBuffer');
}
