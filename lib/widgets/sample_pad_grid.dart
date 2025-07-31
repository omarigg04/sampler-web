import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sampler_provider.dart';
import '../models/sample.dart';

class SamplePadGrid extends StatelessWidget {
  const SamplePadGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SamplerProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 16,
            itemBuilder: (context, index) {
              final sample = index < provider.samples.length ? provider.samples[index] : null;
              return SamplePad(
                sample: sample,
                padIndex: index,
                isSelected: sample != null && provider.selectedSample?.id == sample.id,
                onTap: () {
                  if (sample != null) {
                    provider.playSample(sample.id, padIndex: index);
                    provider.selectSample(sample.id);
                  }
                },
                onLongPress: () {
                  if (sample != null) {
                    _showSampleMenu(context, sample, index);
                  } else {
                    provider.loadSample();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showSampleMenu(BuildContext context, Sample sample, int padIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sample.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Sample'),
              onTap: () {
                Navigator.pop(context);
                context.read<SamplerProvider>().selectSample(sample.id);
              },
            ),
            ListTile(
              leading: Icon(sample.isLooping ? Icons.repeat_one : Icons.repeat),
              title: Text(sample.isLooping ? 'Disable Loop' : 'Enable Loop'),
              onTap: () {
                Navigator.pop(context);
                context.read<SamplerProvider>().toggleSampleLoop(sample.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.piano),
              title: Text('MIDI Note: ${sample.midiNote != null ? _getMidiNoteName(sample.midiNote!) : 'None'}'),
              onTap: () {
                Navigator.pop(context);
                _showMidiNoteDialog(context, sample);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Sample'),
              onTap: () {
                Navigator.pop(context);
                context.read<SamplerProvider>().removeSample(sample.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMidiNoteDialog(BuildContext context, Sample sample) {
    int selectedNote = sample.midiNote ?? 60;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign MIDI Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Note: ${_getMidiNoteName(selectedNote)}'),
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
                context.read<SamplerProvider>().assignMidiNote(sample.id, selectedNote);
                Navigator.pop(context);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMidiNoteName(int midiNote) {
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (midiNote ~/ 12) - 1;
    final note = noteNames[midiNote % 12];
    return '$note$octave';
  }
}

class SamplePad extends StatefulWidget {
  final Sample? sample;
  final int padIndex;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SamplePad({
    super.key,
    required this.sample,
    required this.padIndex,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<SamplePad> createState() => _SamplePadState();
}

class _SamplePadState extends State<SamplePad>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = widget.sample != null;
    
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getPadColors(hasAudio),
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isSelected ? Colors.orange : Colors.grey.withValues(alpha: 0.3),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: _isPressed ? 2 : 6,
                    offset: Offset(0, _isPressed ? 1 : 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasAudio ? Icons.music_note : Icons.add,
                    size: 32,
                    color: hasAudio ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasAudio ? widget.sample!.name : 'Empty',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: hasAudio ? Colors.white : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasAudio && widget.sample!.midiNote != null)
                    Text(
                      _getMidiNoteName(widget.sample!.midiNote!),
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Color> _getPadColors(bool hasAudio) {
    if (hasAudio) {
      return [
        const Color(0xFF2196F3),
        const Color(0xFF1976D2),
      ];
    } else {
      return [
        const Color(0xFF424242),
        const Color(0xFF303030),
      ];
    }
  }

  String _getMidiNoteName(int midiNote) {
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (midiNote ~/ 12) - 1;
    final note = noteNames[midiNote % 12];
    return '$note$octave';
  }
}