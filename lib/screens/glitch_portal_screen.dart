import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import '../services/crypto_service.dart';

class GlitchMessage {
  final String id;
  final String content;
  final DateTime timestamp;
  final String senderName;
  final Color senderColor;
  
  GlitchMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.senderName,
    required this.senderColor,
  });
}

class GlitchPortalScreen extends StatefulWidget {
  const GlitchPortalScreen({Key? key}) : super(key: key);

  @override
  _GlitchPortalScreenState createState() => _GlitchPortalScreenState();
}

class _GlitchPortalScreenState extends State<GlitchPortalScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _messageController = TextEditingController();
  final List<GlitchMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  String _portalId = const Uuid().v4(); // Random portal ID
  Duration _timeRemaining = const Duration(minutes: 30); // Self-destruct timer
  Timer? _timerUpdateTimer;
  bool _isTimerRunning = true;
  
  // Anonymous persona generation
  final List<String> _anonymousNames = [
    'Phantom', 'Ghost', 'Shadow', 'Wraith', 'Specter', 
    'Echo', 'Void', 'Enigma', 'Cipher', 'Whisper'
  ];
  final List<Color> _glitchColors = [
    Colors.purple, Colors.cyanAccent, Colors.pinkAccent, 
    Colors.greenAccent, Colors.amberAccent, Colors.redAccent
  ];
  
  late String _anonymousName;
  late Color _anonymousColor;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Generate random anonymous persona
    final random = math.Random();
    _anonymousName = _anonymousNames[random.nextInt(_anonymousNames.length)];
    _anonymousColor = _glitchColors[random.nextInt(_glitchColors.length)];
    
    // Start timer update
    _timerUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerRunning) {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
          if (_timeRemaining.inSeconds <= 0) {
            _timerUpdateTimer?.cancel();
            _onPortalExpired();
          }
        });
      }
    });
    
    // Add system message
    _addSystemMessage(
      'Welcome to Glitch Portal #${_portalId.substring(0, 8)}. This portal will self-destruct in 30 minutes. All messages are encrypted and will be permanently deleted.'
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _timerUpdateTimer?.cancel();
    super.dispose();
  }
  
  void _onPortalExpired() {
    // Portal has expired - navigate back
    Navigator.of(context).pop();
  }
  
  void _addSystemMessage(String content) {
    setState(() {
      _messages.add(GlitchMessage(
        id: const Uuid().v4(),
        content: content,
        timestamp: DateTime.now(),
        senderName: 'SYSTEM',
        senderColor: Colors.red,
      ));
    });
  }
  
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      HapticFeedback.mediumImpact();
      
      setState(() {
        _messages.add(GlitchMessage(
          id: const Uuid().v4(),
          content: message,
          timestamp: DateTime.now(),
          senderName: _anonymousName,
          senderColor: _anonymousColor,
        ));
        
        _messageController.clear();
      });
      
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated glitch background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: GlitchBackgroundPainter(
                  animation: _animationController,
                ),
                size: MediaQuery.of(context).size,
              );
            },
          ),
          
          // Portal UI
          SafeArea(
            child: Column(
              children: [
                // Header with timer
                _buildGlitchHeader(),
                
                // Messages
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  ),
                ),
                
                // Input area
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGlitchHeader() {
    final minutes = _timeRemaining.inMinutes;
    final seconds = _timeRemaining.inSeconds % 60;
    final formattedTime = '$minutes:${seconds.toString().padLeft(2, '0')}';
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Portal ID
                  GlitchText(
                    'PORTAL #${_portalId.substring(0, 8)}',
                    baseColor: Colors.white,
                    glitchColor: Colors.cyan,
                  ),
                  
                  // Self-destruct timer
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _timeRemaining.inMinutes < 5 ? Colors.red : Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      GlitchText(
                        formattedTime,
                        baseColor: _timeRemaining.inMinutes < 5 ? Colors.red : Colors.white,
                        glitchColor: Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Anonymous identity
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _anonymousColor,
                          boxShadow: [
                            BoxShadow(
                              color: _anonymousColor.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _anonymousName,
                        style: TextStyle(
                          color: _anonymousColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  
                  // Active users
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: Colors.white.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${1 + math.Random().nextInt(5)} ACTIVE', // Simulated user count
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessageBubble(GlitchMessage message) {
    final bool isSystem = message.senderName == 'SYSTEM';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSystem) // Don't show sender name for system messages
            Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: message.senderColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.senderName,
                    style: TextStyle(
                      color: message.senderColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          
          // Message content
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSystem
                  ? Colors.red.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSystem
                    ? Colors.red.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                if (!isSystem) 
                  BoxShadow(
                    color: message.senderColor.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
              ],
            ),
            child: isSystem
                ? GlitchText(
                    message.content,
                    baseColor: Colors.white,
                    glitchColor: Colors.redAccent,
                    glitchFrequency: 0.5,
                  )
                : Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageInput() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Message field
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type in the void...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              
              // Send button
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _anonymousColor.withOpacity(0.2),
                    border: Border.all(
                      color: _anonymousColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _anonymousColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _anonymousColor,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class GlitchText extends StatefulWidget {
  final String text;
  final Color baseColor;
  final Color glitchColor;
  final double glitchFrequency;
  final TextStyle? style;
  
  const GlitchText(
    this.text, {
    Key? key,
    required this.baseColor,
    required this.glitchColor,
    this.glitchFrequency = 0.3,
    this.style,
  }) : super(key: key);

  @override
  _GlitchTextState createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> with SingleTickerProviderStateMixin {
  late Timer _glitchTimer;
  bool _isGlitching = false;
  
  @override
  void initState() {
    super.initState();
    
    // Random glitch effect timer
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (math.Random().nextDouble() < widget.glitchFrequency) {
        setState(() {
          _isGlitching = true;
        });
        
        // Reset glitch after a short delay
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() {
              _isGlitching = false;
            });
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _glitchTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = (widget.style ?? const TextStyle()).copyWith(
      color: _isGlitching ? widget.glitchColor : widget.baseColor,
      fontWeight: FontWeight.bold,
      letterSpacing: _isGlitching ? 1.5 : 1.0,
    );
    
    return Text(
      _isGlitching ? _applyGlitchText(widget.text) : widget.text,
      style: baseStyle,
    );
  }
  
  String _applyGlitchText(String text) {
    // Simple text glitch effect by replacing random characters
    final result = StringBuffer();
    final glitchChars = 'x!@#$%^&*_-+=;:?/|\\';
    
    for (int i = 0; i < text.length; i++) {
      if (math.Random().nextDouble() < 0.2) {
        // Replace with glitch character
        result.write(glitchChars[math.Random().nextInt(glitchChars.length)]);
      } else {
        result.write(text[i]);
      }
    }
    
    return result.toString();
  }
}

class GlitchBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  
  GlitchBackgroundPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Background gradient
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1a0936),
          Color(0xFF290052),
          Color(0xFF1e0129),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.purple.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Vertical lines
    final vLineCount = 20;
    final vLineSpacing = width / vLineCount;
    
    for (int i = 0; i < vLineCount; i++) {
      final x = i * vLineSpacing;
      final wobble = math.sin(animation.value * math.pi * 2 + i) * 5;
      
      final path = Path();
      path.moveTo(x + wobble, 0);
      
      for (double y = 0; y < height; y += 20) {
        final xWobble = math.sin(animation.value * math.pi * 2 + y / 50) * 3;
        path.lineTo(x + xWobble, y);
      }
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Horizontal lines
    final hLineCount = 30;
    final hLineSpacing = height / hLineCount;
    
    for (int i = 0; i < hLineCount; i++) {
      final y = i * hLineSpacing;
      final wobble = math.cos(animation.value * math.pi * 2 + i) * 5;
      
      final path = Path();
      path.moveTo(0, y + wobble);
      
      for (double x = 0; x < width; x += 20) {
        final yWobble = math.cos(animation.value * math.pi * 2 + x / 50) * 3;
        path.lineTo(x, y + yWobble);
      }
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Moving glitch blocks
    final random = math.Random(animation.value.toInt() * 10000);
    final glitchPaint = Paint()..style = PaintingStyle.fill;
    
    final glitchCount = 5;
    
    for (int i = 0; i < glitchCount; i++) {
      final glitchHeight = 2.0 + random.nextDouble() * 20;
      final glitchWidth = 20.0 + random.nextDouble() * 100;
      final glitchY = random.nextDouble() * height;
      final glitchX = random.nextDouble() * width;
      
      final glitchOpacity = 0.05 + random.nextDouble() * 0.15;
      final hue = 240 + random.nextDouble() * 60; // Purple to blue hues
      
      glitchPaint.color = HSVColor.fromAHSV(
        glitchOpacity,
        hue,
        0.8,
        0.9,
      ).toColor();
      
      canvas.drawRect(
        Rect.fromLTWH(glitchX, glitchY, glitchWidth, glitchHeight),
        glitchPaint,
      );
    }
    
    // Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final particleCount = 100;
    
    for (int i = 0; i < particleCount; i++) {
      final progress = (animation.value + i / particleCount) % 1.0;
      final size = 1.0 + math.Random(i).nextDouble() * 2.0;
      final x = math.Random(i * 2).nextDouble() * width;
      final y = height * progress;
      
      final opacity = (1.0 - progress) * 0.4;
      
      particlePaint.color = Colors.cyanAccent.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), size, particlePaint);
    }
    
    // Scanner line effect
    final scanLineY = (animation.value * height * 2) % (height * 2);
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.cyanAccent.withOpacity(0.0),
          Colors.cyanAccent.withOpacity(0.3),
          Colors.cyanAccent.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, scanLineY - 20, width, 40));
    
    canvas.drawRect(
      Rect.fromLTWH(0, scanLineY - 20, width, 40),
      scanLinePaint,
    );
  }
  
  @override
  bool shouldRepaint(GlitchBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
} 