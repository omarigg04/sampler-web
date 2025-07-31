import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  double _bufferSize = 1024;
  double _sampleRate = 44100;
  bool _autoConnect = false;
  bool _showVelocity = true;
  int _maxPolyphony = 16;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? true;
      _bufferSize = prefs.getDouble('buffer_size') ?? 1024;
      _sampleRate = prefs.getDouble('sample_rate') ?? 44100;
      _autoConnect = prefs.getBool('auto_connect') ?? false;
      _showVelocity = prefs.getBool('show_velocity') ?? true;
      _maxPolyphony = prefs.getInt('max_polyphony') ?? 16;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Audio Settings',
            [
              _buildSliderTile(
                'Buffer Size',
                _bufferSize,
                256,
                4096,
                (value) {
                  setState(() => _bufferSize = value);
                  _saveSetting('buffer_size', value);
                },
                valueFormatter: (value) => '${value.round()} samples',
              ),
              _buildSliderTile(
                'Sample Rate',
                _sampleRate,
                22050,
                96000,
                (value) {
                  setState(() => _sampleRate = value);
                  _saveSetting('sample_rate', value);
                },
                valueFormatter: (value) => '${value.round()} Hz',
              ),
              _buildSliderTile(
                'Max Polyphony',
                _maxPolyphony.toDouble(),
                1,
                32,
                (value) {
                  setState(() => _maxPolyphony = value.round());
                  _saveSetting('max_polyphony', value.round());
                },
                valueFormatter: (value) => '${value.round()} voices',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'MIDI Settings',
            [
              _buildSwitchTile(
                'Auto-connect MIDI devices',
                'Automatically connect to the first available MIDI device',
                _autoConnect,
                (value) {
                  setState(() => _autoConnect = value);
                  _saveSetting('auto_connect', value);
                },
              ),
              _buildSwitchTile(
                'Show velocity information',
                'Display MIDI velocity values in the interface',
                _showVelocity,
                (value) {
                  setState(() => _showVelocity = value);
                  _saveSetting('show_velocity', value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Interface Settings',
            [
              _buildSwitchTile(
                'Dark Mode',
                'Use dark theme throughout the app',
                _darkMode,
                (value) {
                  setState(() => _darkMode = value);
                  _saveSetting('dark_mode', value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'About',
            [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
                onTap: () => _showAboutDialog(),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Report Issue'),
                subtitle: const Text('Submit feedback or bug reports'),
                onTap: () => _showFeedbackDialog(),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset Settings'),
                subtitle: const Text('Restore all settings to default values'),
                onTap: () => _showResetDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.orange,
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    String Function(double)? valueFormatter,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valueFormatter?.call(value) ?? value.toStringAsFixed(0)),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Flutter Sampler'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flutter Sampler v1.0.0'),
            SizedBox(height: 16),
            Text('A professional audio sampling application built with Flutter.'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Audio sample loading and playback'),
            Text('• Waveform visualization and editing'),
            Text('• MIDI device support'),
            Text('• Real-time audio effects'),
            Text('• Audio recording'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feedback'),
        content: const Text(
          'To report bugs or request features, please contact us at:\n\n'
          'support@fluttersampler.com\n\n'
          'Include your device information and steps to reproduce any issues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will restore all settings to their default values. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await _loadSettings();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults'),
                  ),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}