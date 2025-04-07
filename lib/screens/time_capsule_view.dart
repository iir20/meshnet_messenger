import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class TimeCapsuleMessage {
  final String id;
  final String sender;
  final String content;
  final DateTime createdAt;
  final DateTime unlockTime;
  final bool isLocked;
  final String encryptionType;
  final Color color;
  
  TimeCapsuleMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.createdAt,
    required this.unlockTime,
    this.isLocked = true,
    this.encryptionType = 'AES-256',
    required this.color,
  });
  
  bool get isPast => unlockTime.isBefore(DateTime.now());
  bool get isFuture => unlockTime.isAfter(DateTime.now());
  bool get isUnlockable => isPast && isLocked;
  
  TimeCapsuleMessage unlock() {
    return TimeCapsuleMessage(
      id: id,
      sender: sender,
      content: content,
      createdAt: createdAt,
      unlockTime: unlockTime,
      isLocked: false,
      encryptionType: encryptionType,
      color: color,
    );
  }
}

class TimeCapsuleView extends StatefulWidget {
  const TimeCapsuleView({Key? key}) : super(key: key);

  @override
  _TimeCapsuleViewState createState() => _TimeCapsuleViewState();
}

class _TimeCapsuleViewState extends State<TimeCapsuleView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _timelineController = ScrollController();
  double _rotationY = 0;
  double _scale = 1.0;
  final DateTime _now = DateTime.now();
  double _timeOffset = 0; // Days offset from now
  final double _maxTimeOffset = 30; // Max days in past/future
  bool _isComposing = false;
  final TextEditingController _messageController = TextEditingController();
  DateTime _scheduledDateTime = DateTime.now().add(const Duration(days: 1));
  
  final List<TimeCapsuleMessage> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _loadSampleMessages();
  }
  
  void _loadSampleMessages() {
    final _now = DateTime.now();
    
    _messages.addAll([
      TimeCapsuleMessage(
        id: '1',
        sender: 'Alex',
        content: "Happy Birthday! I scheduled this message a month ago. Hope you're having a great day!",
        createdAt: _now.subtract(const Duration(days: 30)),
        unlockTime: _now.add(const Duration(days: 5)),
        color: Colors.purple,
      ),
      TimeCapsuleMessage(
        id: '2',
        sender: 'Morgan',
        content: "Surprise! If you're reading this, it means our time capsule messaging feature works as planned.",
        createdAt: _now,
        unlockTime: _now.add(const Duration(days: 1)),
        color: Colors.teal,
      ),
    ]);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _timelineController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotationY += details.delta.dx * 0.01;
      _rotationY = _rotationY.clamp(-0.5, 0.5);
    });
  }
  
  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _rotationY = 0;
    });
  }
  
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = details.scale.clamp(0.8, 1.5);
    });
  }
  
  void _handleScaleEnd(ScaleEndDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }
  
  void _handleTimelineScroll(double delta) {
    setState(() {
      _timeOffset += delta;
      _timeOffset = _timeOffset.clamp(-_maxTimeOffset, _maxTimeOffset);
    });
  }
  
  void _unlockMessage(TimeCapsuleMessage message) {
    if (!message.isUnlockable) return;
    
    HapticFeedback.heavyImpact();
    
    setState(() {
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = message.unlock();
      }
    });
  }
  
  void _showNewCapsuleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.purpleAccent.withOpacity(0.5),
              width: 1,
            ),
          ),
          title: const Text(
            'Create Time Capsule',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _messageController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your message...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.purpleAccent.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.purpleAccent.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Colors.purpleAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Unlock date: ${_scheduledDateTime.day}/${_scheduledDateTime.month}/${_scheduledDateTime.year}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Slider(
                activeColor: Colors.purpleAccent,
                inactiveColor: Colors.purpleAccent.withOpacity(0.3),
                min: 1,
                max: 30,
                divisions: 29,
                label: '${(_scheduledDateTime.difference(_now).inDays)} days',
                value: _scheduledDateTime.difference(_now).inDays.toDouble(),
                onChanged: (value) {
                  setState(() {
                    _scheduledDateTime = _now.add(Duration(days: value.round()));
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  final newMessage = TimeCapsuleMessage(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    sender: 'You',
                    content: _messageController.text,
                    createdAt: _now,
                    unlockTime: _scheduledDateTime,
                    color: Colors.purple,
                  );
                  
                  setState(() {
                    _messages.add(newMessage);
                    _messageController.clear();
                  });
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Time capsule scheduled for ${newMessage.unlockTime.day}/${newMessage.unlockTime.month}/${newMessage.unlockTime.year}'
                      ),
                      backgroundColor: Colors.purpleAccent,
                    ),
                  );
                }
              },
              child: const Text('CREATE'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Time Capsule Messages',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
            ),
            body: Stack(
              children: [
                // Animated background
                _buildAnimatedBackground(),
                
                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Time controls
                      _buildTimeControls(),
                      
                      // Timeline view
                      Expanded(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateY(_rotationY)
                            ..scale(_scale),
                          alignment: Alignment.center,
                          child: _buildTimeline(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Instructions overlay
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Drag left/right to rotate • Pinch to zoom',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _showNewCapsuleDialog,
              backgroundColor: Colors.purpleAccent,
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
          ],
        ),
      ),
      child: CustomPaint(
        painter: TimeBackgroundPainter(
          animation: _animationController,
        ),
        child: Container(),
      ),
    );
  }
  
  Widget _buildTimeControls() {
    final currentDate = _now.add(Duration(days: _timeOffset.round()));
    final isPast = _timeOffset < 0;
    final isFuture = _timeOffset > 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPast ? 'PAST' : isFuture ? 'FUTURE' : 'TODAY',
                style: TextStyle(
                  color: isPast ? Colors.blue : isFuture ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currentDate.day}/${currentDate.month}/${currentDate.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white10,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Timeline slider
                Positioned.fill(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.purpleAccent,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      min: -_maxTimeOffset,
                      max: _maxTimeOffset,
                      value: _timeOffset,
                      onChanged: (value) {
                        setState(() {
                          _timeOffset = value;
                        });
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ),
                
                // Time markers
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          '-${_maxTimeOffset.round()} days',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Text(
                        'TODAY',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          '+${_maxTimeOffset.round()} days',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeline() {
    final filteredMessages = _messages.where((message) {
      final messageDaysOffset = message.unlockTime.difference(_now).inDays;
      return (messageDaysOffset - _timeOffset).abs() <= 5; // Show messages within 5 days of current view
    }).toList();
    
    if (filteredMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No time capsules found',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try looking at a different date or create a new one',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _timelineController,
      itemCount: filteredMessages.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final message = filteredMessages[index];
        final messageDaysOffset = message.unlockTime.difference(_now).inDays;
        final distanceFromCenter = (messageDaysOffset - _timeOffset).abs();
        final scale = 1.0 - (distanceFromCenter * 0.05).clamp(0.0, 0.3);
        final opacity = 1.0 - (distanceFromCenter * 0.2).clamp(0.0, 0.7);
        
        // Calculate z-position based on time distance
        final zOffset = -distanceFromCenter * 20.0;
        
        return Transform(
          transform: Matrix4.identity()
            ..translate(0.0, 0.0, zOffset),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: _buildMessageCard(message),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMessageCard(TimeCapsuleMessage message) {
    final isPast = message.unlockTime.isBefore(_now);
    final unlockable = message.isUnlockable;
    
    return GestureDetector(
      onTap: () {
        if (unlockable) {
          _unlockMessage(message);
        } else if (message.isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This message will unlock on ${message.unlockTime.day}/${message.unlockTime.month}/${message.unlockTime.year}'),
              backgroundColor: Colors.blueGrey,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              message.color.withOpacity(0.3),
              Colors.black54,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: message.color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: message.color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: message.color,
                        child: Text(
                          message.sender.isNotEmpty ? message.sender[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.sender,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Created: ${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPast 
                              ? (message.isLocked ? Colors.amber : Colors.green)
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPast
                              ? (message.isLocked ? 'UNLOCK' : 'UNLOCKED')
                              : 'FUTURE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (message.isLocked) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: message.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 32,
                            color: message.color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            unlockable
                                ? 'Tap to unlock this message'
                                : 'This message is locked until ${message.unlockTime.day}/${message.unlockTime.month}/${message.unlockTime.year}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Encrypted with ${message.encryptionType}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.lock_open,
                          size: 12,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked on ${message.unlockTime.day}/${message.unlockTime.month}/${message.unlockTime.year}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TimeBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  
  TimeBackgroundPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw holo grid
    const gridSpacing = 40.0;
    final horizontalLines = (size.height / gridSpacing).ceil();
    final verticalLines = (size.width / gridSpacing).ceil();
    
    // Horizontal lines
    for (int i = 0; i <= horizontalLines; i++) {
      final y = i * gridSpacing;
      
      // Add wave effect
      final path = Path();
      path.moveTo(0, y);
      
      for (double x = 0; x < size.width; x += 5) {
        final waveHeight = math.sin(x / 50 + animation.value * 2 * math.pi) * 2.0;
        path.lineTo(x, y + waveHeight);
      }
      
      canvas.drawPath(path, paint..color = Colors.cyan.withOpacity(0.05));
    }
    
    // Vertical lines
    for (int i = 0; i <= verticalLines; i++) {
      final x = i * gridSpacing;
      
      // Add wave effect
      final path = Path();
      path.moveTo(x, 0);
      
      for (double y = 0; y < size.height; y += 5) {
        final waveWidth = math.sin(y / 50 + animation.value * 2 * math.pi) * 2.0;
        path.lineTo(x + waveWidth, y);
      }
      
      canvas.drawPath(path, paint..color = Colors.purple.withOpacity(0.05));
    }
    
    // Draw time axis
    paint
      ..color = Colors.purpleAccent.withOpacity(0.2)
      ..strokeWidth = 2.0;
    
    final centerY = size.height / 2;
    final axisPath = Path();
    axisPath.moveTo(0, centerY);
    
    for (double x = 0; x < size.width; x += 2) {
      final waveHeight = math.sin(x / 100 + animation.value * math.pi) * 5.0;
      axisPath.lineTo(x, centerY + waveHeight);
    }
    
    canvas.drawPath(axisPath, paint);
    
    // Draw floating time markers
    final markerCount = 10;
    final markerSpacing = size.width / markerCount;
    
    for (int i = 0; i <= markerCount; i++) {
      final x = i * markerSpacing;
      final markerY = centerY + math.sin(x / 100 + animation.value * math.pi) * 5.0;
      
      // Draw marker
      paint
        ..color = Colors.purpleAccent.withOpacity(0.3 + (i / markerCount) * 0.4)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, markerY),
        3.0,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant TimeBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
} 