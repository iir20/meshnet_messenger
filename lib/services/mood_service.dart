import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MoodType {
  neutral,
  happy,
  sad,
  angry,
  excited,
  calm,
  curious,
  anxious,
  reflective
}

class MoodService extends ChangeNotifier {
  static const String _currentMoodKey = 'current_mood';
  static const String _autoDetectKey = 'auto_detect_mood';
  static const String _lastChangedKey = 'mood_last_changed';
  
  MoodType _currentMood = MoodType.neutral;
  bool _autoDetectMood = true;
  DateTime _lastMoodChange = DateTime.now();
  Timer? _autoChangeTimer;
  
  // Getters
  MoodType get currentMood => _currentMood;
  bool get autoDetectMood => _autoDetectMood;
  DateTime get lastMoodChange => _lastMoodChange;
  
  // Initialize mood service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved mood
    final savedMood = prefs.getString(_currentMoodKey);
    if (savedMood != null) {
      _currentMood = MoodType.values.firstWhere(
        (m) => m.toString() == savedMood,
        orElse: () => MoodType.neutral,
      );
    }
    
    // Load auto-detect setting
    _autoDetectMood = prefs.getBool(_autoDetectKey) ?? true;
    
    // Load last changed timestamp
    final lastChanged = prefs.getInt(_lastChangedKey);
    if (lastChanged != null) {
      _lastMoodChange = DateTime.fromMillisecondsSinceEpoch(lastChanged);
    }
    
    // Start auto-detection if enabled
    if (_autoDetectMood) {
      _startAutoDetection();
    }
    
