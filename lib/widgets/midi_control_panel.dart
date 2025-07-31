import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/midi_provider.dart';
import '../providers/sampler_provider.dart';

class MidiControlPanel extends StatefulWidget {
  const MidiControlPanel({super.key});

  @override
  State<MidiControlPanel> createState() => _MidiControlPanelState();
}

class _MidiControlPanelState extends State<MidiControlPanel> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<MidiProvider, SamplerProvider>(
      builder: (context, midiProvider, samplerProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bluetooth,
                    color: midiProvider.isConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    midiProvider.isConnected 
                        ? 'Connected to ${midiProvider.connectedDevice?.name}'
                        : 'No MIDI device connected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (midiProvider.isConnected)
                    ElevatedButton(
                      onPressed: () => midiProvider.disconnectDevice(),
                      child: const Text('Disconnect'),
                    )
                  else
                    ElevatedButton(
                      onPressed: midiProvider.isScanning 
                          ? null 
                          : () => midiProvider.scanForDevices(),
                      child: midiProvider.isScanning 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Scan'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              if (midiProvider.devices.isNotEmpty && !midiProvider.isConnected) ...[
                Text(
                  'Available MIDI Devices',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: midiProvider.devices.length,
                    itemBuilder: (context, index) {
                      final device = midiProvider.devices[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.piano),
                          title: Text(device.name),
                          subtitle: Text('ID: ${device.id}'),
                          trailing: ElevatedButton(
                            onPressed: () => midiProvider.connectDevice(device),
                            child: const Text('Connect'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (midiProvider.isConnected) ...[
                Text(
                  'MIDI Mappings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: samplerProvider.samples.length,
                    itemBuilder: (context, index) {
                      final sample = samplerProvider.samples[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(sample.name),
                          subtitle: Text(
                            sample.midiNote != null
                                ? 'MIDI Note: ${midiProvider.getMidiNoteName(sample.midiNote!)}'
                                : 'No MIDI note assigned',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (sample.midiNote != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    samplerProvider.assignMidiNote(sample.id, -1);
                                  },
                                ),
                              ElevatedButton(
                                onPressed: () => _showMidiAssignDialog(context, sample.id),
                                child: const Text('Assign'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const VirtualPianoKeyboard(),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.piano, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No MIDI devices found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap "Scan" to search for MIDI devices',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMidiAssignDialog(BuildContext context, String sampleId) {
    int selectedNote = 60;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign MIDI Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Note: ${context.read<MidiProvider>().getMidiNoteName(selectedNote)}'),
              Slider(
                value: selectedNote.toDouble(),
                min: 24,
                max: 96,
                divisions: 72,
                onChanged: (value) {
                  setState(() {
                    selectedNote = value.round();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<SamplerProvider>().assignMidiNote(sampleId, selectedNote);
                Navigator.pop(context);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}

class VirtualPianoKeyboard extends StatelessWidget {
  const VirtualPianoKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: List.generate(12, (index) {
          final midiNote = 60 + index; // C4 to B4
          final isBlackKey = _isBlackKey(index);
          
          return Expanded(
            child: GestureDetector(
              onTapDown: (_) => _playNote(context, midiNote),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isBlackKey ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isBlackKey ? Colors.grey : Colors.black,
                  ),
                ),
                child: Center(
                  child: Text(
                    context.read<MidiProvider>().getMidiNoteName(midiNote),
                    style: TextStyle(
                      color: isBlackKey ? Colors.white : Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _isBlackKey(int index) {
    return [1, 3, 6, 8, 10].contains(index);
  }

  void _playNote(BuildContext context, int midiNote) {
    final samplerProvider = context.read<SamplerProvider>();
    final samples = samplerProvider.samples;
    
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].midiNote == midiNote) {
        samplerProvider.playSample(samples[i].id, padIndex: i);
        break;
      }
    }
  }
}