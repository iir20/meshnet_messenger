import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:secure_mesh_messenger/services/theme_service.dart';

class HolographicAvatar extends StatefulWidget {
  final String userId;
  final String? name;
  final String? avatarUrl;
  final String? emotion;
  final double size;
  final bool isAnimated;
  final VoidCallback? onTap;
  final Color? accentColor;
  
  const HolographicAvatar({
    Key? key,
    required this.userId,
    this.name,
    this.avatarUrl,
    this.emotion,
    this.size = 50.0,
    this.isAnimated = true,
    this.onTap,
    this.accentColor,
  }) : super(key: key);
  
  @override
  State<HolographicAvatar> createState() => _HolographicAvatarState();
}

class _HolographicAvatarState extends State<HolographicAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();
  final List<HoloRing> _rings = [];
  final List<HoloParticle> _particles = [];
  final List<HoloSpark> _sparks = [];
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _initializeEffects();
  }
  
  void _initializeEffects() {
    // Create rings around the avatar
    for (int i = 0; i < 3; i++) {
      _rings.add(HoloRing(
        radius: widget.size * 0.6 + (i * widget.size * 0.15),
        rotationSpeed: _random.nextDouble() * 0.2 + 0.1,
        clockwise: i % 2 == 0,
        opacity: 0.2 + (3 - i) * 0.1,
      ));
    }
    
    // Create particles
    for (int i = 0; i < 12; i++) {
      _particles.add(HoloParticle(
        angle: _random.nextDouble() * 2 * math.pi,
        distance: _random.nextDouble() * widget.size * 0.4 + widget.size * 0.6,
        size: _random.nextDouble() * 4 + 1,
        opacity: _random.nextDouble() * 0.5 + 0.3,
        orbitSpeed: _random.nextDouble() * 0.2 + 0.05,
      ));
    }
    
    // Create sparks
    for (int i = 0; i < 5; i++) {
      _sparks.add(HoloSpark(
        position: Offset(
          _random.nextDouble() * widget.size - widget.size / 2,
          _random.nextDouble() * widget.size - widget.size / 2,
        ),
        size: _random.nextDouble() * 4 + 2,
        lifespan: _random.nextDouble() * 2 + 1,
        startTime: _random.nextDouble() * 10,
      ));
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Theme.of(context).extension<ThemeService>() ??
        ThemeService(); // Fallback
    
    final accentColor = widget.accentColor ?? _getEmotionColor(themeService);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: widget.size * 2,
            height: widget.size * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rings
                if (widget.isAnimated)
                  ..._rings.map((ring) => _buildRing(ring, accentColor)),
                
                // Core avatar
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.6),
                    border: Border.all(
                      color: accentColor.withOpacity(0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _buildAvatarContent(),
                ),
                
                // Particles
                if (widget.isAnimated)
                  ..._particles.map((particle) => _buildParticle(particle, accentColor)),
                
                // Sparks
                if (widget.isAnimated)
                  ..._sparks.map((spark) => _buildSpark(spark, accentColor)),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAvatarContent() {
    if (widget.avatarUrl != null) {
      return ClipOval(
        child: Image.network(
          widget.avatarUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar();
          },
        ),
      );
    } else {
      return _buildFallbackAvatar();
    }
  }
  
  Widget _buildFallbackAvatar() {
    final name = widget.name ?? widget.userId;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.size / 2.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildRing(HoloRing ring, Color color) {
    final rotationAngle = _controller.value * 2 * math.pi * ring.rotationSpeed * (ring.clockwise ? 1 : -1);
    
    return Container(
      width: ring.radius * 2,
      height: ring.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(ring.opacity),
          width: 1,
        ),
      ),
      child: Transform.rotate(
        angle: rotationAngle,
        child: CustomPaint(
          painter: _RingPainter(
            color: color.withOpacity(ring.opacity),
            dashCount: (ring.radius ~/ 5).clamp(10, 30),
            dashWidth: 3,
          ),
        ),
      ),
    );
  }
  
  Widget _buildParticle(HoloParticle particle, Color color) {
    final time = _controller.value * 10;
    final angle = particle.angle + time * particle.orbitSpeed;
    
    final x = math.cos(angle) * particle.distance;
    final y = math.sin(angle) * particle.distance;
    
    return Positioned(
      left: widget.size + x - particle.size / 2,
      top: widget.size + y - particle.size / 2,
      child: Container(
        width: particle.size,
        height: particle.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(particle.opacity),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(particle.opacity * 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpark(HoloSpark spark, Color color) {
    final time = (_controller.value * 10 + spark.startTime) % (spark.lifespan * 2);
    final opacity = time < spark.lifespan
        ? time / spark.lifespan
        : 2 - time / spark.lifespan;
        
    return Positioned(
      left: widget.size + spark.position.dx,
      top: widget.size + spark.position.dy,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: spark.size,
          height: spark.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.8),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getEmotionColor(ThemeService themeService) {
    final emotion = widget.emotion?.toLowerCase() ?? 'neutral';
    
    switch (emotion) {
      case 'happy':
        return Colors.yellow;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'excited':
        return Colors.orange;
      case 'curious':
        return Colors.purple;
      default:
        return themeService.currentColorScheme.primary;
    }
  }
}

class AvatarEmotionDetector extends StatefulWidget {
  final String userId;
  final String? name;
  final String? avatarUrl;
  final String initialEmotion;
  final double size;
  final Widget Function(String emotion) builder;
  
  const AvatarEmotionDetector({
    Key? key,
    required this.userId,
    this.name,
    this.avatarUrl,
    this.initialEmotion = 'neutral',
    this.size = 50.0,
    required this.builder,
  }) : super(key: key);
  
  @override
  State<AvatarEmotionDetector> createState() => _AvatarEmotionDetectorState();
}

class _AvatarEmotionDetectorState extends State<AvatarEmotionDetector> {
  late String _currentEmotion;
  
  @override
  void initState() {
    super.initState();
    _currentEmotion = widget.initialEmotion;
    
    // Simulate emotion changes for demo purposes
    _initEmotionDetection();
  }
  
  void _initEmotionDetection() {
    // In a real app, this would use ML to detect emotions from text/camera
    // For demo, we'll just randomly change emotions
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      
      final emotions = ['happy', 'sad', 'neutral', 'excited', 'curious', 'angry'];
      final newEmotion = emotions[math.Random().nextInt(emotions.length)];
      
      setState(() {
        _currentEmotion = newEmotion;
      });
      
      _initEmotionDetection(); // Schedule next update
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.builder(_currentEmotion);
  }
}

class HolographicAvatarGroup extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final double avatarSize;
  final double spacing;
  final int maxDisplayed;
  
  const HolographicAvatarGroup({
    Key? key,
    required this.users,
    this.avatarSize = 40.0,
    this.spacing = 10.0,
    this.maxDisplayed = 3,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final displayCount = users.length > maxDisplayed ? maxDisplayed : users.length;
    final hasMore = users.length > maxDisplayed;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(displayCount, (index) {
          final user = users[index];
          return Padding(
            padding: EdgeInsets.only(right: spacing),
            child: HolographicAvatar(
              userId: user['id'],
              name: user['name'],
              avatarUrl: user['avatarUrl'],
              emotion: user['emotion'],
              size: avatarSize,
              isAnimated: false,
            ),
          );
        }),
        if (hasMore)
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.6),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '+${users.length - maxDisplayed}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: avatarSize / 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Helper classes for holographic effects

class HoloRing {
  final double radius;
  final double rotationSpeed;
  final bool clockwise;
  final double opacity;
  
  HoloRing({
    required this.radius,
    required this.rotationSpeed,
    required this.clockwise,
    required this.opacity,
  });
}

class HoloParticle {
  final double angle;
  final double distance;
  final double size;
  final double opacity;
  final double orbitSpeed;
  
  HoloParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.opacity,
    required this.orbitSpeed,
  });
}

class HoloSpark {
  final Offset position;
  final double size;
  final double lifespan;
  final double startTime;
  
  HoloSpark({
    required this.position,
    required this.size,
    required this.lifespan,
    required this.startTime,
  });
}

class _RingPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double dashWidth;
  
  _RingPainter({
    required this.color,
    required this.dashCount,
    required this.dashWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = dashWidth
      ..strokeCap = StrokeCap.round;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    for (int i = 0; i < dashCount; i++) {
      final angle = (i / dashCount) * 2 * math.pi;
      final spanAngle = 0.5 / dashCount * 2 * math.pi;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        spanAngle,
        false,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_RingPainter oldDelegate) => 
      oldDelegate.color != color || 
      oldDelegate.dashCount != dashCount || 
      oldDelegate.dashWidth != dashWidth;
} 