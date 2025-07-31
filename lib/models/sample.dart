import 'dart:typed_data';

class Sample {
  final String id;
  final String name;
  final String filePath;
  final Duration duration;
  final List<double> waveformData;
  final Uint8List? bytes; // Para almacenar bytes en web
  
  double startPosition;
  double endPosition;
  double volume;
  double pitch;
  int? midiNote;
  bool isLooping;
  
  Sample({
    required this.id,
    required this.name,
    required this.filePath,
    required this.duration,
    this.waveformData = const [],
    this.bytes,
    this.startPosition = 0.0,
    double? endPosition,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.midiNote,
    this.isLooping = false,
  }) : endPosition = endPosition ?? 1.0;
  
  Sample copyWith({
    String? id,
    String? name,
    String? filePath,
    Duration? duration,
    List<double>? waveformData,
    Uint8List? bytes,
    double? startPosition,
    double? endPosition,
    double? volume,
    double? pitch,
    int? midiNote,
    bool? isLooping,
  }) {
    return Sample(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      waveformData: waveformData ?? this.waveformData,
      bytes: bytes ?? this.bytes,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      midiNote: midiNote ?? this.midiNote,
      isLooping: isLooping ?? this.isLooping,
    );
  }
  
  Duration get sampleDuration {
    final totalDuration = duration.inMilliseconds;
    final startMs = (totalDuration * startPosition).round();
    final endMs = (totalDuration * endPosition).round();
    return Duration(milliseconds: endMs - startMs);
  }
}