import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../providers/sampler_provider.dart';
import '../models/sample.dart';

class SampleControls extends StatelessWidget {
  final Sample sample;

  const SampleControls({
    super.key,
    required this.sample,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<SamplerProvider>().playSample(sample.id);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<SamplerProvider>().stopAllSamples();
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<SamplerProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      provider.toggleSampleLoop(sample.id);
                    },
                    icon: Icon(sample.isLooping ? Icons.repeat_one : Icons.repeat),
                    label: Text(sample.isLooping ? 'Loop On' : 'Loop Off'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sample.isLooping ? Colors.orange : null,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSliderControl(
                  context,
                  'Volume',
                  sample.volume,
                  0.0,
                  kIsWeb ? 1.0 : 2.0, // Limitar max volumen en web
                  (value) {
                    context.read<SamplerProvider>().updateSampleVolume(sample.id, value);
                  },
                  valueFormatter: (value) => '${(value * 100).round()}%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSliderControl(
                  context,
                  'Pitch',
                  sample.pitch,
                  0.25,
                  4.0,
                  (value) {
                    context.read<SamplerProvider>().updateSamplePitch(sample.id, value);
                  },
                  valueFormatter: (value) => '${value.toStringAsFixed(2)}x',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRangeSlider(
                  context,
                  'Sample Range',
                  SfRangeValues(sample.startPosition, sample.endPosition),
                  0.0,
                  1.0,
                  (values) {
                    context.read<SamplerProvider>().updateSampleStartPosition(sample.id, values.start);
                    context.read<SamplerProvider>().updateSampleEndPosition(sample.id, values.end);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    String Function(double)? valueFormatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              valueFormatter?.call(value) ?? value.toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SfSlider(
          value: value,
          min: min,
          max: max,
          onChanged: (value) => onChanged(value),
          activeColor: Colors.orange,
          inactiveColor: Colors.grey.withValues(alpha: 0.3),
          thumbShape: const SfThumbShape(),
        ),
      ],
    );
  }

  Widget _buildRangeSlider(
    BuildContext context,
    String label,
    SfRangeValues values,
    double min,
    double max,
    Function(SfRangeValues) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${(values.start * 100).round()}% - ${(values.end * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SfRangeSlider(
          values: values,
          min: min,
          max: max,
          onChanged: (value) => onChanged(value),
          activeColor: Colors.orange,
          inactiveColor: Colors.grey.withValues(alpha: 0.3),
          startThumbIcon: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 16,
          ),
          endThumbIcon: const Icon(
            Icons.stop,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }
}