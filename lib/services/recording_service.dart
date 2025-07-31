import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> startRecording() async {
    try {
      if (_isRecording) return false;

      final hasPermission = await requestPermissions();
      if (!hasPermission) return false;

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      
      return path ?? _currentRecordingPath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> pauseRecording() async {
    try {
      if (_isRecording) {
        await _recorder.pause();
      }
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  Future<void> resumeRecording() async {
    try {
      if (_isRecording) {
        await _recorder.resume();
      }
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  Future<bool> isRecordingPermissionGranted() async {
    return await Permission.microphone.isGranted;
  }

  void dispose() {
    _recorder.dispose();
  }
}