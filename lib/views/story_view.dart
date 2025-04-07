import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:secure_mesh_messenger/models/chat.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/services/theme_service.dart';
import 'package:local_auth/local_auth.dart';

class StoryView extends StatefulWidget {
  final Chat storyChat;
  
  const StoryView({
    Key? key,
    required this.storyChat,
  }) : super(key: key);
  
  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Message> _storyItems = [];
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isLocked = true;
  bool _isUnlocking = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
    
    _loadStoryItems();
    
    // Auto-unlock if biometric not required
    if (!widget.storyChat.requiresBiometric) {
      _unlockStory();
    }
  }
  
  void _loadStoryItems() {
    // Sample story items - replace with actual data loading
    _storyItems.addAll([
      Message.image(
        id: '1',
        chatId: widget.storyChat.id,
        senderId: widget.storyChat.participantIds[0],
        isMe: false,
        mediaPath: 'assets/story1.jpg',
        content: 'A beautiful day at the beach!',
        emotion: 'happy',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.delivered,
      ),
      Message.text(
        id: '2',
        chatId: widget.storyChat.id,
        senderId: widget.storyChat.participantIds[0],
        content: 'Just had the most amazing adventure today!',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MessageStatus.delivered,
        emotion: 'excited',
      ),
      Message.ar(
        id: '3',
        chatId: widget.storyChat.id,
        senderId: widget.storyChat.participantIds[0],
        isMe: false,
        content: 'Check out this AR effect!',
        mediaPath: 'assets/ar_effect.jpg',
        arEffectId: 'nebula_effect',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: MessageStatus.delivered,
      ),
    ]);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _authenticate() async {
    try {
      setState(() {
        _isUnlocking = true;
      });
      
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      if (canCheckBiometrics) {
        bool authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to view this encrypted story',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        
        if (authenticated) {
          _unlockStory();
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() {
        _isUnlocking = false;
      });
    }
  }
  
  void _unlockStory() {
    setState(() {
      _isLocked = false;
    });
    _controller.forward();
    
    // Trigger haptic feedback for successful unlock
    HapticFeedback.heavyImpact();
  }
  
  void _nextStory() {
    if (_currentIndex < _storyItems.length - 1) {
      setState(() {
        _currentIndex++;
        _controller.reset();
      });
      _controller.forward();
    } else {
      // End of stories, close the view
      Navigator.of(context).pop();
    }
  }
  
  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _controller.reset();
      });
      _controller.forward();
    }
  }
  
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _controller.stop();
      } else {
        _controller.forward();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background blur effect
          if (!_isLocked)
            ..._buildBackgroundEffects(themeService),
          
          // Story content or lock screen
          if (_isLocked)
            _buildLockScreen(themeService, size)
          else
            _buildStoryContent(themeService),
          
          // Story progress indicators
          if (!_isLocked)
            _buildProgressIndicators(),
          
          // Controls
          if (!_isLocked)
            _buildControls(),
        ],
      ),
    );
  }
  
  List<Widget> _buildBackgroundEffects(ThemeService themeService) {
    final currentMessage = _storyItems[_currentIndex];
    final emotion = currentMessage.emotion ?? 'neutral';
    
    return [
      // Color overlay based on emotion
      Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              _getEmotionColor(emotion, themeService).withOpacity(0.3),
              Colors.black,
            ],
            radius: 1.5,
          ),
        ),
      ),
      
      // Particle effect
      RepaintBoundary(
        child: CustomPaint(
          painter: _ParticleEffectPainter(
            color: _getEmotionColor(emotion, themeService),
            particleCount: 50,
            speed: 0.5,
          ),
          size: Size.infinite,
        ),
      ),
    ];
  }
  
  Widget _buildLockScreen(ThemeService themeService, Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Encrypted HoloRing
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeService.currentColorScheme.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).rotate(
                duration: const Duration(seconds: 10),
              ),
              
              // Middle ring
              Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeService.currentColorScheme.secondary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).rotate(
                duration: const Duration(seconds: 15),
                direction: AnimateDirection.reverse,
              ),
              
              // Inner ring
              Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeService.currentColorScheme.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).rotate(
                duration: const Duration(seconds: 20),
              ),
              
              // Lock icon in center
              Container(
                width: size.width * 0.4,
                height: size.width * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.6),
                  border: Border.all(
                    color: themeService.currentColorScheme.primary,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock,
                    color: themeService.currentColorScheme.primary,
                    size: 48,
                  ).animate(
                    onPlay: (controller) => controller.repeat(),
                  ).shimmer(
                    duration: const Duration(seconds: 3),
                    color: themeService.currentColorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Unlock button
          ElevatedButton(
            onPressed: _isUnlocking ? null : _authenticate,
            style: ElevatedButton.styleFrom(
              foregroundColor: themeService.currentColorScheme.onPrimary,
              backgroundColor: themeService.currentColorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isUnlocking
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: themeService.currentColorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Unlock with Biometrics'),
          ),
          
          const SizedBox(height: 16),
          
          // User info
          Text(
            widget.storyChat.name,
            style: TextStyle(
              color: themeService.currentColorScheme.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posted ${_formatTime(_storyItems.first.timestamp)}',
            style: TextStyle(
              color: themeService.currentColorScheme.onBackground.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStoryContent(ThemeService themeService) {
    final currentMessage = _storyItems[_currentIndex];
    
    Widget content;
    
    switch (currentMessage.type) {
      case MessageType.image:
        content = _buildImageStory(currentMessage, themeService);
        break;
      case MessageType.ar:
        content = _buildArStory(currentMessage, themeService);
        break;
      case MessageType.text:
      default:
        content = _buildTextStory(currentMessage, themeService);
        break;
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<int>(_currentIndex),
        child: content,
      ),
    );
  }
  
  Widget _buildImageStory(Message message, ThemeService themeService) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder image - replace with actual image loading
        Container(
          color: Colors.blue,
          child: Center(
            child: Icon(
              Icons.image,
              size: 100,
              color: themeService.currentColorScheme.onPrimary,
            ),
          ),
        ),
        
        // Text overlay
        if (message.content.isNotEmpty)
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeService.currentColorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildTextStory(Message message, ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getEmotionColor(message.emotion ?? 'neutral', themeService).withOpacity(0.2),
            Colors.black,
          ],
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeService.currentColorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  Widget _buildArStory(Message message, ThemeService themeService) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder AR image - replace with actual AR content
        Container(
          color: Colors.black,
          child: Center(
            child: Icon(
              Icons.view_in_ar,
              size: 100,
              color: themeService.currentColorScheme.primary,
            ),
          ),
        ),
        
        // AR effects overlay
        CustomPaint(
          painter: _ArEffectPainter(
            color: themeService.currentColorScheme.primary,
          ),
          size: Size.infinite,
        ),
        
        // Text overlay
        if (message.content.isNotEmpty)
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeService.currentColorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        
        // AR badge
        Positioned(
          top: 60,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeService.currentColorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_in_ar,
                  color: themeService.currentColorScheme.onPrimary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'AR Effect',
                  style: TextStyle(
                    color: themeService.currentColorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressIndicators() {
    return Positioned(
      top: 44,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(
          _storyItems.length,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: LinearProgressIndicator(
                value: index < _currentIndex
                    ? 1.0
                    : index == _currentIndex
                        ? _controller.value
                        : 0.0,
                backgroundColor: Colors.grey.withOpacity(0.5),
                color: Colors.white,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildControls() {
    return Stack(
      children: [
        // Close button
        Positioned(
          top: 44,
          right: 16,
          child: IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        
        // User info
        Positioned(
          top: 44,
          left: 16,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(
                  widget.storyChat.name[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.storyChat.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Navigation gesture areas
        Row(
          children: [
            // Previous story area
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: _previousStory,
                behavior: HitTestBehavior.opaque,
              ),
            ),
            
            // Pause/play area
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: _togglePause,
                behavior: HitTestBehavior.opaque,
              ),
            ),
            
            // Next story area
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: _nextStory,
                behavior: HitTestBehavior.opaque,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Color _getEmotionColor(String emotion, ThemeService themeService) {
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
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _ParticleEffectPainter extends CustomPainter {
  final Color color;
  final int particleCount;
  final double speed;
  final List<_Particle> particles = [];
  final math.Random random = math.Random();
  
  _ParticleEffectPainter({
    required this.color,
    this.particleCount = 30,
    this.speed = 1.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) {
      _initializeParticles(size);
    }
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (var particle in particles) {
      // Update position
      particle.position = Offset(
        (particle.position.dx + particle.velocity.dx * speed) % size.width,
        (particle.position.dy + particle.velocity.dy * speed) % size.height,
      );
      
      // Draw particle
      canvas.drawCircle(
        particle.position,
        particle.size,
        paint.copyWith(color: color.withOpacity(particle.opacity)),
      );
    }
  }
  
  void _initializeParticles(Size size) {
    for (var i = 0; i < particleCount; i++) {
      particles.add(
        _Particle(
          position: Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
          ),
          velocity: Offset(
            random.nextDouble() * 2 - 1,
            random.nextDouble() * 2 - 1,
          ),
          size: random.nextDouble() * 3 + 1,
          opacity: random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
  }
  
  @override
  bool shouldRepaint(_ParticleEffectPainter oldDelegate) => true;
}

class _ArEffectPainter extends CustomPainter {
  final Color color;
  final math.Random random = math.Random();
  final List<_ArLine> lines = [];
  
  _ArEffectPainter({
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (lines.isEmpty) {
      _initializeLines(size);
    }
    
    for (var line in lines) {
      final paint = Paint()
        ..color = color.withOpacity(line.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = line.width;
      
      final path = Path();
      path.moveTo(line.start.dx, line.start.dy);
      
      for (var i = 0; i < line.points.length; i++) {
        path.lineTo(line.points[i].dx, line.points[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
  }
  
  void _initializeLines(Size size) {
    for (var i = 0; i < 10; i++) {
      final start = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      
      final points = <Offset>[];
      var currentPoint = start;
      
      for (var j = 0; j < 5; j++) {
        currentPoint = Offset(
          (currentPoint.dx + random.nextDouble() * 100 - 50).clamp(0, size.width),
          (currentPoint.dy + random.nextDouble() * 100 - 50).clamp(0, size.height),
        );
        points.add(currentPoint);
      }
      
      lines.add(
        _ArLine(
          start: start,
          points: points,
          width: random.nextDouble() * 2 + 0.5,
          opacity: random.nextDouble() * 0.7 + 0.1,
        ),
      );
    }
  }
  
  @override
  bool shouldRepaint(_ArEffectPainter oldDelegate) => false;
}

class _Particle {
  Offset position;
  final Offset velocity;
  final double size;
  final double opacity;
  
  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
  });
}

class _ArLine {
  final Offset start;
  final List<Offset> points;
  final double width;
  final double opacity;
  
  _ArLine({
    required this.start,
    required this.points,
    required this.width,
    required this.opacity,
  });
} 