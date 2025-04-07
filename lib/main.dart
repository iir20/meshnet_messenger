import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/network_view.dart';
import 'screens/profile_view.dart';
import 'screens/chat_list_view.dart';
import 'screens/time_capsule_view.dart';
import 'screens/shadow_clone_screen.dart';
import 'services/mesh_service.dart';
import 'services/crypto_service.dart';
import 'services/audio_service.dart';
import 'services/shadow_clone_service.dart';
import 'screens/orbital_chat_list.dart';
import 'screens/chat_detail_screen.dart';
import 'screens/holo_rings_screen.dart';
import 'services/time_capsule_service.dart';
import 'screens/time_capsule_screen.dart';
import 'services/soul_key_service.dart';
import 'screens/soul_key_screen.dart';
import 'services/mood_messaging_service.dart';
import 'screens/mood_messaging_screen.dart';
import 'services/steganography_service.dart';
import 'screens/steganography_screen.dart';
import 'services/story_service.dart';
import 'services/p2p_service.dart';
import 'services/quantum_crypto_service.dart';
import 'screens/quantum_crypto_screen.dart';
import 'services/distributed_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0f0f22),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  // Initialize services
  final themeService = ThemeProvider();
  final meshService = MeshService();
  final cryptoService = CryptoService();
  final moodService = MoodService();
  final audioService = AudioService();
  final shadowCloneService = ShadowCloneService();
  final timeCapsuleService = TimeCapsuleService('user123');
  final soulKeyService = SoulKeyService('user123');
  final moodMessagingService = MoodMessagingService();
  final steganographyService = SteganographyService();
  final storyService = StoryService('user123');
  final p2pService = P2PService();
  final quantumCryptoService = QuantumCryptoService();
  final distributedStorageService = DistributedStorageService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => themeService),
        ChangeNotifierProvider(create: (context) => meshService),
        ChangeNotifierProvider(create: (context) => cryptoService),
        ChangeNotifierProvider(create: (context) => moodService),
        ChangeNotifierProvider(create: (context) => audioService),
        ChangeNotifierProvider(create: (context) => shadowCloneService),
        ChangeNotifierProvider(create: (context) => timeCapsuleService),
        ChangeNotifierProvider(create: (context) => soulKeyService),
        ChangeNotifierProvider(create: (context) => moodMessagingService),
        ChangeNotifierProvider(create: (context) => steganographyService),
        ChangeNotifierProvider(create: (context) => storyService),
        ChangeNotifierProvider(create: (context) => p2pService),
        ChangeNotifierProvider(create: (context) => quantumCryptoService),
        ChangeNotifierProvider(create: (context) => distributedStorageService),
      ],
      child: const MeshNetApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode for futuristic feel
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class MoodService extends ChangeNotifier {
  String _currentMood = 'neutral';
  final Map<String, Color> _moodColors = {
    'happy': Colors.amber,
    'calm': Colors.blue,
    'excited': Colors.orange,
    'creative': Colors.purple,
    'focused': Colors.teal,
    'neutral': Colors.blueGrey,
  };
  
  String get currentMood => _currentMood;
  Color get moodColor => _moodColors[_currentMood] ?? Colors.blueGrey;
  
  void setMood(String mood) {
    if (_moodColors.containsKey(mood)) {
      _currentMood = mood;
      notifyListeners();
    }
  }
}

