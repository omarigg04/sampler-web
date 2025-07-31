import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/sample.dart';
import '../services/audio_service.dart';
import '../services/recording_service.dart';

class SamplerProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  final RecordingService _recordingService = RecordingService();
  final List<Sample> _samples = [];
  final List<AudioPlayer> _players = [];
  
  Sample? _selectedSample;
  bool _isRecording = false;
  double _masterVolume = 1.0;
  
  List<Sample> get samples => List.unmodifiable(_samples);
  Sample? get selectedSample => _selectedSample;
  bool get isRecording => _isRecording;
  double get masterVolume => _masterVolume;
  
  SamplerProvider() {
    _initializePlayers();
  }
  
  void _initializePlayers() {
    for (int i = 0; i < 16; i++) {
      _players.add(AudioPlayer());
    }
  }
  
  Future<void> loadSample() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      
      if (result != null) {
        final pickedFile = result.files.single;
        final fileName = pickedFile.name;
        
        String? filePath;
        Uint8List? fileBytes;
        
        if (kIsWeb) {
          // En web, usar bytes
          fileBytes = pickedFile.bytes;
          if (fileBytes == null) {
            debugPrint('Error: No se pudieron obtener los bytes del archivo');
            return;
          }
          filePath = 'web_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        } else {
          // En desktop, usar path
          if (pickedFile.path == null) {
            debugPrint('Error: No se pudo obtener la ruta del archivo');
            return;
          }
          filePath = pickedFile.path!;
        }
        
        final player = AudioPlayer();
        Duration duration = Duration.zero;
        
        try {
          if (kIsWeb && fileBytes != null) {
            // Para web, crear un AudioSource desde bytes
            await player.setAudioSource(
              AudioSource.uri(
                Uri.dataFromBytes(fileBytes, mimeType: 'audio/${fileName.split('.').last}'),
              ),
            );
          } else {
            // Para desktop, usar archivo local
            await player.setFilePath(filePath);
          }
          duration = player.duration ?? Duration.zero;
        } catch (e) {
          debugPrint('Error cargando audio: $e');
          // Usar duración por defecto si no se puede obtener
          duration = const Duration(seconds: 30);
        } finally {
          player.dispose();
        }
        
        // Generar waveform
        List<double> waveformData;
        if (kIsWeb && fileBytes != null) {
          waveformData = await _audioService.generateWaveformFromBytes(fileBytes);
        } else {
          waveformData = await _audioService.generateWaveform(filePath);
        }
        
        final sample = Sample(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: fileName.split('.').first,
          filePath: filePath,
          duration: duration,
          waveformData: waveformData,
          bytes: kIsWeb ? fileBytes : null, // Guardamos los bytes para web
        );
        
        _samples.add(sample);
        _selectedSample = sample;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading sample: $e');
    }
  }
  
  Future<void> playSample(String sampleId, {int? padIndex}) async {
    final sample = _samples.firstWhere((s) => s.id == sampleId);
    final playerIndex = padIndex ?? 0;
    
    if (playerIndex < _players.length) {
      final player = _players[playerIndex];
      
      try {
        if (kIsWeb && sample.bytes != null) {
          // Para web, usar bytes
          final fileName = sample.name;
          final extension = sample.filePath.split('.').last.toLowerCase();
          String mimeType = 'audio/mpeg'; // default
          
          switch (extension) {
            case 'mp3':
              mimeType = 'audio/mpeg';
              break;
            case 'wav':
              mimeType = 'audio/wav';
              break;
            case 'ogg':
              mimeType = 'audio/ogg';
              break;
            case 'm4a':
              mimeType = 'audio/mp4';
              break;
          }
          
          await player.setAudioSource(
            AudioSource.uri(
              Uri.dataFromBytes(sample.bytes!, mimeType: mimeType),
            ),
          );
        } else {
          // Para desktop, usar path
          await player.setFilePath(sample.filePath);
        }
        
        final startMs = (sample.duration.inMilliseconds * sample.startPosition).round();
        final endMs = (sample.duration.inMilliseconds * sample.endPosition).round();
        
        await player.seek(Duration(milliseconds: startMs));
        // Asegurar que el volumen esté entre 0 y 1 para web
        final clampedVolume = (sample.volume * _masterVolume).clamp(0.0, 1.0);
        player.setVolume(clampedVolume);
        
        if (sample.pitch != 1.0) {
          await player.setSpeed(sample.pitch);
        }
        
        await player.play();
        
        if (!sample.isLooping) {
          Future.delayed(Duration(milliseconds: endMs - startMs), () {
            player.stop();
          });
        }
        
      } catch (e) {
        debugPrint('Error playing sample: $e');
      }
    }
  }
  
  void stopSample(int padIndex) {
    if (padIndex < _players.length) {
      _players[padIndex].stop();
    }
  }
  
  void stopAllSamples() {
    for (final player in _players) {
      player.stop();
    }
  }
  
  void selectSample(String sampleId) {
    _selectedSample = _samples.firstWhere((s) => s.id == sampleId);
    notifyListeners();
  }
  
  void updateSampleStartPosition(String sampleId, double position) {
    final sampleIndex = _samples.indexWhere((s) => s.id == sampleId);
    if (sampleIndex != -1) {
      _samples[sampleIndex].startPosition = position.clamp(0.0, _samples[sampleIndex].endPosition - 0.01);
      if (_selectedSample?.id == sampleId) {
        _selectedSample = _samples[sampleIndex];
      }
      notifyListeners();
    }
  }
  
  void updateSampleEndPosition(String sampleId, double position) {
    final sampleIndex = _samples.indexWhere((s) => s.id == sampleId);
    if (sampleIndex != -1) {
      _samples[sampleIndex].endPosition = position.clamp(_samples[sampleIndex].startPosition + 0.01, 1.0);
      if (_selectedSample?.id == sampleId) {
        _selectedSample = _samples[sampleIndex];
      }
      notifyListeners();
    }
  }
  
  void updateSampleVolume(String sampleId, double volume) {
    final sampleIndex = _samples.indexWhere((s) => s.id == sampleId);
    if (sampleIndex != -1) {
      // En web, limitar el volumen máximo a 1.0
      final maxVolume = kIsWeb ? 1.0 : 2.0;
      _samples[sampleIndex].volume = volume.clamp(0.0, maxVolume);
      if (_selectedSample?.id == sampleId) {
        _selectedSample = _samples[sampleIndex];
      }
      notifyListeners();
    }
  }
  
  void updateSamplePitch(String sampleId, double pitch) {
    final sampleIndex = _samples.indexWhere((s) => s.id == sampleId);
    if (sampleIndex != -1) {
      _samples[sampleIndex].pitch = pitch.clamp(0.25, 4.0);
      if (_selectedSample?.id == sampleId) {
        _selectedSample = _samples[sampleIndex];
      }
      notifyListeners();
    }
  }
  
  void toggleSampleLoop(String sampleId) {
    final sampleIndex = _samples.indexWhere((s) => s.id == sampleId);
    if (sampleIndex != -1) {
      _samples[sampleIndex].isLooping = !_samples[sampleIndex].isLooping;
      if (_selectedSample?.id == sampleId) {
        _selectedSample = _samples[sampleIndex];
      }
      notifyListeners();
    }
  }
  
  void assignMidiNote(String sampleId, int midiNote) {
    final sampleIndex = _samples.indexWhere((s) => s.id == sampleId);
    if (sampleIndex != -1) {
      _samples[sampleIndex].midiNote = midiNote;
      if (_selectedSample?.id == sampleId) {
        _selectedSample = _samples[sampleIndex];
      }
      notifyListeners();
    }
  }
  
  void removeSample(String sampleId) {
    _samples.removeWhere((s) => s.id == sampleId);
    if (_selectedSample?.id == sampleId) {
      _selectedSample = _samples.isNotEmpty ? _samples.first : null;
    }
    notifyListeners();
  }
  
  void setMasterVolume(double volume) {
    // En web, limitar el volumen máximo a 1.0
    final maxVolume = kIsWeb ? 1.0 : 2.0;
    _masterVolume = volume.clamp(0.0, maxVolume);
    notifyListeners();
  }
  
  Future<void> startRecording() async {
    try {
      final success = await _recordingService.startRecording();
      if (success) {
        _isRecording = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }
  
  Future<void> stopRecording() async {
    try {
      final recordingPath = await _recordingService.stopRecording();
      _isRecording = false;
      
      if (recordingPath != null) {
        await _createSampleFromRecording(recordingPath);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
    }
  }
  
  Future<void> _createSampleFromRecording(String recordingPath) async {
    try {
      final file = File(recordingPath);
      if (!await file.exists()) return;
      
      final player = AudioPlayer();
      await player.setFilePath(recordingPath);
      final duration = player.duration ?? Duration.zero;
      player.dispose();
      
      final waveformData = await _audioService.generateWaveform(recordingPath);
      final fileName = 'Recording ${DateTime.now().millisecondsSinceEpoch}';
      
      final sample = Sample(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        filePath: recordingPath,
        duration: duration,
        waveformData: waveformData,
      );
      
      _samples.add(sample);
      _selectedSample = sample;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating sample from recording: $e');
    }
  }
  
  @override
  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
    _recordingService.dispose();
    super.dispose();
  }
}