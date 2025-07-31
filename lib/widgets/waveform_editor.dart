import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sampler_provider.dart';
import '../models/sample.dart';
import 'sample_controls.dart';

class WaveformEditor extends StatefulWidget {
  const WaveformEditor({super.key});

  @override
  State<WaveformEditor> createState() => _WaveformEditorState();
}

class _WaveformEditorState extends State<WaveformEditor> {

  @override
  Widget build(BuildContext context) {
    return Consumer<SamplerProvider>(
      builder: (context, provider, child) {
        final sample = provider.selectedSample;
        
        if (sample == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.graphic_eq, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No sample selected',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Select a sample from the pads to edit',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sample.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duration: ${_formatDuration(sample.duration)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: WaveformDisplay(
                    sample: sample,
                    onStartPositionChanged: (position) {
                      provider.updateSampleStartPosition(sample.id, position);
                    },
                    onEndPositionChanged: (position) {
                      provider.updateSampleEndPosition(sample.id, position);
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Consumer<SamplerProvider>(
                builder: (context, provider, child) {
                  return SampleControls(sample: sample);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(milliseconds ~/ 10).toString().padLeft(2, '0')}';
  }
}

class WaveformDisplay extends StatefulWidget {
  final Sample sample;
  final Function(double) onStartPositionChanged;
  final Function(double) onEndPositionChanged;

  const WaveformDisplay({
    super.key,
    required this.sample,
    required this.onStartPositionChanged,
    required this.onEndPositionChanged,
  });

  @override
  State<WaveformDisplay> createState() => _WaveformDisplayState();
}

class _WaveformDisplayState extends State<WaveformDisplay> {
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            final position = details.localPosition.dx / constraints.maxWidth;
            final distanceToStart = (position - widget.sample.startPosition).abs();
            final distanceToEnd = (position - widget.sample.endPosition).abs();
            
            if (distanceToStart < distanceToEnd && distanceToStart < 0.05) {
              _isDraggingStart = true;
            } else if (distanceToEnd < 0.05) {
              _isDraggingEnd = true;
            }
          },
          onPanUpdate: (details) {
            final position = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
            
            if (_isDraggingStart) {
              widget.onStartPositionChanged(position);
            } else if (_isDraggingEnd) {
              widget.onEndPositionChanged(position);
            }
          },
          onPanEnd: (details) {
            _isDraggingStart = false;
            _isDraggingEnd = false;
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: WaveformPainter(
              waveformData: widget.sample.waveformData,
              startPosition: widget.sample.startPosition,
              endPosition: widget.sample.endPosition,
              isDraggingStart: _isDraggingStart,
              isDraggingEnd: _isDraggingEnd,
            ),
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double startPosition;
  final double endPosition;
  final bool isDraggingStart;
  final bool isDraggingEnd;

  WaveformPainter({
    required this.waveformData,
    required this.startPosition,
    required this.endPosition,
    required this.isDraggingStart,
    required this.isDraggingEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final selectedPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final markerPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2.0;

    final centerY = size.height / 2;
    final stepX = size.width / waveformData.length;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * stepX;
      final normalizedPosition = i / waveformData.length;
      final amplitude = waveformData[i] * centerY;
      
      final isInSelectedRange = normalizedPosition >= startPosition && normalizedPosition <= endPosition;
      final currentPaint = isInSelectedRange ? selectedPaint : backgroundPaint;

      canvas.drawRect(
        Rect.fromLTWH(x, centerY - amplitude, stepX, amplitude * 2),
        currentPaint,
      );
    }

    final startX = startPosition * size.width;
    final endX = endPosition * size.width;

    canvas.drawLine(
      Offset(startX, 0),
      Offset(startX, size.height),
      markerPaint..color = isDraggingStart ? Colors.red : Colors.orange,
    );

    canvas.drawLine(
      Offset(endX, 0),
      Offset(endX, size.height),
      markerPaint..color = isDraggingEnd ? Colors.red : Colors.orange,
    );

    final handlePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    const handleSize = 8.0;
    canvas.drawCircle(
      Offset(startX, size.height - handleSize),
      handleSize,
      handlePaint..color = isDraggingStart ? Colors.red : Colors.orange,
    );

    canvas.drawCircle(
      Offset(endX, size.height - handleSize),
      handleSize,
      handlePaint..color = isDraggingEnd ? Colors.red : Colors.orange,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}