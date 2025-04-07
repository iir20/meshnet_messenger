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

class SecretPortalView extends StatefulWidget {
  final Chat chat;
  final int timeToLive; // Time in minutes before portal self-destructs
  
  const SecretPortalView({
    Key? key,
    required this.chat,
    this.timeToLive = 60,
  }) : super(key: key);
  
  @override
  State<SecretPortalView> createState() => _SecretPortalViewState();
}

class _SecretPortalViewState extends State<SecretPortalView> with SingleTickerProviderStateMixin {
  late AnimationController _glitchController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  Timer? _destructionTimer;
  int _remainingTimeInSeconds = 0;
  bool _isGlitching = false;
  
  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Set up initial messages
    _initializeMessages();
    
    // Set up destruction timer
    _remainingTimeInSeconds = widget.timeToLive * 60;
    _startDestructionTimer();
    
    // Set up random glitch effects
    _setupRandomGlitchEffects();
  }
  
  void _initializeMessages() {
    // Sample messages
    _messages.addAll([
      Message.text(
        id: '1',
        chatId: widget.chat.id,
        senderId: 'system',
        content: 'Welcome to the Secret Portal. Messages here will self-destruct in ${widget.timeToLive} minutes.',
        isMe: false,
        status: MessageStatus.delivered,
      ),
    ]);
  }
  
  void _startDestructionTimer() {
    _destructionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTimeInSeconds--;
        
        // Trigger more frequent glitches as time runs out
        if (_remainingTimeInSeconds < 300) { // Last 5 minutes
          final randomGlitch = math.Random().nextInt(100);
          if (randomGlitch < 10) { // 10% chance of glitch
            _triggerGlitch();
          }
        }
        
        if (_remainingTimeInSeconds <= 0) {
          _destructPortal();
        }
      });
    });
  }
  
  void _setupRandomGlitchEffects() {
    // Random glitches throughout the session
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final shouldGlitch = math.Random().nextBool();
      if (shouldGlitch) {
        _triggerGlitch();
      }
    });
  }
  
  void _triggerGlitch() {
    if (_isGlitching) return;
    
    setState(() {
      _isGlitching = true;
    });
    
    // Play glitch sound
    SystemSound.play(SystemSoundType.click);
    
    // Animate glitch
    _glitchController.forward().then((_) {
      _glitchController.reverse().then((_) {
        setState(() {
          _isGlitching = false;
        });
      });
    });
  }
  
  void _destructPortal() {
    _destructionTimer?.cancel();
    
    // Show destruction animation then pop
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DestructionDialog(),
    ).then((_) {
      Navigator.of(context).pop();
    });
  }
  
  @override
  void dispose() {
    _destructionTimer?.cancel();
    _glitchController.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.chat.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          _buildTimerWidget(themeService),
        ],
      ),
      body: Stack(
        children: [
          // Background effects
          _buildBackgroundEffects(themeService),
          
          // Content
          Column(
            children: [
              Expanded(
                child: _buildMessageList(themeService),
              ),
              _buildInputArea(themeService),
            ],
          ),
          
          // Glitch overlay when active
          if (_isGlitching)
            _buildGlitchOverlay(themeService),
        ],
      ),
    );
  }
  
  Widget _buildTimerWidget(ThemeService themeService) {
    final minutes = _remainingTimeInSeconds ~/ 60;
    final seconds = _remainingTimeInSeconds % 60;
    
    final color = _remainingTimeInSeconds < 300
        ? Colors.red
        : themeService.currentColorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$minutes:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate(
      target: _remainingTimeInSeconds < 60 ? 1 : 0, // Animate in last minute
    ).shimmer(
      duration: const Duration(milliseconds: 800),
      color: Colors.red,
    );
  }
  
  Widget _buildBackgroundEffects(ThemeService themeService) {
    return Stack(
      children: [
        // Dark background with grid
        CustomPaint(
          painter: _GridPainter(
            color: themeService.currentColorScheme.primary.withOpacity(0.3),
            glitchFactor: _glitchController.value,
          ),
          size: Size.infinite,
        ),
        
        // Vignette effect
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.1, 1.0],
              radius: 1.2,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMessageList(ThemeService themeService) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == 'user1'; // Replace with actual user ID
        
        return _buildMessageBubble(message, isMe, themeService);
      },
    );
  }
  
  Widget _buildMessageBubble(Message message, bool isMe, ThemeService themeService) {
    final hasGlitch = math.Random().nextInt(10) < 3; // 30% chance of glitch effect per message
    
    Widget bubble = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildGlitchedAvatar(message, themeService),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? themeService.currentColorScheme.primary.withOpacity(0.3)
                    : Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeService.currentColorScheme.primary.withOpacity(0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeService.currentColorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.senderId == 'system')
                    Text(
                      message.content,
                      style: TextStyle(
                        color: themeService.currentColorScheme.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildGlitchedAvatar(message, themeService),
          ],
        ],
      ),
    );
    
    if (hasGlitch && message.senderId != 'system') {
      bubble = bubble.animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).shimmer(
        duration: const Duration(milliseconds: 300),
        color: themeService.currentColorScheme.primary,
      );
      
      if (_isGlitching) {
        bubble = bubble.animate().shake(
          duration: const Duration(milliseconds: 500),
          offset: const Offset(5, 0),
        );
      }
    }
    
    return bubble;
  }
  
  Widget _buildGlitchedAvatar(Message message, ThemeService themeService) {
    final avatarWidget = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(
          color: themeService.currentColorScheme.primary.withOpacity(0.7),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          message.senderId == 'system' 
              ? 'S' 
              : message.senderId[0].toUpperCase(),
          style: TextStyle(
            color: themeService.currentColorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    
    if (message.senderId == 'system') {
      return avatarWidget;
    }
    
    // Add glitch animation to user avatars
    return avatarWidget.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).shimmer(
      duration: const Duration(seconds: 3),
      color: themeService.currentColorScheme.primary.withOpacity(0.8),
    );
  }
  
  Widget _buildInputArea(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border(
          top: BorderSide(
            color: themeService.currentColorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: themeService.currentColorScheme.primary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: themeService.currentColorScheme.primary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: themeService.currentColorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _sendMessage(value);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeService.currentColorScheme.primary,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  _sendMessage(_messageController.text);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGlitchOverlay(ThemeService themeService) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _glitchController,
          builder: (context, child) {
            return Stack(
              children: [
                // Horizontal RGB shift
                Positioned(
                  left: 2 * _glitchController.value,
                  top: 0,
                  child: Opacity(
                    opacity: 0.5 * _glitchController.value,
                    child: Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      color: Colors.red.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -2 * _glitchController.value,
                  top: 0,
                  child: Opacity(
                    opacity: 0.5 * _glitchController.value,
                    child: Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ),
                
                // Random glitch lines
                ...List.generate(10, (index) {
                  final random = math.Random();
                  final height = random.nextDouble() * 10 + 1;
                  final width = constraints.maxWidth;
                  final top = random.nextDouble() * constraints.maxHeight;
                  final opacity = random.nextDouble() * 0.7 * _glitchController.value;
                  
                  return Positioned(
                    left: 0,
                    top: top,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: width,
                        height: height,
                        color: themeService.currentColorScheme.primary,
                      ),
                    ),
                  );
                }),
                
                // Scan line
                Positioned(
                  left: 0,
                  top: constraints.maxHeight * _glitchController.value,
                  child: Container(
                    width: constraints.maxWidth,
                    height: 2,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _sendMessage(String content) {
    final newMessage = Message.text(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chat.id,
      senderId: 'user1', // Replace with actual user ID
      content: content,
      isMe: true,
      status: MessageStatus.sending,
    );
    
    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    
    // Simulate reply with random glitch
    if (math.Random().nextBool()) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        
        _triggerGlitch();
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          
          setState(() {
            _messages.add(Message.text(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              chatId: widget.chat.id,
              senderId: 'anonymous',
              content: _getRandomReply(),
              isMe: false,
              status: MessageStatus.delivered,
            ));
          });
          
          // Scroll to bottom again
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        });
      });
    }
  }
  
  String _getRandomReply() {
    final replies = [
      'The network is watching...',
      'Be careful what you share here.',
      'Messages are encrypted but not forgotten.',
      'Signal detected. Proceed with caution.',
      'Digital footprints never truly disappear.',
      'This conversation exists in quantum space.',
      'Security protocols active. Continue transmission.',
    ];
    
    return replies[math.Random().nextInt(replies.length)];
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double glitchFactor;
  
  _GridPainter({
    required this.color,
    this.glitchFactor = 0.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    final cellSize = 30.0;
    
    // Horizontal lines
    for (double y = 0; y < size.height; y += cellSize) {
      final path = Path();
      
      // Add glitch effect
      if (glitchFactor > 0 && math.Random().nextDouble() < glitchFactor * 0.2) {
        // Skip some lines randomly
        continue;
      }
      
      if (glitchFactor > 0 && math.Random().nextDouble() < glitchFactor * 0.3) {
        // Add glitched line
        path.moveTo(0, y);
        
        double currentX = 0;
        while (currentX < size.width) {
          final segmentLength = math.Random().nextDouble() * 50 + 10;
          final nextX = currentX + segmentLength;
          
          if (math.Random().nextDouble() < glitchFactor * 0.4) {
            // Random y displacement
            final displacement = (math.Random().nextDouble() * 10 - 5) * glitchFactor;
            path.lineTo(nextX, y + displacement);
          } else {
            path.lineTo(nextX, y);
          }
          
          currentX = nextX;
          
          // Random gaps
          if (math.Random().nextDouble() < glitchFactor * 0.3) {
            currentX += math.Random().nextDouble() * 20 * glitchFactor;
            path.moveTo(currentX, y);
          }
        }
      } else {
        // Regular line
        path.moveTo(0, y);
        path.lineTo(size.width, y);
      }
      
      canvas.drawPath(path, paint);
    }
    
    // Vertical lines
    for (double x = 0; x < size.width; x += cellSize) {
      final path = Path();
      
      // Add glitch effect
      if (glitchFactor > 0 && math.Random().nextDouble() < glitchFactor * 0.2) {
        // Skip some lines randomly
        continue;
      }
      
      if (glitchFactor > 0 && math.Random().nextDouble() < glitchFactor * 0.3) {
        // Add glitched line
        path.moveTo(x, 0);
        
        double currentY = 0;
        while (currentY < size.height) {
          final segmentLength = math.Random().nextDouble() * 50 + 10;
          final nextY = currentY + segmentLength;
          
          if (math.Random().nextDouble() < glitchFactor * 0.4) {
            // Random x displacement
            final displacement = (math.Random().nextDouble() * 10 - 5) * glitchFactor;
            path.lineTo(x + displacement, nextY);
          } else {
            path.lineTo(x, nextY);
          }
          
          currentY = nextY;
          
          // Random gaps
          if (math.Random().nextDouble() < glitchFactor * 0.3) {
            currentY += math.Random().nextDouble() * 20 * glitchFactor;
            path.moveTo(x, currentY);
          }
        }
      } else {
        // Regular line
        path.moveTo(x, 0);
        path.lineTo(x, size.height);
      }
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(_GridPainter oldDelegate) => 
      oldDelegate.color != color || oldDelegate.glitchFactor != glitchFactor;
}

class _DestructionDialog extends StatefulWidget {
  const _DestructionDialog({Key? key}) : super(key: key);

  @override
  State<_DestructionDialog> createState() => _DestructionDialogState();
}

class _DestructionDialogState extends State<_DestructionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    
    // Vibrate for emphasis
    HapticFeedback.vibrate();
    
    // Close after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pop();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.red.withOpacity(_controller.value),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Glitch effect
                if (_controller.value > 0.5)
                  ...List.generate(10, (index) {
                    final random = math.Random();
                    final width = 200.0;
                    final height = random.nextDouble() * 5 + 1;
                    final top = random.nextDouble() * 200;
                    final opacity = random.nextDouble() * 0.7 * (_controller.value - 0.5) * 2;
                    
                    return Positioned(
                      left: 0,
                      top: top,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: width,
                          height: height,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }),
                
                // Text
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.withOpacity(_controller.value),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SELF-DESTRUCTING',
                        style: TextStyle(
                          color: Colors.red.withOpacity(_controller.value),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CircularProgressIndicator(
                        value: _controller.value,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 