    notifyListeners();
  }
  
  // Manually set the mood
  Future<void> setMood(MoodType mood) async {
    if (_currentMood != mood) {
      _currentMood = mood;
      _lastMoodChange = DateTime.now();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentMoodKey, mood.toString());
      await prefs.setInt(_lastChangedKey, _lastMoodChange.millisecondsSinceEpoch);
      
      // Provide haptic feedback for mood change
      HapticFeedback.mediumImpact();
      
      notifyListeners();
    }
  }
  
  // Toggle auto-detection
  Future<void> toggleAutoDetect() async {
    _autoDetectMood = !_autoDetectMood;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoDetectKey, _autoDetectMood);
    
    if (_autoDetectMood) {
      _startAutoDetection();
    } else {
      _stopAutoDetection();
    }
    
    notifyListeners();
  }
  
  // Auto-detect mood from text
  Future<MoodType> detectMoodFromText(String text) async {
    // This is a placeholder implementation.
    // In a real app, this would use natural language processing or ML
    // to detect the emotional tone of the message.
    
    // Simple keyword matching for demo
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('happy') || 
        lowerText.contains('great') || 
        lowerText.contains('awesome') ||
        lowerText.contains('😊') ||
        lowerText.contains('😀')) {
      return MoodType.happy;
    } else if (lowerText.contains('sad') || 
               lowerText.contains('upset') || 
               lowerText.contains('disappointed') ||
               lowerText.contains('😢') ||
               lowerText.contains('😭')) {
      return MoodType.sad;
    } else if (lowerText.contains('angry') || 
               lowerText.contains('annoyed') || 
               lowerText.contains('frustrated') ||
               lowerText.contains('😠') ||
               lowerText.contains('😡')) {
      return MoodType.angry;
    } else if (lowerText.contains('excited') || 
               lowerText.contains('thrilled') || 
               lowerText.contains('wow') ||
               lowerText.contains('🤩') ||
               lowerText.contains('😃')) {
      return MoodType.excited;
    } else if (lowerText.contains('calm') || 
               lowerText.contains('relaxed') || 
               lowerText.contains('peaceful') ||
               lowerText.contains('😌') ||
               lowerText.contains('🧘')) {
      return MoodType.calm;
    } else if (lowerText.contains('curious') || 
               lowerText.contains('interesting') || 
               lowerText.contains('wonder') ||
               lowerText.contains('🤔') ||
               lowerText.contains('❓')) {
      return MoodType.curious;
    } else if (lowerText.contains('anxious') || 
               lowerText.contains('worried') || 
               lowerText.contains('nervous') ||
               lowerText.contains('😰') ||
               lowerText.contains('😨')) {
      return MoodType.anxious;
    } else if (lowerText.contains('think') || 
               lowerText.contains('remember') || 
               lowerText.contains('reflect') ||
               lowerText.contains('🤔') ||
               lowerText.contains('💭')) {
      return MoodType.reflective;
    }
    
    return MoodType.neutral;
  }
  
  // Auto-detect mood from camera (placeholder implementation)
  Future<MoodType> detectMoodFromCamera() async {
    // This is a placeholder implementation.
    // In a real app, this would use face detection and emotion recognition.
    
    // For demo, just return a random mood
    final moods = [
      MoodType.neutral, 
      MoodType.happy, 
      MoodType.sad,
      MoodType.excited,
      MoodType.calm,
    ];
    
    return moods[math.Random().nextInt(moods.length)];
  }
  
  // Process a message and update mood if relevant
  Future<void> processMessage(String text) async {
    if (!_autoDetectMood) return;
    
    final detectedMood = await detectMoodFromText(text);
    
    // Only update if the detected mood is significant
    if (detectedMood != MoodType.neutral) {
      await setMood(detectedMood);
    }
  }
  
  // Start auto-detection
  void _startAutoDetection() {
    // Cancel any existing timer
    _stopAutoDetection();
    
    // In a real app, this would use more sophisticated methods
    // For demo, randomly change mood every few minutes
    _autoChangeTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_autoDetectMood) {
        final newMood = await detectMoodFromCamera();
        await setMood(newMood);
      }
    });
  }
  
  // Stop auto-detection
  void _stopAutoDetection() {
    _autoChangeTimer?.cancel();
    _autoChangeTimer = null;
  }
  
  @override
  void dispose() {
    _stopAutoDetection();
    super.dispose();
  }
  
  // Get color scheme based on mood
  ColorScheme getMoodColorScheme(bool isDark) {
    switch (_currentMood) {
      case MoodType.happy:
        return ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFFFFD700), // Gold
          onPrimary: Colors.black,
          secondary: const Color(0xFFFFA000), // Amber
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          background: isDark ? Colors.black : Colors.yellow.shade50,
          onBackground: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
        );
      
      case MoodType.sad:
        return ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFF64B5F6), // Light Blue
          onPrimary: Colors.black,
          secondary: const Color(0xFF2196F3), // Blue
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: isDark ? Colors.black : Colors.blue.shade50,
          onBackground: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
        );
        
      case MoodType.angry:
        return ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFFFF5252), // Red
          onPrimary: Colors.white,
          secondary: const Color(0xFFFF1744), // Dark Red
          onSecondary: Colors.white,
          error: Colors.yellow,
          onError: Colors.black,
          background: isDark ? Colors.black : Colors.red.shade50,
          onBackground: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
        );
        
      case MoodType.excited:
        return ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFFFF9800), // Orange
          onPrimary: Colors.black,
          secondary: const Color(0xFFFF6D00), // Deep Orange
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: isDark ? Colors.black : Colors.orange.shade50,
          onBackground: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
        );
        
      case MoodType.calm:
        return ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFF4CAF50), // Green
          onPrimary: Colors.black,
          secondary: const Color(0xFF388E3C), // Dark Green
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: isDark ? Colors.black : Colors.green.shade50,
          onBackground: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
        );
        
      case MoodType.curious:
        return ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFF9C27B0), // Purple
          onPrimary: Colors.white,
          secondary: const Color(0xFF7B1FA2), // Dark Purple
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: isDark ? Colors.black : Colors.purple.shade50,
          onBackground: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
        );
        
      case MoodType.anxious:
        return ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFFFFEB3B), // Yellow
          onPrimary: Colors.black,
          secondary: const Color(0xFFFBC02D), // Dark Yellow
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          background: isDark ? Colors.black : Colors.yellow.shade50,
          onBackground: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
        );
        
      case MoodType.reflective:
        return ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFF607D8B), // Blue Grey
          onPrimary: Colors.white,
          secondary: const Color(0xFF455A64), // Dark Blue Grey
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: isDark ? Colors.black : Colors.blueGrey.shade50,
          onBackground: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
        );
        
      case MoodType.neutral:
      default:
        return ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFF00E5FF), // Cyan
          onPrimary: Colors.black,
          secondary: const Color(0xFF00B8D4), // Dark Cyan
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          background: isDark ? Colors.black : Colors.grey.shade50,
          onBackground: isDark ? Colors.white : Colors.black,
          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
        );
    }
  }
  
  // Get background particle settings based on mood
  MoodParticleSettings getParticleSettings() {
    switch (_currentMood) {
      case MoodType.happy:
        return MoodParticleSettings(
          particleCount: 40,
          colors: [Colors.yellow, Colors.amber, Colors.orange],
          speed: 1.5,
          size: 3.0,
          variance: 0.8,
        );
        
      case MoodType.sad:
        return MoodParticleSettings(
          particleCount: 20,
          colors: [Colors.blue.shade200, Colors.blue.shade300, Colors.blue.shade400],
          speed: 0.5,
          size: 2.0,
          variance: 0.4,
        );
        
      case MoodType.angry:
        return MoodParticleSettings(
          particleCount: 60,
          colors: [Colors.red, Colors.redAccent, Colors.deepOrange],
          speed: 2.0,
          size: 2.5,
          variance: 1.0,
        );
        
      case MoodType.excited:
        return MoodParticleSettings(
          particleCount: 50,
          colors: [Colors.orange, Colors.deepOrange, Colors.amber],
          speed: 1.8,
          size: 3.0,
          variance: 0.9,
        );
        
      case MoodType.calm:
        return MoodParticleSettings(
          particleCount: 30,
          colors: [Colors.green.shade200, Colors.green.shade300, Colors.teal.shade200],
          speed: 0.7,
          size: 2.0,
          variance: 0.5,
        );
        
      case MoodType.curious:
        return MoodParticleSettings(
          particleCount: 35,
          colors: [Colors.purple.shade200, Colors.purple.shade300, Colors.deepPurple.shade200],
          speed: 1.2,
          size: 2.5,
          variance: 0.7,
        );
        
      case MoodType.anxious:
        return MoodParticleSettings(
          particleCount: 45,
          colors: [Colors.yellow, Colors.amber, Colors.yellow.shade700],
          speed: 1.5,
          size: 2.0,
          variance: 1.0,
        );
        
      case MoodType.reflective:
        return MoodParticleSettings(
          particleCount: 25,
          colors: [Colors.blueGrey.shade200, Colors.blueGrey.shade300, Colors.grey.shade300],
          speed: 0.8,
          size: 2.0,
          variance: 0.6,
        );
        
      case MoodType.neutral:
      default:
        return MoodParticleSettings(
          particleCount: 30,
          colors: [Colors.cyan.shade200, Colors.cyan.shade300, Colors.lightBlue.shade200],
          speed: 1.0,
          size: 2.5,
          variance: 0.6,
        );
    }
  }
  
  // Get animation settings based on mood
  MoodAnimationSettings getAnimationSettings() {
    switch (_currentMood) {
      case MoodType.happy:
        return MoodAnimationSettings(
          transitionDuration: const Duration(milliseconds: 300),
          pulseDuration: const Duration(seconds: 2),
          pulseIntensity: 0.1,
          shouldBounce: true,
        );
        
      case MoodType.sad:
        return MoodAnimationSettings(
          transitionDuration: const Duration(milliseconds: 500),
          pulseDuration: const Duration(seconds: 4),
          pulseIntensity: 0.05,
          shouldBounce: false,
        );
        
      case MoodType.angry:
        return MoodAnimationSettings(
          transitionDuration: const Duration(milliseconds: 200),
          pulseDuration: const Duration(milliseconds: 800),
          pulseIntensity: 0.15,
          shouldBounce: true,
        );
        
      case MoodType.excited:
        return MoodAnimationSettings(
          transitionDuration: const Duration(milliseconds: 250),
          pulseDuration: const Duration(milliseconds: 1500),
          pulseIntensity: 0.12,
          shouldBounce: true,
        );
        
      case MoodType.calm:
        return MoodAnimationSettings(
          transitionDuration: const Duration(milliseconds: 700),
          pulseDuration: const Duration(seconds: 3),
          pulseIntensity: 0.04,
          shouldBounce: false,
        );
        
      case MoodType.curious:
        return MoodAnimationSettings(
          transitionDuration: const Duration(milliseconds: 400),
          pulseDuration: const Duration(seconds: 2),
          pulseIntensity: 0.08,
          shouldBounce: true,
        );
        
      case MoodType.anxious:
        return MoodAnimationSettings(
          transitionDuration: const Duration(milliseconds: 300),
          pulseDuration: const Duration(milliseconds: 1200),
          pulseIntensity: 0.12,
          shouldBounce: true,
        );
        
      case MoodType.reflective:
        return MoodAnimationSettings(
          transitionDuration: const Duration(milliseconds: 600),
          pulseDuration: const Duration(seconds: 4),
          pulseIntensity: 0.06,
          shouldBounce: false,
        );
        
      case MoodType.neutral:
      default:
        return MoodAnimationSettings(
          transitionDuration: const Duration(milliseconds: 400),
          pulseDuration: const Duration(seconds: 3),
          pulseIntensity: 0.07,
          shouldBounce: false,
        );
    }
  }
  
  // Get haptic feedback pattern based on mood
  HapticFeedbackType getHapticFeedbackType() {
    switch (_currentMood) {
      case MoodType.happy:
        return HapticFeedbackType.gentle;
        
      case MoodType.sad:
        return HapticFeedbackType.soft;
        
      case MoodType.angry:
        return HapticFeedbackType.strong;
        
      case MoodType.excited:
        return HapticFeedbackType.burst;
        
      case MoodType.anxious:
        return HapticFeedbackType.rapid;
        
      default:
        return HapticFeedbackType.medium;
    }
  }
  
  // Get emoji representation of mood
  String getMoodEmoji() {
    switch (_currentMood) {
      case MoodType.happy:
        return '😊';
      case MoodType.sad:
        return '😢';
      case MoodType.angry:
        return '😠';
      case MoodType.excited:
        return '🤩';
      case MoodType.calm:
        return '😌';
      case MoodType.curious:
        return '🤔';
      case MoodType.anxious:
        return '😰';
      case MoodType.reflective:
        return '💭';
      case MoodType.neutral:
      default:
        return '😐';
    }
  }
  
  // Get display name for mood
  String getMoodDisplayName() {
    switch (_currentMood) {
      case MoodType.happy:
        return 'Happy';
      case MoodType.sad:
        return 'Sad';
      case MoodType.angry:
        return 'Angry';
      case MoodType.excited:
        return 'Excited';
      case MoodType.calm:
        return 'Calm';
      case MoodType.curious:
        return 'Curious';
      case MoodType.anxious:
        return 'Anxious';
      case MoodType.reflective:
        return 'Reflective';
      case MoodType.neutral:
      default:
        return 'Neutral';
    }
  }
}