class MeshNetApp extends StatelessWidget {
  const MeshNetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CryptoService()),
        ChangeNotifierProvider(create: (_) => MeshService()),
        ChangeNotifierProvider(create: (_) => ShadowCloneService()),
        ChangeNotifierProvider(create: (_) => TimeCapsuleService('user123')),
      ],
      child: MaterialApp(
        title: 'MeshNet Messenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.cyanAccent,
          scaffoldBackgroundColor: const Color(0xFF0f0f22),
          fontFamily: 'Exo',
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            secondary: Colors.purpleAccent,
            surface: Color(0xFF1a1a3a),
            background: Color(0xFF0f0f22),
          ),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyMedium: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          appBarTheme: const AppBarTheme(
            color: Colors.transparent,
            elevation: 0,
          ),
          // Use cyberpunk-inspired button styles
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Colors.cyanAccent,
                  width: 2,
                ),
              ),
              elevation: 0,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _animationController.forward().then((_) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f22),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Background
              CustomPaint(
                painter: SplashBackgroundPainter(progress: _animationController.value),
                size: MediaQuery.of(context).size,
              ),
              
              // Content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white,
                              Colors.cyanAccent.withOpacity(0.8),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.hub_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // App Name
                      const Text(
                        'MESHNET',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
            color: Colors.white,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MESSENGER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Loading indicator
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: _animationController.value,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ESTABLISHING SECURE CONNECTION',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  final List<Widget> _screens = [
    const OrbitalChatListScreen(),
    const HoloRingsScreen(),
    const TimeCapsuleScreen(),
    const ShadowCloneScreen(),
    const SoulKeyScreen(),
    const MoodMessagingScreen(),
    const SteganographyScreen(),
    const QuantumCryptoScreen(),
    const NetworkView(),
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, 'Nodes', Icons.hub),
                  _buildNavItem(1, 'Rings', Icons.panorama_fish_eye),
                  _buildNavItem(2, 'Time', Icons.hourglass_empty),
                  _buildNavItem(3, 'Shadow', Icons.face),
                  _buildNavItem(4, 'Soul', Icons.vpn_key_rounded),
                  _buildNavItem(5, 'Mood', Icons.mood),
                  _buildNavItem(6, 'Stego', Icons.hide_image),
                  _buildNavItem(7, 'Quantum', Icons.security),
                  _buildNavItem(8, 'Network', Icons.wifi_tethering),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.5);
    
    return InkWell(
      onTap: () => _onTabTapped(index),
      child: Container(
        width: 80,
        height: 70,
        padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
                    Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            if (isSelected)
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                    ),
                  ],
                ),
              ),
            );
          }
}

class SplashBackgroundPainter extends CustomPainter {
  final double progress;
  
  SplashBackgroundPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Background gradient
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0f0f22),
          Color(0xFF1a1a3a),
          Color(0xFF0f0f22),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Horizontal grid lines
    final numHLines = 20;
    final hSpacing = height / numHLines;
    for (int i = 0; i < numHLines; i++) {
      final y = i * hSpacing;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(width, y);
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Vertical grid lines
    final numVLines = 15;
    final vSpacing = width / numVLines;
    for (int i = 0; i < numVLines; i++) {
      final x = i * vSpacing;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x, height);
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Draw network nodes
    final nodePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42);
    
    // Draw nodes
    final nodeCount = 50;
    List<Offset> nodes = [];
    
    for (int i = 0; i < nodeCount; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final nodeOffset = Offset(x, y);
      nodes.add(nodeOffset);
      
      final nodeSize = 2.0 + random.nextDouble() * 3.0;
      final opacity = 0.3 + random.nextDouble() * 0.7;
      
      // Only show nodes based on progress
      if (i <= nodeCount * progress) {
        nodePaint.color = Colors.cyanAccent.withOpacity(opacity);
        canvas.drawCircle(nodeOffset, nodeSize, nodePaint);
      }
    }
    
    // Draw connections based on progress
    if (progress > 0.1) {
      final linePaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      final maxConnections = (nodeCount * 2 * progress).round();
      int connectionCount = 0;
      
      for (int i = 0; i < nodes.length && connectionCount < maxConnections; i++) {
        for (int j = i + 1; j < nodes.length && connectionCount < maxConnections; j++) {
          final distance = (nodes[i] - nodes[j]).distance;
          
          // Only connect nearby nodes
          if (distance < width * 0.2) {
            final path = Path()
              ..moveTo(nodes[i].dx, nodes[i].dy)
              ..lineTo(nodes[j].dx, nodes[j].dy);
            
            // Fade in based on progress
            final opacity = math.min(1.0, (progress - 0.1) / 0.9) * 0.2 * (1.0 - distance / (width * 0.2));
            linePaint.color = Colors.cyanAccent.withOpacity(opacity);
            
            canvas.drawPath(path, linePaint);
            connectionCount++;
          }
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(SplashBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 