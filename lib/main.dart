import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sampler_provider.dart';
import 'providers/midi_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SamplerApp());
}

class SamplerApp extends StatelessWidget {
  const SamplerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SamplerProvider()),
        ChangeNotifierProvider(create: (_) => MidiProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Sampler',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E1E1E),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
