import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'chat_detail_screen.dart';

class Contact {
  final String id;
  final String name;
  final String avatar;
  final Color color;
  final String status;
  final bool isOnline;
  final bool isGroup;
  final List<String> members;
  
  Contact({
    required this.id,
    required this.name,
    required this.avatar,
    required this.color,
    required this.status,
    this.isOnline = false,
    this.isGroup = false,
    this.members = const [],
  });
}

class OrbitalChatListScreen extends StatefulWidget {
  const OrbitalChatListScreen({Key? key}) : super(key: key);

  @override
  _OrbitalChatListScreenState createState() => _OrbitalChatListScreenState();
}

class _OrbitalChatListScreenState extends State<OrbitalChatListScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  final List<Contact> _contacts = [];
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _scale = 1.0;
  Contact? _selectedContact;
  bool _isZooming = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    
    _loadSampleContacts();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _loadSampleContacts() {
    final sampleContacts = [
      Contact(
        id: '1',
        name: 'Alex Chen',
        avatar: 'assets/avatars/alex.png',
        color: Colors.blueAccent,
        status: 'Working on the new project',
        isOnline: true,
      ),
      Contact(
        id: '2',
        name: 'Morgan Lee',
        avatar: 'assets/avatars/morgan.png',
        color: Colors.purpleAccent,
        status: 'At the coffee shop',
        isOnline: true,
      ),
      Contact(
        id: '3',
        name: 'Taylor Kim',
        avatar: 'assets/avatars/taylor.png',
        color: Colors.teal,
        status: 'Listening to music',
        isOnline: false,
      ),
      Contact(
        id: '4',
        name: 'Quantum Hub',
        avatar: 'assets/avatars/group.png',
        color: Colors.orangeAccent,
        status: '5 members online',
        isOnline: true,
        isGroup: true,
        members: ['Alex', 'Morgan', 'Taylor', 'Jordan', 'Riley'],
      ),
      Contact(
        id: '5',
        name: 'Jordan River',
        avatar: 'assets/avatars/jordan.png',
        color: Colors.greenAccent,
        status: 'Available',
        isOnline: true,
      ),
      Contact(
        id: '6',
        name: 'Riley Zhang',
        avatar: 'assets/avatars/riley.png',
        color: Colors.redAccent,
        status: 'Do not disturb',
        isOnline: false,
      ),
      Contact(
        id: '7',
        name: 'Mesh Network',
        avatar: 'assets/avatars/group.png',
        color: Colors.amber,
        status: '12 members',
        isOnline: true,
        isGroup: true,
        members: ['Alex', 'Morgan', 'Taylor', 'Jordan', 'Riley', 'Skyler', 'Dana', 'Casey', 'Quinn', 'Jamie', 'Blake', 'Avery'],
      ),
      Contact(
        id: '8',
        name: 'Skyler Patel',
        avatar: 'assets/avatars/skyler.png',
        color: Colors.cyanAccent,
        status: 'At the gym',
        isOnline: true,
      ),
      Contact(
        id: '9',
        name: 'Dana Wong',
        avatar: 'assets/avatars/dana.png',
        color: Colors.deepPurpleAccent,
        status: 'Working from home',
        isOnline: true,
      ),
      Contact(
        id: '10',
        name: 'Casey Martinez',
        avatar: 'assets/avatars/casey.png',
        color: Colors.pinkAccent,
        status: 'On vacation',
        isOnline: false,
      ),
    ];
    
    setState(() {
      _contacts.addAll(sampleContacts);
    });
  }

  void _handleOrbTap(Contact contact) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedContact = contact;
      _isZooming = true;
    });
    
    // Animate zoom in
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _selectedContact != null) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ChatDetailScreen(
              chatId: contact.id,
              chatName: contact.name,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ).then((_) {
          setState(() {
            _selectedContact = null;
            _isZooming = false;
          });
        });
      }
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
          'MeshNet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            fontFamily: 'Exo',
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
                const SnackBar(content: Text('New chat feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated cosmic background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: SpaceBackgroundPainter(
                  animation: _animationController,
                ),
                size: MediaQuery.of(context).size,
              );
            },
          ),
          
          // Main galaxy view
          GestureDetector(
            onPanUpdate: (details) {
              if (!_isZooming) {
                setState(() {
                  _rotationY += details.delta.dx * 0.01;
                  _rotationX -= details.delta.dy * 0.01;
                });
              }
            },
            onScaleUpdate: (details) {
              if (!_isZooming) {
                setState(() {
                  _scale = (_scale * details.scale).clamp(0.8, 2.0);
                });
              }
            },
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_rotationX)
                  ..rotateY(_rotationY)
                  ..scale(_scale),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Central glowing core
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.5 + _animationController.value * 0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white,
                                  Colors.cyanAccent,
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.2, 1.0],
                              ),
                            ),
                          ),
                        ),
                        
                        // Orbital rings
                        ...List.generate(3, (index) {
                          final radius = 100.0 + index * 80.0;
                          return Transform(
                            transform: Matrix4.rotationX(
                              _animationController.value * math.pi * 2 * (index % 2 == 0 ? 1 : -1) * 0.05
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: radius * 2,
                              height: radius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1 + 0.05 * index),
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        }),
                        
                        // Orbiting contacts
                        ..._contacts.asMap().entries.map((entry) {
                          final i = entry.key;
                          final contact = entry.value;
                          
                          // Calculate position on orbit
                          final orbitRadius = 100.0 + (i % 3) * 80.0;
                          final angle = _animationController.value * math.pi * 2 +
                                      i * (math.pi * 2 / (_contacts.length / 3));
                          final x = math.cos(angle) * orbitRadius;
                          final y = math.sin(angle) * orbitRadius * 0.3; // Flatten to elliptical orbit
                          
                          final isSelectedContact = _selectedContact?.id == contact.id;
                          final scale = isSelectedContact && _isZooming
                              ? 2.0 + (_animationController.value - _animationController.value.floor()) * 3.0
                              : 1.0;
                          
                          return Positioned(
                            left: MediaQuery.of(context).size.width / 2 + x - 30,
                            top: MediaQuery.of(context).size.height / 2 + y - 30,
                            child: Transform(
                              transform: Matrix4.identity()..scale(scale),
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () => _handleOrbTap(contact),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 500),
                                  opacity: isSelectedContact && _isZooming ? 
                                      (1.0 - (_animationController.value - _animationController.value.floor())) : 1.0,
                                  child: Container(
                                    width: contact.isGroup ? 70 : 60,
                                    height: contact.isGroup ? 70 : 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          contact.color.withOpacity(0.8),
                                          contact.color.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.3, 0.6, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: contact.color.withOpacity(0.5),
                                          blurRadius: 15,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Holographic glow effect
                                            AnimatedBuilder(
                                              animation: _animationController,
                                              builder: (context, child) {
                                                return Transform.rotate(
                                                  angle: _animationController.value * math.pi * 2,
                                                  child: CustomPaint(
                                                    painter: HolographicEdgePainter(
                                                      color: contact.color,
                                                      progress: _animationController.value,
                                                    ),
                                                    size: Size(contact.isGroup ? 70 : 60, contact.isGroup ? 70 : 60),
                                                  ),
                                                );
                                              },
                                            ),
                                            
                                            // Status indicator
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 500),
                                                width: 15,
                                                height: 15,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: contact.isOnline ? Colors.greenAccent : Colors.redAccent,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: contact.isOnline ? 
                                                          Colors.greenAccent.withOpacity(0.5) : 
                                                          Colors.redAccent.withOpacity(0.5),
                                                      blurRadius: 6,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            
                                            // Contact initial or group icon
                                            Center(
                                              child: contact.isGroup
                                                ? Icon(
                                                    Icons.people,
                                                    color: Colors.white.withOpacity(0.9),
                                                    size: 24,
                                                  )
                                                : Text(
                                                    contact.name[0].toUpperCase(),
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.9),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 24,
                                                      shadows: [
                                                        Shadow(
                                                          blurRadius: 10,
                                                          color: contact.color,
                                                          offset: const Offset(0, 0),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Contact info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Nodes: ${_contacts.where((c) => c.isOnline).length}/${_contacts.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Swipe to rotate galaxy • Pinch to zoom • Tap orbiting node to connect',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _animationController.value,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Network scan initiated')),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.cyanAccent, Colors.blueAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.radar,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class SpaceBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  
  SpaceBackgroundPainter({required this.animation}) : super(repaint: animation);
  
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
          Color(0xFF0f0f22),
          Color(0xFF1a1a3a),
          Color(0xFF0f0f22),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    // Draw stars
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42);  // Fixed seed for consistency
    
    // Small stars
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final size = 0.5 + random.nextDouble() * 1.5;
      final twinkle = 0.3 + (math.sin(animation.value * math.pi * 2 + i) + 1) / 2 * 0.7;
      
      starPaint.color = Colors.white.withOpacity(twinkle);
      canvas.drawCircle(Offset(x, y), size, starPaint);
    }
    
    // Medium stars with glow
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final baseSize = 1.0 + random.nextDouble() * 2.0;
      final twinkle = 0.5 + (math.sin(animation.value * math.pi * 2 + i) + 1) / 2 * 0.5;
      final size = baseSize * twinkle;
      
      // Star glow
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.3 * twinkle)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), size * 3, glowPaint);
      
      // Star core
      starPaint.color = Colors.white.withOpacity(twinkle);
      canvas.drawCircle(Offset(x, y), size, starPaint);
    }
    
    // Distant galaxies and nebulae
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final size = 30.0 + random.nextDouble() * 70.0;
      final rotation = random.nextDouble() * math.pi * 2;
      final hue = random.nextDouble() * 360;
      
      final nebulaPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            HSVColor.fromAHSV(0.3, hue, 0.7, 1.0).toColor(),
            HSVColor.fromAHSV(0.1, hue, 0.7, 1.0).toColor(),
            HSVColor.fromAHSV(0.0, hue, 0.0, 1.0).toColor(),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(x - size, y - size, size * 2, size * 2));
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.scale(1.0, 0.6);  // Flatten to make more elliptical
      canvas.drawCircle(Offset.zero, size, nebulaPaint);
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(SpaceBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class HolographicEdgePainter extends CustomPainter {
  final Color color;
  final double progress;
  
  HolographicEdgePainter({
    required this.color,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final circleRadius = radius * 0.9;
    
    // Draw holographic edge
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          color.withOpacity(0.5),
          Colors.white.withOpacity(0.8),
          color.withOpacity(0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, circleRadius, edgePaint);
  }
  
  @override
  bool shouldRepaint(HolographicEdgePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
} 