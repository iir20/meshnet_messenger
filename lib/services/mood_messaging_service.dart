import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that handles mood detection and adaptive messaging
class MoodMessagingService extends ChangeNotifier {
  // Mood states
  final List<MoodState> _availableMoods = [
    MoodState(
      id: 'calm',
      name: 'Calm',
      color: Colors.blue,
      gradient: const LinearGradient(
        colors: [Color(0xFF2980B9), Color(0xFF6DD5FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      fontStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
        height: 1.4,
      ),
      animationIntensity: 0.3,
      soundEffect: 'calm_notification.mp3',
      messageModifier: (String message) => message,
    ),
    MoodState(
      id: 'happy',
      name: 'Happy',
      color: Colors.amber,
      gradient: const LinearGradient(
        colors: [Color(0xFFFDC830), Color(0xFFF37335)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      fontStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.2,
      ),
      animationIntensity: 0.7,
      soundEffect: 'happy_notification.mp3',
      messageModifier: (String message) => message.endsWith('!') ? message : '$message!',
    ),
    MoodState(
      id: 'excited',
      name: 'Excited',
      color: Colors.orange,
      gradient: const LinearGradient(
        colors: [Color(0xFFF953C6), Color(0xFFB91D73)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      fontStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        height: 1.1,
      ),
      animationIntensity: 1.0,
      soundEffect: 'excited_notification.mp3',
      messageModifier: (String message) => message.toUpperCase(),
    ),
    MoodState(
      id: 'creative',
      name: 'Creative',
      color: Colors.purple,
      gradient: const LinearGradient(
        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      fontStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.3,
        height: 1.3,
        shadows: [
          Shadow(
            blurRadius: 2.0,
            color: Colors.purple.withOpacity(0.3),
            offset: const Offset(1, 1),
          ),
        ],
      ),
      animationIntensity: 0.8,
      soundEffect: 'creative_notification.mp3',
      messageModifier: (String message) => '~ $message ~',
    ),
    MoodState(
      id: 'focused',
      name: 'Focused',
      color: Colors.teal,
      gradient: const LinearGradient(
        colors: [Color(0xFF43C6AC), Color(0xFF191654)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      fontStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        height: 1.4,
        wordSpacing: 2.0,
      ),
      animationIntensity: 0.4,
      soundEffect: 'focused_notification.mp3',
      messageModifier: (String message) => message,
    ),
    MoodState(
      id: 'neutral',
      name: 'Neutral',
      color: Colors.blueGrey,
      gradient: const LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      fontStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
        height: 1.4,
      ),
      animationIntensity: 0.5,
      soundEffect: 'neutral_notification.mp3',
      messageModifier: (String message) => message,
    ),
    MoodState(
      id: 'reflective',
      name: 'Reflective',
      color: Colors.indigo,
      gradient: const LinearGradient(
        colors: [Color(0xFF3A1C71), Color(0xFFD76D77)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      fontStyle: const TextStyle(
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.7,
        height: 1.6,
      ),
      animationIntensity: 0.3,
      soundEffect: 'reflective_notification.mp3',
      messageModifier: (String message) => '... $message ...',
    ),
  ];
  
  // Current mood state
  String _currentMoodId = 'neutral';
  
  // User preferences
  bool _adaptMessagesToMood = true;
  bool _adaptUIToMood = true;
  bool _useCameraForMoodDetection = false;
  
  // Camera controller for facial expression detection
  CameraController? _cameraController;
  Timer? _moodDetectionTimer;
  
  // Getters
  MoodState get currentMood => _getMoodById(_currentMoodId);
  bool get adaptMessagesToMood => _adaptMessagesToMood;
  bool get adaptUIToMood => _adaptUIToMood;
  bool get useCameraForMoodDetection => _useCameraForMoodDetection;
  List<MoodState> get availableMoods => _availableMoods;
  
  // Constructor
  MoodMessagingService() {
    _loadPreferences();
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    _moodDetectionTimer?.cancel();
    super.dispose();
  }
  
  // Initialize camera for mood detection
  Future<void> initializeCameraMoodDetection() async {
    if (!_useCameraForMoodDetection) return;
    
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _cameraController!.initialize();
      
      // Start mood detection timer
      _moodDetectionTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _detectMoodFromCamera(),
      );
      
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }
  
  // Detect mood from camera
  Future<void> _detectMoodFromCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      final image = await _cameraController!.takePicture();
      
      // Here you would normally send the image to an emotion detection API
      // For demo purposes, we'll simulate with random mood selection
      _simulateMoodDetection();
      
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }
  
  // Simulate mood detection (in a real app, this would use ML)
  void _simulateMoodDetection() {
    final random = math.Random();
    final randomIndex = random.nextInt(_availableMoods.length);
    final newMood = _availableMoods[randomIndex].id;
    
    if (newMood != _currentMoodId) {
      _currentMoodId = newMood;
      notifyListeners();
    }
  }
  
  // Set mood manually
  void setMood(String moodId) {
    if (_getMoodById(moodId).id != 'unknown') {
      _currentMoodId = moodId;
      _savePreferences();
      notifyListeners();
    }
  }
  
  // Get MoodState by ID
  MoodState _getMoodById(String id) {
    return _availableMoods.firstWhere(
      (mood) => mood.id == id,
      orElse: () => MoodState(
        id: 'unknown',
        name: 'Unknown',
        color: Colors.grey,
        gradient: const LinearGradient(
          colors: [Colors.grey, Colors.blueGrey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        fontStyle: const TextStyle(),
        animationIntensity: 0.5,
        soundEffect: 'default_notification.mp3',
        messageModifier: (String message) => message,
      ),
    );
  }
  
  // Apply mood to message
  String applyMoodToMessage(String message, {String? overrideMoodId}) {
    if (!_adaptMessagesToMood) return message;
    
    final mood = overrideMoodId != null
        ? _getMoodById(overrideMoodId)
        : currentMood;
    
    return mood.messageModifier(message);
  }
  
  // Apply mood to message bubble style
  MessageBubbleStyle getMessageBubbleStyle({String? overrideMoodId}) {
    final mood = overrideMoodId != null
        ? _getMoodById(overrideMoodId)
        : currentMood;
    
    return MessageBubbleStyle(
      gradient: mood.gradient,
      fontStyle: mood.fontStyle,
      animationIntensity: mood.animationIntensity,
    );
  }
  
  // Toggle UI adaptation
  void toggleUIAdaptation() {
    _adaptUIToMood = !_adaptUIToMood;
    _savePreferences();
    notifyListeners();
  }
  
  // Toggle message adaptation
  void toggleMessageAdaptation() {
    _adaptMessagesToMood = !_adaptMessagesToMood;
    _savePreferences();
    notifyListeners();
  }
  
  // Toggle camera mood detection
  Future<void> toggleCameraMoodDetection() async {
    _useCameraForMoodDetection = !_useCameraForMoodDetection;
    
    if (_useCameraForMoodDetection) {
      await initializeCameraMoodDetection();
    } else {
      await _cameraController?.dispose();
      _cameraController = null;
      _moodDetectionTimer?.cancel();
      _moodDetectionTimer = null;
    }
    
    _savePreferences();
    notifyListeners();
  }
  
  // Analyze message text for emotion
  String detectMoodFromText(String text) {
    // Simple keyword-based emotion detection
    // In a real app, this would use ML-based sentiment analysis
    
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('excited') || 
        lowerText.contains('amazing') || 
        lowerText.contains('wow') ||
        lowerText.contains('awesome')) {
      return 'excited';
    }
    
    if (lowerText.contains('happy') || 
        lowerText.contains('glad') || 
        lowerText.contains('great') ||
        lowerText.contains('good')) {
      return 'happy';
    }
    
    if (lowerText.contains('calm') || 
        lowerText.contains('peaceful') || 
        lowerText.contains('relaxed')) {
      return 'calm';
    }
    
    if (lowerText.contains('creative') || 
        lowerText.contains('imagine') || 
        lowerText.contains('idea')) {
      return 'creative';
    }
    
    if (lowerText.contains('focus') || 
        lowerText.contains('attention') || 
        lowerText.contains('concentrate')) {
      return 'focused';
    }
    
    if (lowerText.contains('think') || 
        lowerText.contains('wonder') || 
        lowerText.contains('reflect')) {
      return 'reflective';
    }
    
    return 'neutral';
  }
  
  // Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _currentMoodId = prefs.getString('current_mood_id') ?? 'neutral';
      _adaptMessagesToMood = prefs.getBool('adapt_messages_to_mood') ?? true;
      _adaptUIToMood = prefs.getBool('adapt_ui_to_mood') ?? true;
      _useCameraForMoodDetection = prefs.getBool('use_camera_for_mood_detection') ?? false;
      
      if (_useCameraForMoodDetection) {
        await initializeCameraMoodDetection();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading mood preferences: $e');
    }
  }
  
  // Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('current_mood_id', _currentMoodId);
      await prefs.setBool('adapt_messages_to_mood', _adaptMessagesToMood);
      await prefs.setBool('adapt_ui_to_mood', _adaptUIToMood);
      await prefs.setBool('use_camera_for_mood_detection', _useCameraForMoodDetection);
    } catch (e) {
      debugPrint('Error saving mood preferences: $e');
    }
  }
}

/// Model representing a mood state
class MoodState {
  final String id;
  final String name;
  final Color color;
  final LinearGradient gradient;
  final TextStyle fontStyle;
  final double animationIntensity;
  final String soundEffect;
  final String Function(String) messageModifier;
  
  MoodState({
    required this.id,
    required this.name,
    required this.color,
    required this.gradient,
    required this.fontStyle,
    required this.animationIntensity,
    required this.soundEffect,
    required this.messageModifier,
  });
}

/// Model for message bubble styling based on mood
class MessageBubbleStyle {
  final LinearGradient gradient;
  final TextStyle fontStyle;
  final double animationIntensity;
  
  const MessageBubbleStyle({
    required this.gradient,
    required this.fontStyle,
    required this.animationIntensity,
  });
} 