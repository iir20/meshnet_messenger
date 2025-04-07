import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';

class AudioMessageBubble extends StatefulWidget {
  final String audioPath;
  final String senderName;
  final bool isMe;
  final DateTime timestamp;
  final int duration; // in seconds
  final String mood;
  final bool isEncrypted;
  
  const AudioMessageBubble({
    Key? key,
    required this.audioPath,
    required this.senderName,
    required this.isMe,
    required this.timestamp,
    required this.duration,
    this.mood = 'neutral',
    this.isEncrypted = false,
  }) : super(key: key);

  @override
  _AudioMessageBubbleState createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPlaying = false;
  double _playbackPosition = 0.0;
  double _hologramHeight = 0.0;
  double _spatialAngle = 180.0;
  bool _showSpatialControls = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    
    // Calculate hologram height based on audio duration
    _hologramHeight = math.min(80.0, 20.0 + widget.duration / 2);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  Color _getMoodColor() {
    switch (widget.mood) {
      case 'happy':
        return Colors.amber;
      case 'excited':
        return Colors.orange;
      case 'calm':
        return Colors.blue;
      case 'focused':
        return Colors.teal;
      case 'curious':
        return Colors.cyan;
      case 'sad':
        return Colors.blueGrey;
      case 'angry':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }
  
  void _togglePlayback() async {
    final audioService = Provider.of<AudioService>(context, listen: false);
    
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    if (_isPlaying) {
      HapticFeedback.lightImpact();
      
      // Play the audio with spatial effect if controls are shown
      await audioService.playRecordedAudio(
        widget.audioPath, 
        spatialAudio: _showSpatialControls,
      );
      
      // Update spatial angle in service if needed
      if (_showSpatialControls) {
        audioService.setSpatialAngle(_spatialAngle);
      }
      
      // Simulate playback progress
      final totalFrames = widget.duration;
      for (int i = 0; i <= totalFrames; i++) {
        if (!mounted || !_isPlaying) break;
        
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          setState(() {
            _playbackPosition = i / totalFrames;
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = 0.0;
        });
      }
    }
  }
  
  void _toggleSpatialControls() {
    HapticFeedback.selectionClick();
    setState(() {
      _showSpatialControls = !_showSpatialControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final baseColor = _getMoodColor();
    final contrastColor = widget.isMe ? Colors.white : Colors.black87;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final sineValue = math.sin(_animationController.value * math.pi * 2);
        final pulseValue = 0.95 + sineValue * 0.05;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: baseColor.withOpacity(0.5),
                  child: Text(
                    widget.senderName.isNotEmpty ? widget.senderName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              Stack(
                children: [
                  // Holographic Audio Visualizer
                  if (_isPlaying || _showSpatialControls)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: _hologramHeight * pulseValue,
                        width: 200,
                        margin: const EdgeInsets.only(bottom: 60),
                        child: CustomPaint(
                          painter: AudioWaveformPainter(
                            animation: _animationController,
                            baseColor: baseColor,
                            isPlaying: _isPlaying,
                            progress: _playbackPosition,
                          ),
                        ),
                      ),
                    ),
                  
                  // Main Bubble
                  Transform.scale(
                    scale: _isPlaying ? 1.0 + sineValue * 0.02 : 1.0,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            baseColor.withOpacity(0.7),
                            baseColor.withOpacity(0.4),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: baseColor.withOpacity(_isPlaying ? 0.5 : 0.2),
                            blurRadius: 12,
                            spreadRadius: _isPlaying ? 2 : 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.black12,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Audio controls
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Play button
                                    GestureDetector(
                                      onTap: _togglePlayback,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: contrastColor.withOpacity(0.15),
                                        ),
                                        child: Icon(
                                          _isPlaying ? Icons.pause : Icons.play_arrow,
                                          color: contrastColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // Waveform and progress
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Custom waveform
                                          Container(
                                            height: 24,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                return CustomPaint(
                                                  size: Size(constraints.maxWidth, 24),
                                                  painter: WaveformPainter(
                                                    progress: _playbackPosition,
                                                    activeColor: contrastColor,
                                                    inactiveColor: contrastColor.withOpacity(0.3),
                                                    animation: _animationController,
                                                  ),
                                                );
                                              }
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 4),
                                          
                                          // Duration text
                                          Text(
                                            _formatDuration(widget.duration),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: contrastColor.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 8),
                                    
                                    // Spatial audio toggle
                                    GestureDetector(
                                      onTap: _toggleSpatialControls,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _showSpatialControls 
                                              ? baseColor 
                                              : contrastColor.withOpacity(0.15),
                                        ),
                                        child: Icon(
                                          Icons.spatial_audio,
                                          color: _showSpatialControls 
                                              ? Colors.white 
                                              : contrastColor,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Spatial audio controls
                                if (_showSpatialControls) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: contrastColor.withOpacity(0.1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '3D Spatial Position',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: contrastColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Circle indicator
                                            Container(
                                              width: 150,
                                              height: 150,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: contrastColor.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: CustomPaint(
                                                painter: SpatialAudioPainter(
                                                  angle: _spatialAngle,
                                                  color: baseColor,
                                                ),
                                              ),
                                            ),
                                            
                                            // Position indicator
                                            GestureDetector(
                                              onPanUpdate: (details) {
                                                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                                final position = renderBox.globalToLocal(details.globalPosition);
                                                
                                                // Calculate angle based on touch position relative to center
                                                final center = Offset(150 / 2, 150 / 2);
                                                final angle = math.atan2(
                                                  position.dy - center.dy,
                                                  position.dx - center.dx,
                                                ) * (180 / math.pi);
                                                
                                                setState(() {
                                                  _spatialAngle = (angle + 360) % 360;
                                                });
                                                
                                                // Update service
                                                Provider.of<AudioService>(context, listen: false)
                                                  .setSpatialAngle(_spatialAngle);
                                              },
                                              child: Transform.rotate(
                                                angle: _spatialAngle * (math.pi / 180),
                                                child: Container(
                                                  width: 150,
                                                  height: 150,
                                                  alignment: Alignment(0.8, 0),
                                                  child: Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: baseColor,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: baseColor.withOpacity(0.5),
                                                          blurRadius: 8,
                                                          spreadRadius: 2,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            // Center user icon
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white.withOpacity(0.8),
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                size: 18,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Angle: ${_spatialAngle.toStringAsFixed(0)}°',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: contrastColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Timestamp and encryption status
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.isEncrypted)
                                        Icon(
                                          Icons.enhanced_encryption,
                                          size: 12,
                                          color: contrastColor.withOpacity(0.6),
                                        ),
                                      if (widget.isEncrypted)
                                        const SizedBox(width: 4),
                                      Text(
                                        '${widget.timestamp.hour}:${widget.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: contrastColor.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Painter for the audio waveform visualization
class WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Animation<double> animation;
  
  WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.animation,
  }) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent pattern
    final barWidth = 3.0;
    final spacing = 2.0;
    final numBars = (size.width / (barWidth + spacing)).floor();
    
    for (int i = 0; i < numBars; i++) {
      final x = i * (barWidth + spacing);
      
      // Generate pseudo-random heights that look like an audio waveform
      final baseHeight = (0.2 + 
        0.8 * math.pow(math.sin(i / numBars * math.pi * 8), 2) * 
        (0.4 + 0.6 * random.nextDouble())
      );
      
      // Add animation effect based on current playback
      final heightMultiplier = progress > i / numBars
          ? 0.6 + 0.4 * math.sin(animation.value * math.pi * 8 + i)
          : 0.5;
          
      final height = size.height * baseHeight * heightMultiplier;
      
      // Determine if this bar should be active based on progress
      final isActive = progress > i / numBars;
      final color = isActive ? activeColor : inactiveColor;
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      final rect = Rect.fromLTWH(
        x,
        (size.height - height) / 2,
        barWidth,
        height,
      );
      
      // Draw rounded bars
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(1.5));
      canvas.drawRRect(rRect, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.activeColor != activeColor ||
           oldDelegate.inactiveColor != inactiveColor;
  }
}

// Painter for the floating audio visualization
class AudioWaveformPainter extends CustomPainter {
  final Animation<double> animation;
  final Color baseColor;
  final bool isPlaying;
  final double progress;
  
  AudioWaveformPainter({
    required this.animation,
    required this.baseColor,
    required this.isPlaying,
    required this.progress,
  }) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Draw background glow
    final glowPaint = Paint()
      ..color = baseColor.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width / 2, height * 0.7),
        width: width * 0.8,
        height: height * 0.5,
      ),
      glowPaint,
    );
    
    // Number of bars in the audio visualizer
    final barCount = 40;
    final barWidth = width / barCount;
    
    for (int i = 0; i < barCount; i++) {
      // Calculate bar position
      final x = i * barWidth;
      
      // Calculate height based on sine wave patterns
      double barHeightFactor = math.sin((i / barCount) * math.pi * 4 + animation.value * math.pi * 2);
      barHeightFactor = barHeightFactor.abs();
      
      // Adjust height based on playback
      if (isPlaying) {
        final playbackEffect = math.sin(animation.value * math.pi * 12 + i / 2);
        barHeightFactor *= (0.5 + 0.5 * playbackEffect.abs());
        
        // Reduce height of bars that haven't been played yet
        if (i / barCount > progress) {
          barHeightFactor *= 0.3;
        }
      } else {
        barHeightFactor *= 0.3;
      }
      
      // Bar height
      final barHeight = height * barHeightFactor * 0.8;
      
      // Draw the bar
      final paint = Paint()
        ..color = baseColor.withOpacity(0.6 * barHeightFactor)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + barWidth * 0.2,
            (height - barHeight) / 2,
            barWidth * 0.6,
            barHeight,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return oldDelegate.isPlaying != isPlaying || 
           oldDelegate.progress != progress ||
           oldDelegate.baseColor != baseColor;
  }
}

// Painter for the spatial audio control
class SpatialAudioPainter extends CustomPainter {
  final double angle;
  final Color color;
  
  SpatialAudioPainter({
    required this.angle,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Convert angle to radians
    final radians = angle * (math.pi / 180);
    
    // Draw directional indicator
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        radians - 0.5,
        1.0,
        false
      )
      ..lineTo(center.dx, center.dy)
      ..close();
    
    canvas.drawPath(path, paint);
    
    // Draw directional line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(radians),
        center.dy + radius * math.sin(radians),
      ),
      linePaint,
    );
    
    // Draw cardinal points
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    // North
    textPainter.text = const TextSpan(text: 'N', style: TextStyle(color: Colors.white70, fontSize: 10));
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - radius + 4));
    
    // East
    textPainter.text = const TextSpan(text: 'E', style: TextStyle(color: Colors.white70, fontSize: 10));
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx + radius - textPainter.width - 4, center.dy - textPainter.height / 2));
    
    // South
    textPainter.text = const TextSpan(text: 'S', style: TextStyle(color: Colors.white70, fontSize: 10));
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy + radius - textPainter.height - 4));
    
    // West
    textPainter.text = const TextSpan(text: 'W', style: TextStyle(color: Colors.white70, fontSize: 10));
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - radius + 4, center.dy - textPainter.height / 2));
  }
  
  @override
  bool shouldRepaint(covariant SpatialAudioPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.color != color;
  }
} 