import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../services/crypto_service.dart';
import '../services/story_service.dart';
import '../widgets/glass_card.dart';
import 'components/story_creator.dart';
import 'components/story_viewer.dart';

class StoryItem {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final String mediaUrl;
  final bool isEncrypted;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;
  
  StoryItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.mediaUrl,
    this.isEncrypted = true,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isLocked => isEncrypted && viewedBy.isEmpty;
}

class HoloRingsScreen extends StatefulWidget {
  const HoloRingsScreen({Key? key}) : super(key: key);

  @override
  _HoloRingsScreenState createState() => _HoloRingsScreenState();
}

class _HoloRingsScreenState extends State<HoloRingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<StoryItem> _stories = [];
  int _selectedStoryIndex = -1;
  bool _isUnlocking = false;
  double _unlockProgress = 0.0;
  bool _showBiometricPrompt = false;
  bool _showStoryCreator = false;
  String? _selectedStoryId;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    
    _loadSampleStories();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _loadSampleStories() {
    final now = DateTime.now();
    final sampleStories = [
      StoryItem(
        id: '1',
        userId: '1',
        userName: 'Alex Chen',
        content: 'Exploring the new quantum mesh network today!',
        mediaUrl: 'assets/stories/quantum_lab.jpg',
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 22)),
        viewedBy: [],
      ),
      StoryItem(
        id: '2',
        userId: '2',
        userName: 'Morgan Lee',
        content: 'Testing the new encryption protocol with some friends.',
        mediaUrl: 'assets/stories/encryption_test.jpg',
        createdAt: now.subtract(const Duration(hours: 5)),
        expiresAt: now.add(const Duration(hours: 19)),
        viewedBy: [],
      ),
      StoryItem(
        id: '3',
        userId: '3',
        userName: 'Taylor Kim',
        content: 'My view from the satellite uplink station.',
        mediaUrl: 'assets/stories/satellite_station.jpg',
        createdAt: now.subtract(const Duration(hours: 8)),
        expiresAt: now.add(const Duration(hours: 16)),
        viewedBy: ['1'],
      ),
      StoryItem(
        id: '4',
        userId: '5',
        userName: 'Jordan River',
        content: 'Found this ancient hardware at the tech museum.',
        mediaUrl: 'assets/stories/tech_museum.jpg',
        createdAt: now.subtract(const Duration(hours: 10)),
        expiresAt: now.add(const Duration(hours: 14)),
        viewedBy: [],
      ),
      StoryItem(
        id: '5',
        userId: '8',
        userName: 'Skyler Patel',
        content: 'Secret meeting at the cyber cafe.',
        mediaUrl: 'assets/stories/cyber_cafe.jpg',
        isEncrypted: true,
        createdAt: now.subtract(const Duration(hours: 4)),
        expiresAt: now.add(const Duration(hours: 20)),
        viewedBy: [],
      ),
    ];
    
    setState(() {
      _stories.addAll(sampleStories);
    });
  }
  
  void _handleRingTap(int index) {
    HapticFeedback.selectionClick();
    final story = _stories[index];
    
    if (story.isLocked) {
      setState(() {
        _selectedStoryIndex = index;
        _isUnlocking = true;
        _unlockProgress = 0.0;
      });
    } else {
      _viewStory(index);
    }
  }
  
  void _viewStory(int index) {
    setState(() {
      if (!_stories[index].viewedBy.contains('1')) {
        final updatedViewers = List<String>.from(_stories[index].viewedBy)..add('1');
        _stories[index] = StoryItem(
          id: _stories[index].id,
          userId: _stories[index].userId,
          userName: _stories[index].userName,
          content: _stories[index].content,
          mediaUrl: _stories[index].mediaUrl,
          isEncrypted: _stories[index].isEncrypted,
          createdAt: _stories[index].createdAt,
          expiresAt: _stories[index].expiresAt,
          viewedBy: updatedViewers,
        );
      }
      
      _selectedStoryIndex = index;
      _isUnlocking = false;
    });
  }
  
  void _handleUnlockGesture(double progress) {
    setState(() {
      _unlockProgress = progress;
      
      if (progress >= 1.0) {
        _showBiometricPrompt = true;
        
        // Simulate biometric auth success after a delay
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _showBiometricPrompt) {
            setState(() {
              _showBiometricPrompt = false;
              _isUnlocking = false;
              _viewStory(_selectedStoryIndex);
            });
          }
        });
      }
    });
  }
  
  void _closeStoryView() {
    setState(() {
      _selectedStoryIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'HoloRings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black12,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create story coming soon')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a1a3a),
                  const Color(0xFF0f0f22),
                  Color.lerp(const Color(0xFF0f0f22), Colors.purple, 0.1)!,
                ],
              ),
            ),
          ),
          
          // Rings grid
          if (_selectedStoryIndex == -1 && !_isUnlocking)
            SafeArea(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _stories.length,
                itemBuilder: (context, index) {
                  final story = _stories[index];
                  return _buildStoryRing(story, index);
                },
              ),
            ),
          
          // Story view
          if (_selectedStoryIndex >= 0 && !_isUnlocking)
            _buildStoryView(_stories[_selectedStoryIndex]),
          
          // Unlock interface
          if (_isUnlocking && _selectedStoryIndex >= 0)
            _buildUnlockInterface(_stories[_selectedStoryIndex]),
          
          // Biometric authentication overlay
          if (_showBiometricPrompt)
            _buildBiometricPrompt(),
        ],
      ),
    );
  }
  
  Widget _buildStoryRing(StoryItem story, int index) {
    final hasViewed = story.viewedBy.contains('1');
    final ringColor = story.isLocked ? Colors.amber : (hasViewed ? Colors.grey : Colors.cyanAccent);
    
    return GestureDetector(
      onTap: () => _handleRingTap(index),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  story.isLocked
                      ? Colors.amber.withOpacity(0.1)
                      : (hasViewed ? Colors.grey.withOpacity(0.1) : Colors.cyanAccent.withOpacity(0.1)),
                ],
                stops: const [0.0, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: ringColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating ring
                CustomPaint(
                  painter: HoloRingPainter(
                    progress: _animationController.value,
                    color: ringColor,
                    viewProgress: hasViewed ? 1.0 : (story.viewedBy.length / 10).clamp(0.0, 1.0),
                    isLocked: story.isLocked,
                  ),
                  size: Size.fromRadius(MediaQuery.of(context).size.width / 4 - 16),
                ),
                
                // Story preview (blurred if locked)
                Center(
                  child: ClipOval(
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 32,
                      height: MediaQuery.of(context).size.width / 4 - 32,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        image: story.isLocked
                            ? null
                            : DecorationImage(
                                image: AssetImage(story.mediaUrl),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: story.isLocked
                          ? BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Center(
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.amber.withOpacity(0.7),
                                  size: 24,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                
                // User name
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Text(
                    story.userName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Lock icon for encrypted stories
                if (story.isLocked)
                  Positioned(
                    top: 10,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.amber.withOpacity(0.8),
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStoryView(StoryItem story) {
    return Stack(
      children: [
        // Story content
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Image.asset(
            story.mediaUrl,
            fit: BoxFit.cover,
          ),
        ),
        
        // Holographic overlay
        CustomPaint(
          painter: HolographicOverlayPainter(
            animation: _animationController,
          ),
          size: MediaQuery.of(context).size,
        ),
        
        // Top gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Bottom info panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.purple.withOpacity(0.5),
                          child: Text(
                            story.userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatTimeAgo(story.createdAt),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (story.isEncrypted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_open,
                                  color: Colors.amber.withOpacity(0.8),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Decrypted',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      story.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expires in ${_formatExpiryTime(story.expiresAt)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Viewed by ${story.viewedBy.length} people',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Close button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _closeStoryView,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white30,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUnlockInterface(StoryItem story) {
    final cryptoService = Provider.of<CryptoService>(context, listen: false);
    
    return Stack(
      children: [
        // Background
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a3a),
                const Color(0xFF0f0f22),
              ],
            ),
          ),
        ),
        
        // Holographic grid
        CustomPaint(
          painter: HolographicGridPainter(
            animation: _animationController,
          ),
          size: MediaQuery.of(context).size,
        ),
        
        // Unlock interface
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ENCRYPTED CONTENT',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'from ${story.userName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              
              // Unlock ring
              GestureDetector(
                onPanUpdate: (details) {
                  // Calculate angle from center
                  final centerX = MediaQuery.of(context).size.width / 2;
                  final centerY = MediaQuery.of(context).size.height / 2;
                  final touchX = details.globalPosition.dx;
                  final touchY = details.globalPosition.dy;
                  
                  final angle = math.atan2(touchY - centerY, touchX - centerX);
                  final normalizedAngle = (angle + math.pi) / (2 * math.pi);
                  
                  _handleUnlockGesture(normalizedAngle);
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress indicator
                      CircularProgressIndicator(
                        value: _unlockProgress,
                        strokeWidth: 4,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(Colors.amber, Colors.green, _unlockProgress)!,
                        ),
                      ),
                      
                      // Lock icon
                      Icon(
                        _unlockProgress > 0.9 ? Icons.lock_open : Icons.lock,
                        color: Colors.white.withOpacity(0.8),
                        size: 40,
                      ),
                      
                      // Instructional text
                      Positioned(
                        bottom: 30,
                        child: Text(
                          'ROTATE TO UNLOCK',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              Text(
                'Using ${cryptoService.getEncryptionType()} encryption',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Posted ${_formatTimeAgo(story.createdAt)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // Cancel button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isUnlocking = false;
                  _selectedStoryIndex = -1;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white30,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBiometricPrompt() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white10,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fingerprint,
                color: Colors.cyanAccent,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                'IDENTITY VERIFICATION',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatTimeAgo(DateTime time) {
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
  
  String _formatExpiryTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'expiring';
    }
  }
}

class HoloRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double viewProgress;
  final bool isLocked;
  
  HoloRingPainter({
    required this.progress,
    required this.color,
    required this.viewProgress,
    required this.isLocked,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background ring
    final backRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withOpacity(0.1);
    
    canvas.drawCircle(center, radius - 2, backRingPaint);
    
    // View progress
    if (viewProgress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = color;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        -math.pi / 2,
        2 * math.pi * viewProgress,
        false,
        progressPaint,
      );
    }
    
    // Holographic glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0),
          color.withOpacity(0.2),
          color.withOpacity(0.8),
          color.withOpacity(0.2),
          color.withOpacity(0),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, glowPaint);
    
    // Lock symbol
    if (isLocked) {
      final lockAngle = progress * math.pi * 2;
      final lockX = center.dx + math.cos(lockAngle) * (radius - 10);
      final lockY = center.dy + math.sin(lockAngle) * (radius - 10);
      
      final lockPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(lockX, lockY), 4, lockPaint);
    }
  }
  
  @override
  bool shouldRepaint(HoloRingPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.color != color || 
           oldDelegate.viewProgress != viewProgress ||
           oldDelegate.isLocked != isLocked;
  }
}

class HolographicOverlayPainter extends CustomPainter {
  final Animation<double> animation;
  
  HolographicOverlayPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Draw horizontal scan lines
    final scanLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    final scanLineCount = 100;
    final scanLineSpacing = height / scanLineCount;
    
    for (int i = 0; i < scanLineCount; i++) {
      final y = i * scanLineSpacing;
      canvas.drawLine(Offset(0, y), Offset(width, y), scanLinePaint);
    }
    
    // Draw moving holographic glitch
    final glitchHeight = 5.0;
    final glitchY = (animation.value * height) % height;
    
    final glitchPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, glitchY, width, glitchHeight),
      glitchPaint,
    );
    
    // Draw vignette effect
    final vignetteRect = Rect.fromLTWH(0, 0, width, height);
    final vignetteGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.5),
      ],
      stops: const [0.6, 1.0],
    );
    
    final vignettePaint = Paint()
      ..shader = vignetteGradient.createShader(vignetteRect)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(vignetteRect, vignettePaint);
  }
  
  @override
  bool shouldRepaint(HolographicOverlayPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class HolographicGridPainter extends CustomPainter {
  final Animation<double> animation;
  
  HolographicGridPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.amber.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Horizontal grid lines
    final hSpacing = 20.0;
    final hLineCount = (height / hSpacing).ceil();
    
    for (int i = 0; i < hLineCount; i++) {
      final y = i * hSpacing;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(width, y);
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Vertical grid lines
    final vSpacing = 20.0;
    final vLineCount = (width / vSpacing).ceil();
    
    for (int i = 0; i < vLineCount; i++) {
      final x = i * vSpacing;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x, height);
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Pulsing concentric circles
    final centerX = width / 2;
    final centerY = height / 2;
    final maxRadius = math.sqrt(width * width + height * height) / 2;
    
    final circleCount = 5;
    
    for (int i = 0; i < circleCount; i++) {
      final adjustedProgress = (animation.value + i / circleCount) % 1.0;
      final radius = adjustedProgress * maxRadius;
      final opacity = (1.0 - adjustedProgress) * 0.3;
      
      final circlePaint = Paint()
        ..color = Colors.amber.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawCircle(Offset(centerX, centerY), radius, circlePaint);
    }
  }
  
  @override
  bool shouldRepaint(HolographicGridPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
} 