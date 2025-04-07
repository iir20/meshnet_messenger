import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_detail_screen.dart';
import 'dart:ui';

class Chat {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final Color orbitColor;
  final bool isGroup;

  Chat({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    required this.orbitColor,
    this.isGroup = false,
  });
}

class ChatListView extends StatefulWidget {
  const ChatListView({Key? key}) : super(key: key);

  @override
  _ChatListViewState createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _scrollController = ScrollController();
  double _dragValue = 0.0;
  bool _showSecretPortal = false;
  
  // Sample chat data
  final List<Chat> _chats = [
    Chat(
      id: '1',
      name: 'Alice',
      lastMessage: 'Hey there! How are you?',
      time: '10:30 AM',
      unreadCount: 2,
      orbitColor: Colors.purpleAccent,
    ),
    Chat(
      id: '2',
      name: 'Bob',
      lastMessage: 'Check out this new encryption protocol',
      time: '9:15 AM',
      unreadCount: 0,
      orbitColor: Colors.blueAccent,
    ),
    Chat(
      id: '3',
      name: 'Team Alpha',
      lastMessage: 'Weekly update on mesh coverage',
      time: 'Yesterday',
      unreadCount: 5,
      orbitColor: Colors.greenAccent,
      isGroup: true,
    ),
    Chat(
      id: '4',
      name: 'Charlie',
      lastMessage: 'The satellite uplink is working now',
      time: 'Yesterday',
      unreadCount: 1,
      orbitColor: Colors.orangeAccent,
    ),
    Chat(
      id: '5',
      name: 'Secure Hub',
      lastMessage: '5 new peers discovered nearby',
      time: '2 days ago',
      unreadCount: 0,
      orbitColor: Colors.redAccent,
      isGroup: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragValue += details.primaryDelta! / MediaQuery.of(context).size.height;
      _dragValue = _dragValue.clamp(0.0, 1.0);
      if (_dragValue > 0.5 && !_showSecretPortal) {
        _showSecretPortal = true;
        HapticFeedback.mediumImpact();
      } else if (_dragValue < 0.5 && _showSecretPortal) {
        _showSecretPortal = false;
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      if (_dragValue > 0.7) {
        // Keep portal open
        _dragValue = 0.8;
      } else {
        // Close portal
        _dragValue = 0.0;
        _showSecretPortal = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Stack(
            children: [
              // Animated background
              _buildAnimatedBackground(),
              
              // Chat list
              _buildChatOrbitalList(),
              
              // Secret portal overlay
              if (_showSecretPortal) _buildSecretPortal(),
              
              // Top bar with instructions
              Positioned(
                top: 20,
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
                      'Drag down to reveal secret chats',
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
        );
      },
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 25, 25, 60),
            Color.fromARGB(255, 40, 40, 80),
          ],
        ),
      ),
      child: CustomPaint(
        painter: BackgroundPainter(
          animation: _controller,
        ),
        child: Container(),
      ),
    );
  }
  
  Widget _buildChatOrbitalList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        // Calculate an orbital position based on index and animation
        final orbitalOffset = math.sin(
          _controller.value * 2 * math.pi + index * (math.pi / 4)
        ) * 10.0;
        
        return _buildChatOrb(chat, orbitalOffset);
      },
    );
  }
  
  Widget _buildChatOrb(Chat chat, double orbitalOffset) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _navigateToChatDetail(chat);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.fromLTRB(
          20 + orbitalOffset.abs(), 
          8, 
          20 - orbitalOffset.abs(), 
          8
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              chat.orbitColor.withOpacity(0.2),
              chat.orbitColor.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: chat.orbitColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: chat.orbitColor.withOpacity(0.7),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildChatAvatar(chat),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                chat.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              chat.time,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat.lastMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (chat.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: chat.orbitColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chat.unreadCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
  
  Widget _buildChatAvatar(Chat chat) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                chat.orbitColor,
                chat.orbitColor.withOpacity(0.5),
              ],
              stops: const [0.5, 1.0],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: chat.orbitColor.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (chat.isGroup)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: chat.orbitColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.group,
                size: 12,
                color: chat.orbitColor,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildSecretPortal() {
    return AnimatedOpacity(
      opacity: _dragValue,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomCenter,
            radius: 1.5,
            colors: [
              Colors.purpleAccent.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SECRET PORTAL',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.purpleAccent,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSecretPortalItem(
                      icon: Icons.lock,
                      title: 'Encrypted Room',
                      color: Colors.blue,
                    ),
                    _buildSecretPortalItem(
                      icon: Icons.timer,
                      title: 'Self-Destruct',
                      color: Colors.red,
                    ),
                    _buildSecretPortalItem(
                      icon: Icons.visibility_off,
                      title: 'Anonymous',
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSecretPortalItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title portal opening soon')),
        );
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToChatDetail(Chat chat) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatDetailScreen(
          chatName: chat.name,
          chatId: chat.id,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve = Curves.easeInOutCubic;
          var curveTween = CurveTween(curve: curve);
          
          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(animation.drive(curveTween));
          
          var scaleAnimation = Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(animation.drive(curveTween));
          
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  
  BackgroundPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw animated stars/particles
    for (int i = 0; i < 100; i++) {
      final x = math.cos(i * math.pi / 50 + animation.value * 2 * math.pi) * 
                (size.width / 2 - 50) + size.width / 2;
      final y = math.sin(i * math.pi / 50 + animation.value * 2 * math.pi) * 
                (size.height / 2 - 50) + size.height / 2;
      
      final radius = 1.0 + math.sin(animation.value * 2 * math.pi + i) * 1.0;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = Colors.white.withOpacity(0.1 + (radius - 1) * 0.2),
      );
    }
    
    // Draw orbital lines
    paint
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 5; i++) {
      final ovalRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.6 + i * 40,
        height: size.height * 0.8 + i * 20, 
      );
      
      canvas.drawOval(ovalRect, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
} 