// Particle system settings based on mood
class MoodParticleSettings {
  final int particleCount;
  final List<Color> colors;
  final double speed;
  final double size;
  final double variance;
  
  MoodParticleSettings({
    required this.particleCount,
    required this.colors,
    required this.speed,
    required this.size,
    required this.variance,
  });
}

// Animation settings based on mood
class MoodAnimationSettings {
  final Duration transitionDuration;
  final Duration pulseDuration;
  final double pulseIntensity;
  final bool shouldBounce;
  
  MoodAnimationSettings({
    required this.transitionDuration,
    required this.pulseDuration,
    required this.pulseIntensity,
    required this.shouldBounce,
  });
}

// Haptic feedback types
enum HapticFeedbackType {
  soft,
  gentle,
  medium,
  strong,
  burst,
  rapid
}

// Mood Overlay Widget
class MoodOverlay extends StatelessWidget {
  final Widget child;
  
  const MoodOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final moodService = Provider.of<MoodService>(context);
    final particleSettings = moodService.getParticleSettings();
    
    return Stack(
      children: [
        // Particle background
        Positioned.fill(
          child: CustomPaint(
            painter: _MoodParticlePainter(
              particleCount: particleSettings.particleCount,
              colors: particleSettings.colors,
              speed: particleSettings.speed,
              size: particleSettings.size,
              variance: particleSettings.variance,
            ),
            size: Size.infinite,
          ),
        ),
        
        // Child content
        child,
      ],
    );
  }
}

