import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HolographicAvatar extends StatefulWidget {
  final String? imagePath;
  final String? initials;
  final double size;
  final Color primaryColor;
  final bool isActive;
  final bool isAnimating;
  final VoidCallback? onTap;

  const HolographicAvatar({
    Key? key,
    this.imagePath,
    this.initials,
    this.size = 120.0,
    this.primaryColor = Colors.blue,
    this.isActive = true,
    this.isAnimating = true,
    this.onTap,
  }) : super(key: key);

  @override
  _HolographicAvatarState createState() => _HolographicAvatarState();
}

class _HolographicAvatarState extends State<HolographicAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationY = 0.0;
  double _rotationX = 0.0;
  double _scale = 1.0;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotationY += details.delta.dx * 0.01;
      _rotationX -= details.delta.dy * 0.01;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _rotationY = 0.0;
      _rotationX = 0.0;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = details.scale.clamp(0.8, 1.2);
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_rotationX)
              ..rotateY(_rotationY + (_controller.value * 0.05 * (widget.isAnimating ? 1 : 0)))
              ..scale(_isPressed ? 0.95 : _scale),
            child: SizedBox(
              height: widget.size,
              width: widget.size,
              child: Stack(
                children: [
                  // Glow background
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  
                  // Main avatar circle with backdrop filter
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.primaryColor.withOpacity(0.8),
                              widget.primaryColor.withOpacity(0.3),
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            center: Alignment.center,
                            focal: Alignment.center,
                            focalRadius: 0.1,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: _buildAvatarContent(),
                        ),
                      ),
                    ),
                  ),
                  
                  // Scan line effect
                  if (widget.isAnimating)
                    Positioned.fill(
                      child: ClipOval(
                        child: _buildScanEffect(),
                      ),
                    ),
                  
                  // Status indicator
                  if (widget.isActive)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Holographic ring
                  Positioned.fill(
                    child: CustomPaint(
                      painter: HolographicRingPainter(
                        animation: _controller,
                        color: widget.primaryColor,
                      ),
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

  Widget _buildAvatarContent() {
    if (widget.imagePath != null) {
      return ClipOval(
        child: Image.asset(
          widget.imagePath!,
          width: widget.size * 0.85,
          height: widget.size * 0.85,
          fit: BoxFit.cover,
        ),
      );
    } else if (widget.initials != null) {
      return Text(
        widget.initials!,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.size * 0.35,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: widget.primaryColor.withOpacity(0.8),
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      );
    } else {
      return Icon(
        Icons.person,
        color: Colors.white.withOpacity(0.8),
        size: widget.size * 0.5,
      );
    }
  }

  Widget _buildScanEffect() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Transform.translate(
          offset: Offset(
            0,
            constraints.maxHeight * (_controller.value * 2 - 1),
          ),
          child: Container(
            height: constraints.maxHeight * 0.15,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HolographicRingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  HolographicRingPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw multiple circular paths with different dash patterns
    for (int i = 0; i < 3; i++) {
      final paint = Paint()
        ..color = color.withOpacity(0.3 - i * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      
      final dashCount = 20 + i * 10;
      final dashLength = 2.0 * math.pi * radius / dashCount * 0.7;
      final dashSpace = 2.0 * math.pi * radius / dashCount * 0.3;
      final dashOffset = animation.value * 2 * math.pi + i * 0.5;
      
      final path = Path();
      
      for (int j = 0; j < dashCount; j++) {
        final startAngle = j * (dashLength + dashSpace) / radius + dashOffset;
        final endAngle = startAngle + dashLength / radius;
        
        path.addArc(
          Rect.fromCircle(center: center, radius: radius - i * 4),
          startAngle,
          dashLength / radius,
        );
      }
      
      canvas.drawPath(path, paint);
    }
    
    // Draw circular glint effect
    final glintPosition = Offset(
      center.dx + radius * 0.7 * math.cos(animation.value * 2 * math.pi),
      center.dy + radius * 0.7 * math.sin(animation.value * 2 * math.pi),
    );
    
    final glintGradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.8),
        Colors.white.withOpacity(0.3),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    final glintPaint = Paint()
      ..shader = glintGradient.createShader(
        Rect.fromCircle(center: glintPosition, radius: 10),
      );
    
    canvas.drawCircle(glintPosition, 10, glintPaint);
  }

  @override
  bool shouldRepaint(covariant HolographicRingPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.color != color;
  }
} 