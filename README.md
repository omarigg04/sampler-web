# Flutter Sampler

A professional audio sampling application built with Flutter, featuring comprehensive audio manipulation, MIDI support, and real-time recording capabilities.

## Features

### 🎵 Audio Sampling
- **File Loading**: Support for multiple audio formats
- **Waveform Visualization**: Real-time visual representation of audio samples
- **Sample Editing**: Adjustable start/stop markers for precise sample selection
- **16-Pad Grid**: Classic sampler-style interface for triggering samples

### 🎹 MIDI Integration
- **Device Connection**: Connect and manage MIDI input devices
- **Note Mapping**: Assign MIDI notes to specific samples
- **Real-time Triggering**: Play samples via MIDI input
- **Virtual Piano**: On-screen keyboard for testing samples

### 🎛️ Audio Effects
- **Volume Control**: Individual sample and master volume controls
- **Pitch Adjustment**: Real-time pitch shifting (0.25x to 4x)
- **Sample Looping**: Toggle loop mode for sustained playback
- **Polyphonic Playback**: Multiple simultaneous sample playback

### 🎙️ Recording
- **Real-time Recording**: Built-in audio recording functionality
- **Automatic Sample Creation**: Recorded audio automatically becomes a sample
- **Permission Management**: Proper microphone permission handling

### ⚙️ Settings & Customization
- **Audio Settings**: Buffer size, sample rate, and polyphony configuration
- **MIDI Settings**: Auto-connect and velocity display options
- **Interface Customization**: Dark mode and UI preferences
- **Persistent Storage**: Settings saved between sessions

## Technical Implementation

### Architecture
- **Provider Pattern**: State management using Flutter Provider
- **Service Layer**: Separate services for audio processing, MIDI, and recording
- **Model Layer**: Clean data models for samples and audio properties

### Key Dependencies
- `just_audio`: High-quality audio playback
- `flutter_midi_command`: MIDI device integration
- `record`: Audio recording functionality
- `audio_waveforms`: Waveform visualization
- `file_picker`: File selection interface
- `provider`: State management

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode for mobile development
- Physical device recommended for MIDI and audio recording features

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the application**
   ```bash
   flutter run
   ```

### Permissions

The app requires the following permissions:
- **Microphone**: For audio recording functionality
- **Storage**: For loading and saving audio files
- **Bluetooth**: For MIDI device connectivity

## Usage Guide

### Loading Samples
1. Tap the "+" button in the app bar
2. Select an audio file from your device
3. The sample will appear in the first available pad

### Editing Samples
1. Select a sample from the pad grid
2. Navigate to the "Editor" tab
3. Drag the start/stop markers to adjust sample boundaries
4. Use the controls to adjust volume, pitch, and loop settings

### MIDI Setup
1. Navigate to the "MIDI" tab
2. Tap "Scan" to search for available MIDI devices
3. Connect to your desired device
4. Assign MIDI notes to samples using the "Assign" button

### Recording
1. Tap the record button in the app bar
2. Grant microphone permission if prompted
3. Record your audio
4. Tap stop to finish - the recording becomes a new sample

## Project Structure
```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   └── sample.dart
├── providers/                # State management
│   ├── sampler_provider.dart
│   └── midi_provider.dart
├── services/                 # Business logic
│   ├── audio_service.dart
│   └── recording_service.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   └── settings_screen.dart
└── widgets/                  # Reusable components
    ├── sample_pad_grid.dart
    ├── waveform_editor.dart
    ├── midi_control_panel.dart
    └── sample_controls.dart
```

## Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```
