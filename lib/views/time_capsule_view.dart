import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/services/theme_service.dart';

class TimeCapsuleView extends StatefulWidget {
  final List<TimeCapsuleMessage> messages;
  final Function(TimeCapsuleMessage)? onMessageSelect;
  
  const TimeCapsuleView({
    Key? key,
    required this.messages,
    this.onMessageSelect,
  }) : super(key: key);
  
  @override
  State<TimeCapsuleView> createState() => _TimeCapsuleViewState();
}

class _TimeCapsuleViewState extends State<TimeCapsuleView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  TimeCapsuleMessage? _selectedMessage;
  bool _isFloating = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Time Capsule',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFloating ? Icons.view_timeline : Icons.view_in_ar,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isFloating = !_isFloating;
              });
              
              // Give haptic feedback
              HapticFeedback.mediumImpact();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background effects
          _buildBackgroundEffect(themeService),
          
          // Time capsule display
          _isFloating
              ? _build3DFloatingView(themeService, size)
              : _buildTimelineView(themeService),
              
          // Selected message detail overlay
          if (_selectedMessage != null)
            _buildMessageDetailOverlay(themeService),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundEffect(ThemeService themeService) {
    return Stack(
      children: [
        // Dark gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                themeService.currentColorScheme.primary.withOpacity(0.2),
                Colors.black,
              ],
            ),
          ),
        ),
        
        // Animated star field
        CustomPaint(
          painter: _StarFieldPainter(
            starCount: 100,
            animationValue: _animationController.value,
            color: Colors.white,
          ),
          size: Size.infinite,
        ),
      ],
    );
  }
  
  Widget _buildTimelineView(ThemeService themeService) {
    // Group messages by time period
    final pastMessages = widget.messages
        .where((msg) => msg.unlockTime.isBefore(DateTime.now()))
        .toList();
    
    final futureMessages = widget.messages
        .where((msg) => msg.unlockTime.isAfter(DateTime.now()))
        .toList();
    
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Past messages section
        if (pastMessages.isNotEmpty) ...[
          _buildSectionHeader('Past Messages', themeService),
          ...pastMessages.map((message) => _buildTimelineMessageCard(message, themeService, true)),
        ],
        
        // Divider
        if (pastMessages.isNotEmpty && futureMessages.isNotEmpty)
          const SizedBox(height: 32),
        
        // Future messages section
        if (futureMessages.isNotEmpty) ...[
          _buildSectionHeader('Future Messages', themeService),
          ...futureMessages.map((message) => _buildTimelineMessageCard(message, themeService, false)),
        ],
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeService.currentColorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeService.currentColorScheme.primary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: themeService.currentColorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: themeService.currentColorScheme.primary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineMessageCard(
      TimeCapsuleMessage message, ThemeService themeService, bool isUnlocked) {
    final isPast = message.unlockTime.isBefore(DateTime.now());
    
    return GestureDetector(
      onTap: () {
        if (isPast || !message.isEncrypted) {
          setState(() {
            _selectedMessage = message;
          });
          
          // Trigger vibration
          HapticFeedback.selectionClick();
          
          if (widget.onMessageSelect != null) {
            widget.onMessageSelect!(message);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeService.currentColorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: themeService.currentColorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Time indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPast ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isPast ? 'PAST' : 'FUTURE',
                    style: TextStyle(
                      color: isPast ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Lock status
                if (message.isEncrypted)
                  Icon(
                    isPast ? Icons.lock_open : Icons.lock,
                    color: isPast ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  
                const Spacer(),
                
                // Date
                Text(
                  _formatDate(message.unlockTime),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Message preview
            if (isPast || !message.isEncrypted)
              Text(
                message.preview,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'This message is encrypted until ${_formatDate(message.unlockTime)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              
            const SizedBox(height: 12),
            
            // Footer
            Row(
              children: [
                // Sender info
                CircleAvatar(
                  radius: 12,
                  backgroundColor: themeService.currentColorScheme.primary.withOpacity(0.2),
                  child: Text(
                    message.senderName[0].toUpperCase(),
                    style: TextStyle(
                      color: themeService.currentColorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.senderName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 500))
      .slide(
        begin: Offset(0, 0.1),
        end: Offset.zero,
        duration: const Duration(milliseconds: 500),
      );
  }
  
  Widget _build3DFloatingView(ThemeService themeService, Size size) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Time divider line
            Center(
              child: Container(
                width: size.width,
                height: 2,
                color: themeService.currentColorScheme.primary.withOpacity(0.3),
              ),
            ),
            
            // Current time indicator
            Center(
              child: Container(
                width: 150,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeService.currentColorScheme.primary,
                    width: 1,
                  ),
                ),
                child: const Text(
                  'NOW',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Message capsules
            ...widget.messages.map((message) {
              // Calculate vertical position based on time
              final timeDifference = message.unlockTime.difference(DateTime.now()).inHours;
              final maxOffset = 150.0; // Max pixels from center
              final offsetFactor = timeDifference.abs() > 720 
                  ? 1.0 
                  : timeDifference.abs() / 720;
              final verticalOffset = timeDifference.sign * offsetFactor * maxOffset;
              
              // Calculate size based on distance from center
              final sizeScale = 1.0 - (offsetFactor * 0.5);
              
              // Calculate animation offset
              final animationOffset = math.sin(_animationController.value * 2 * math.pi) * 5;
              
              return Positioned(
                top: size.height / 2 - 40 + verticalOffset + animationOffset,
                left: size.width / 2 - 100 * sizeScale,
                child: GestureDetector(
                  onTap: () {
                    if (message.unlockTime.isBefore(DateTime.now()) || !message.isEncrypted) {
                      setState(() {
                        _selectedMessage = message;
                      });
                      
                      // Trigger haptic feedback
                      HapticFeedback.selectionClick();
                      
                      if (widget.onMessageSelect != null) {
                        widget.onMessageSelect!(message);
                      }
                    }
                  },
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateX(0.1 * verticalOffset.sign)
                      ..scale(sizeScale),
                    alignment: Alignment.center,
                    child: _build3DMessageCapsule(message, themeService, size),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
  
  Widget _build3DMessageCapsule(
    TimeCapsuleMessage message, 
    ThemeService themeService,
    Size size,
  ) {
    final isPast = message.unlockTime.isBefore(DateTime.now());
    final capsuleColor = isPast
        ? Colors.green.withOpacity(0.3)
        : Colors.orange.withOpacity(0.3);
    final borderColor = isPast
        ? Colors.green.withOpacity(0.7)
        : Colors.orange.withOpacity(0.7);
    
    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: capsuleColor,
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Time indicator
          Positioned(
            top: -8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  _formatDate(message.unlockTime),
                  style: TextStyle(
                    color: isPast ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Message content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPast || !message.isEncrypted)
                    Text(
                      message.preview,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Locked',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'From: ${message.senderName}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          // Glowing effect for unlocked messages
          if (isPast)
            Positioned.fill(
              child: CustomPaint(
                painter: _GlowingEdgePainter(
                  color: Colors.green,
                  animationValue: _animationController.value,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMessageDetailOverlay(ThemeService themeService) {
    if (_selectedMessage == null) return const SizedBox.shrink();
    
    final message = _selectedMessage!;
    final isPast = message.unlockTime.isBefore(DateTime.now());
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMessage = null;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeService.currentColorScheme.primary.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeService.currentColorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPast
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPast ? Colors.green : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          message.isEncrypted
                              ? (isPast ? 'DECRYPTED' : 'ENCRYPTED')
                              : 'OPEN',
                          style: TextStyle(
                            color: isPast ? Colors.green : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Date and time
                  Text(
                    _formatDetailDate(message.unlockTime),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      isPast || !message.isEncrypted
                          ? message.content
                          : 'This message is still encrypted and will be unlocked on ${_formatDetailDate(message.unlockTime)}.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontStyle: isPast || !message.isEncrypted
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Footer with sender info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: themeService.currentColorScheme.primary.withOpacity(0.2),
                        child: Text(
                          message.senderName[0].toUpperCase(),
                          style: TextStyle(
                            color: themeService.currentColorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.senderName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Sent ${_formatTime(message.sentTime)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Action buttons
                  if (isPast || !message.isEncrypted)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.reply),
                            label: const Text('Reply'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: themeService.currentColorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              // Handle reply
                              setState(() {
                                _selectedMessage = null;
                              });
                            },
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
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else if (difference.inDays > 0 && difference.inDays < 7) {
      return '${difference.inDays} days from now';
    } else if (difference.inDays < 0 && difference.inDays > -7) {
      return '${-difference.inDays} days ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
  
  String _formatDetailDate(DateTime dateTime) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at '
           '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class TimeCapsuleMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String preview;
  final DateTime sentTime;
  final DateTime unlockTime;
  final bool isEncrypted;
  final Map<String, dynamic>? metadata;
  
  TimeCapsuleMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    String? preview,
    required this.sentTime,
    required this.unlockTime,
    this.isEncrypted = true,
    this.metadata,
  }) : preview = preview ?? (content.length > 100 ? '${content.substring(0, 97)}...' : content);
  
  bool get isUnlocked => unlockTime.isBefore(DateTime.now());
  
  factory TimeCapsuleMessage.fromMessage(Message message, {
    required String senderName,
    required DateTime unlockTime,
  }) {
    return TimeCapsuleMessage(
      id: message.id,
      senderId: message.senderId,
      senderName: senderName,
      content: message.content,
      sentTime: message.timestamp,
      unlockTime: unlockTime,
      isEncrypted: message.isEncrypted,
      metadata: message.embeddedData,
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final int starCount;
  final double animationValue;
  final Color color;
  final List<Offset> _stars = [];
  final List<double> _sizes = [];
  final math.Random _random = math.Random();
  
  _StarFieldPainter({
    required this.starCount,
    required this.animationValue,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (_stars.isEmpty) {
      _initializeStars(size);
    }
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < starCount; i++) {
      // Update position - subtle movement
      final offset = Offset(
        (_stars[i].dx + animationValue * 2) % size.width,
        _stars[i].dy,
      );
      
      // Pulsate size
      final pulseFactor = math.sin((animationValue * 2 * math.pi) + i) * 0.2 + 0.8;
      final starSize = _sizes[i] * pulseFactor;
      
      // Draw star
      canvas.drawCircle(offset, starSize, paint);
    }
  }
  
  void _initializeStars(Size size) {
    for (int i = 0; i < starCount; i++) {
      _stars.add(Offset(
        _random.nextDouble() * size.width,
        _random.nextDouble() * size.height,
      ));
      
      _sizes.add(_random.nextDouble() * 1.5 + 0.5);
    }
  }
  
  @override
  bool shouldRepaint(_StarFieldPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

class _GlowingEdgePainter extends CustomPainter {
  final Color color;
  final double animationValue;
  
  _GlowingEdgePainter({
    required this.color,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final glowOpacity = math.sin(animationValue * 2 * math.pi) * 0.3 + 0.3;
    
    final paint = Paint()
      ..color = color.withOpacity(glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
    
    // Draw rounded rectangle
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(40));
    canvas.drawRRect(rrect, paint);
  }
  
  @override
  bool shouldRepaint(_GlowingEdgePainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
} 