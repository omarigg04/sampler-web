import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/sampler_provider.dart';
import '../providers/midi_provider.dart';
import '../widgets/sample_pad_grid.dart';
import '../widgets/waveform_editor.dart';
import '../widgets/midi_control_panel.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupMidiCallbacks();
  }

  void _setupMidiCallbacks() {
    final midiProvider = context.read<MidiProvider>();
    final samplerProvider = context.read<SamplerProvider>();

    midiProvider.onNoteOn = (midiNote, velocity) {
      final samples = samplerProvider.samples;
      for (int i = 0; i < samples.length; i++) {
        if (samples[i].midiNote == midiNote) {
          samplerProvider.playSample(samples[i].id, padIndex: i);
          break;
        }
      }
    };

    midiProvider.onNoteOff = (midiNote) {
      final samples = samplerProvider.samples;
      for (int i = 0; i < samples.length; i++) {
        if (samples[i].midiNote == midiNote && !samples[i].isLooping) {
          samplerProvider.stopSample(i);
          break;
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Sampler'),
        centerTitle: true,
        actions: [
          if (!kIsWeb)
            Consumer<SamplerProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: Icon(provider.isRecording ? Icons.stop : Icons.fiber_manual_record),
                  color: provider.isRecording ? Colors.red : null,
                  onPressed: () {
                    if (provider.isRecording) {
                      provider.stopRecording();
                    } else {
                      provider.startRecording();
                    }
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<SamplerProvider>().loadSample();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  context.read<SamplerProvider>().stopAllSamples();
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Stop All Samples'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Consumer<SamplerProvider>(
                    builder: (context, provider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Master Volume', style: TextStyle(fontSize: 12)),
                          Slider(
                            value: provider.masterVolume,
                            min: 0.0,
                            max: kIsWeb ? 1.0 : 2.0, // Limitar max volumen en web
                            divisions: kIsWeb ? 50 : 100,
                            label: '${(provider.masterVolume * 100).round()}%',
                            onChanged: provider.setMasterVolume,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Consumer<MidiProvider>(
                  builder: (context, midiProvider, child) {
                    return Column(
                      children: [
                        Icon(
                          Icons.bluetooth,
                          color: midiProvider.isConnected ? Colors.green : Colors.grey,
                        ),
                        Text(
                          midiProvider.isConnected ? 'MIDI ON' : 'MIDI OFF',
                          style: TextStyle(
                            fontSize: 10,
                            color: midiProvider.isConnected ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                SamplePadGrid(),
                WaveformEditor(),
                MidiControlPanel(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Pads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.graphic_eq),
            label: 'Editor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.piano),
            label: 'MIDI',
          ),
        ],
      ),
    );
  }

}