// Custom painter for mood particles
class _MoodParticlePainter extends CustomPainter {
  final int particleCount;
  final List<Color> colors;
  final double speed;
  final double size;
  final double variance;
  final List<_MoodParticle> _particles = [];
  final math.Random _random = math.Random();
  
  _MoodParticlePainter({
    required this.particleCount,
    required this.colors,
    required this.speed,
    required this.size,
    required this.variance,
  });
  
  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (_particles.isEmpty) {
      _initializeParticles(canvasSize);
    }
    
    for (var particle in _particles) {
      // Update position
      particle.position = Offset(
        (particle.position.dx + particle.velocity.dx * speed) % canvasSize.width,
        (particle.position.dy + particle.velocity.dy * speed) % canvasSize.height,
      );
      
      // Draw particle
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        particle.position,
        particle.size,
        paint,
      );
    }
  }
  
  void _initializeParticles(Size size) {
    for (var i = 0; i < particleCount; i++) {
      final randomColor = colors[_random.nextInt(colors.length)];
      final randomSize = size * (_random.nextDouble() * variance + 0.5);
      
      _particles.add(
        _MoodParticle(
          position: Offset(
            _random.nextDouble() * size.width,
            _random.nextDouble() * size.height,
          ),
          velocity: Offset(
            (_random.nextDouble() - 0.5) * variance,
            (_random.nextDouble() - 0.5) * variance,
          ),
          color: randomColor,
          size: randomSize,
          opacity: _random.nextDouble() * 0.3 + 0.1,
        ),
      );
    }
  }
  
  @override
  bool shouldRepaint(_MoodParticlePainter oldDelegate) => true;
}

// Helper class for mood particles
class _MoodParticle {
  Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  final double opacity;
  
  _MoodParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.opacity,
  });
} 