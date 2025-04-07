import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:secure_mesh_messenger/services/theme_service.dart';
import 'package:secure_mesh_messenger/models/chat.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ChatOrb> _orbs = [];
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    // Initialize orbs with sample data
    _initializeOrbs();
  }
  
  void _initializeOrbs() {
    // Sample chat data - replace with actual data
    final chats = [
      Chat(id: '1', name: 'Alice', lastMessage: 'Hello!', unreadCount: 2),
      Chat(id: '2', name: 'Bob', lastMessage: 'Meeting at 3pm', unreadCount: 0),
      Chat(id: '3', name: 'Team Alpha', lastMessage: 'Project update', unreadCount: 5),
    ];
    
    for (var i = 0; i < chats.length; i++) {
      final angle = (i * 2 * vector.pi) / chats.length;
      _orbs.add(ChatOrb(
        chat: chats[i],
        angle: angle,
        radius: 150.0,
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
    final themeService = Provider.of<ThemeService>(context);
    
    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          _scale = details.scale.clamp(0.5, 2.0);
          _offset += details.focalPointDelta;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeService.currentColorScheme.background,
              themeService.currentColorScheme.surface,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background stars
            _buildStarField(),
            
            // Chat orbs
            ..._orbs.map((orb) => _buildOrb(orb, themeService)),
            
            // Center indicator
            _buildCenterIndicator(themeService),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStarField() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.8],
        ),
      ),
    );
  }
  
  Widget _buildOrb(ChatOrb orb, ThemeService themeService) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = orb.angle + (_controller.value * 2 * vector.pi);
        final x = orb.radius * vector.cos(angle);
        final y = orb.radius * vector.sin(angle);
        
        return Positioned(
          left: MediaQuery.of(context).size.width / 2 + x - 30,
          top: MediaQuery.of(context).size.height / 2 + y - 30,
          child: Transform.scale(
            scale: _scale,
            child: Transform.translate(
              offset: _offset,
              child: _buildOrbContent(orb, themeService),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOrbContent(ChatOrb orb, ThemeService themeService) {
    return GestureDetector(
      onTap: () => _onOrbTapped(orb),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: themeService.currentColorScheme.primary.withOpacity(0.2),
          border: Border.all(
            color: themeService.currentColorScheme.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: themeService.currentColorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 20,
                backgroundColor: themeService.currentColorScheme.secondary,
                child: Text(
                  orb.chat.name[0],
                  style: TextStyle(
                    color: themeService.currentColorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Unread count
            if (orb.chat.unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: themeService.currentColorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    orb.chat.unreadCount.toString(),
                    style: TextStyle(
                      color: themeService.currentColorScheme.onError,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(),
      ).shimmer(
        duration: const Duration(seconds: 2),
        color: themeService.currentColorScheme.primary.withOpacity(0.5),
      ),
    );
  }
  
  Widget _buildCenterIndicator(ThemeService themeService) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: themeService.currentColorScheme.primary.withOpacity(0.1),
          border: Border.all(
            color: themeService.currentColorScheme.primary,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.auto_awesome,
          color: themeService.currentColorScheme.primary,
          size: 40,
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(),
      ).pulse(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
      ),
    );
  }
  
  void _onOrbTapped(ChatOrb orb) {
    // Handle orb tap - navigate to chat
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: orb.chat,
    );
  }
}

class ChatOrb {
  final Chat chat;
  final double angle;
  final double radius;
  
  ChatOrb({
    required this.chat,
    required this.angle,
    required this.radius,
  });
} 