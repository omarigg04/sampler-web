import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

class MidiProvider extends ChangeNotifier {
  MidiCommand? _midiCommand;
  List<MidiDevice> _devices = [];
  MidiDevice? _connectedDevice;
  bool _isScanning = false;
  
  List<MidiDevice> get devices => List.unmodifiable(_devices);
  MidiDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null;
  
  Function(int midiNote, int velocity)? onNoteOn;
  Function(int midiNote)? onNoteOff;
  
  MidiProvider() {
    _initializeMidi();
  }
  
  Future<void> _initializeMidi() async {
    try {
      _midiCommand = MidiCommand();
      
      _midiCommand!.onMidiDataReceived?.listen((data) {
        _handleMidiData(data);
      });
      
      _midiCommand!.onMidiSetupChanged?.listen((data) {
        _refreshDevices();
      });
      
      await _refreshDevices();
    } catch (e) {
      debugPrint('Error initializing MIDI: $e');
    }
  }
  
  void _handleMidiData(MidiPacket packet) {
    if (packet.data.isNotEmpty) {
      final status = packet.data[0];
      final messageType = status & 0xF0;
      
      if (packet.data.length >= 3) {
        final note = packet.data[1];
        final velocity = packet.data[2];
        
        switch (messageType) {
          case 0x90: // Note On
            if (velocity > 0) {
              onNoteOn?.call(note, velocity);
            } else {
              onNoteOff?.call(note);
            }
            break;
          case 0x80: // Note Off
            onNoteOff?.call(note);
            break;
        }
      }
    }
  }
  
  Future<void> scanForDevices() async {
    if (_midiCommand == null) return;
    
    _isScanning = true;
    notifyListeners();
    
    try {
      await _refreshDevices();
    } catch (e) {
      debugPrint('Error scanning for MIDI devices: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }
  
  Future<void> _refreshDevices() async {
    if (_midiCommand == null) return;
    
    try {
      final devices = await _midiCommand!.devices;
      _devices = devices?.where((device) => device.inputPorts.isNotEmpty).toList() ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing MIDI devices: $e');
    }
  }
  
  Future<void> connectDevice(MidiDevice device) async {
    if (_midiCommand == null) return;
    
    try {
      if (_connectedDevice != null) {
        await disconnectDevice();
      }
      
      await _midiCommand!.connectToDevice(device);
      _connectedDevice = device;
      notifyListeners();
      
      debugPrint('Connected to MIDI device: ${device.name}');
    } catch (e) {
      debugPrint('Error connecting to MIDI device: $e');
    }
  }
  
  Future<void> disconnectDevice() async {
    if (_midiCommand == null || _connectedDevice == null) return;
    
    try {
      // Note: Some MIDI command implementations may not have a disconnect method
      // In such cases, we just clear the connected device
      _connectedDevice = null;
      notifyListeners();
      
      debugPrint('Disconnected from MIDI device');
    } catch (e) {
      debugPrint('Error disconnecting from MIDI device: $e');
    }
  }
  
  Future<void> sendMidiMessage(List<int> data) async {
    if (_midiCommand == null || _connectedDevice == null) return;
    
    try {
      _midiCommand!.sendData(Uint8List.fromList(data));
    } catch (e) {
      debugPrint('Error sending MIDI message: $e');
    }
  }
  
  String getMidiNoteName(int midiNote) {
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (midiNote ~/ 12) - 1;
    final note = noteNames[midiNote % 12];
    return '$note$octave';
  }
  
  @override
  void dispose() {
    disconnectDevice();
    super.dispose();
  }
}