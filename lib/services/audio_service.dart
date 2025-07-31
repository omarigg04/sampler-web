import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class AudioService {
  Future<List<double>> generateWaveform(String filePath) async {
    try {
      if (kIsWeb) {
        return _generateDummyWaveform();
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        return [];
      }
      
      final bytes = await file.readAsBytes();
      return _processAudioBytes(bytes);
    } catch (e) {
      debugPrint('Error generating waveform: $e');
      return _generateDummyWaveform();
    }
  }
  
  Future<List<double>> generateWaveformFromBytes(Uint8List bytes) async {
    try {
      return _processAudioBytes(bytes);
    } catch (e) {
      debugPrint('Error generating waveform from bytes: $e');
      return _generateDummyWaveform();
    }
  }
  
  List<double> _processAudioBytes(Uint8List bytes) {
    const int targetPoints = 200;
    
    if (bytes.length < 44) {
      return _generateDummyWaveform();
    }
    
    try {
      int dataStart = 44;
      for (int i = 36; i < bytes.length - 8; i++) {
        if (bytes[i] == 0x64 && bytes[i + 1] == 0x61 && 
            bytes[i + 2] == 0x74 && bytes[i + 3] == 0x61) {
          dataStart = i + 8;
          break;
        }
      }
      
      final audioData = bytes.sublist(dataStart);
      final List<double> waveform = [];
      
      for (int i = 0; i < targetPoints; i++) {
        final startIdx = (i * audioData.length / targetPoints).round();
        final endIdx = ((i + 1) * audioData.length / targetPoints).round();
        
        double maxAmplitude = 0.0;
        
        for (int j = startIdx; j < endIdx && j < audioData.length - 1; j += 2) {
          final sample = (audioData[j + 1] << 8) | audioData[j];
          final normalizedSample = (sample - 32768) / 32768.0;
          maxAmplitude = max(maxAmplitude, normalizedSample.abs());
        }
        
        waveform.add(maxAmplitude);
      }
      
      return waveform;
    } catch (e) {
      debugPrint('Error processing audio bytes: $e');
      return _generateDummyWaveform();
    }
  }
  
  List<double> _generateDummyWaveform({int points = 200}) {
    final random = Random();
    return List.generate(points, (index) {
      final x = index / points * 4 * pi;
      return (sin(x) + sin(x * 2) * 0.5 + sin(x * 4) * 0.25).abs() * 
             (0.5 + random.nextDouble() * 0.5);
    });
  }
  
  double calculateRMS(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    
    double sum = 0.0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    
    return sqrt(sum / samples.length);
  }
  
  List<double> normalizeWaveform(List<double> waveform) {
    if (waveform.isEmpty) return waveform;
    
    final maxValue = waveform.reduce(max);
    if (maxValue == 0) return waveform;
    
    return waveform.map((value) => value / maxValue).toList();
  }
}