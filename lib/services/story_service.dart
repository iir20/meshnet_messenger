import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:location/location.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class StoryService extends ChangeNotifier {
  // Constants
  static const int storyDuration = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
  static const double defaultGeoFenceRadius = 5000.0; // 5km radius for geo-fenced stories
  
  // Story collections
  final List<Story> _myStories = [];
  final List<Story> _availableStories = [];
  
  // User ID
  final String _userId;
  
  // Services
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Location _location = Location();
  
  // Getters
  List<Story> get myStories => _myStories;
  List<Story> get availableStories => _availableStories
      .where((story) => _isStoryAvailable(story))
      .toList();
  
  // Private timer for cleaning expired stories
  Timer? _cleanupTimer;
  
  // Constructor
  StoryService(this._userId) {
    _loadStories();
    _startCleanupTimer();
    _requestLocationPermission();
  }
  
  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
  
  // Create a new story
  Future<Story> createStory({
    required File mediaFile,
    required StoryMediaType mediaType,
    String? caption,
    EmotionFilter? emotionFilter,
    GeoFence? geoFence,
    bool requireBiometric = false,
    bool isCrisisMode = false,
    String? hiddenSOSMessage,
  }) async {
    final String mediaPath = await _saveMediaFile(mediaFile);
    
    final story = Story(
      id: const Uuid().v4(),
      userId: _userId,
      mediaPath: mediaPath,
      mediaType: mediaType,
      caption: caption,
      emotionFilter: emotionFilter,
      geoFence: geoFence,
      requireBiometric: requireBiometric,
      isCrisisMode: isCrisisMode,
      hiddenSOSMessage: hiddenSOSMessage,
      createdAt: DateTime.now(),
      views: [],
    );
    
    _myStories.add(story);
    await _saveStories();
    notifyListeners();
    
    return story;
  }
  
  // Delete a story
  Future<void> deleteStory(String storyId) async {
    final storyIndex = _myStories.indexWhere((story) => story.id == storyId);
    
    if (storyIndex != -1) {
      final story = _myStories[storyIndex];
      
      // Delete the media file
      try {
        final file = File(story.mediaPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting story media: $e');
      }
      
      _myStories.removeAt(storyIndex);
      await _saveStories();
      notifyListeners();
    }
  }
  
  // View a story
  Future<bool> viewStory(String storyId) async {
    final storyIndex = _availableStories.indexWhere((story) => story.id == storyId);
    
    if (storyIndex != -1) {
      final story = _availableStories[storyIndex];
      
      // Check if the story requires biometric authentication
      if (story.requireBiometric) {
        final authenticated = await _authenticateWithBiometrics();
        if (!authenticated) {
          return false;
        }
      }
      
      // Check if the story is geo-fenced
      if (story.geoFence != null) {
        final withinFence = await _isWithinGeoFence(story.geoFence!);
        if (!withinFence) {
          return false;
        }
      }
      
      // Add the current user to the views
      if (!story.views.contains(_userId)) {
        story.views.add(_userId);
      }
      
      await _saveStories();
      notifyListeners();
      return true;
    }
    
    return false;
  }
  
  // Add stories from another user
  void addAvailableStories(List<Story> stories) {
    // Add only stories that aren't already in the list
    for (final story in stories) {
      if (!_availableStories.any((s) => s.id == story.id)) {
        _availableStories.add(story);
      }
    }
    
    notifyListeners();
  }
  
  // Check if a story is still available (not expired)
  bool _isStoryAvailable(Story story) {
    final now = DateTime.now();
    final expirationTime = story.createdAt.add(const Duration(milliseconds: storyDuration));
    
    return now.isBefore(expirationTime);
  }
  
  // Start the cleanup timer
  void _startCleanupTimer() {
    // Run cleanup every hour
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _cleanupExpiredStories(),
    );
    
    // Also run it immediately
    _cleanupExpiredStories();
  }
  
  // Cleanup expired stories
  Future<void> _cleanupExpiredStories() async {
    final now = DateTime.now();
    
    // Remove expired stories from my stories
    _myStories.removeWhere((story) {
      final expirationTime = story.createdAt.add(const Duration(milliseconds: storyDuration));
      return now.isAfter(expirationTime);
    });
    
    // Remove expired stories from available stories
    _availableStories.removeWhere((story) {
      final expirationTime = story.createdAt.add(const Duration(milliseconds: storyDuration));
      return now.isAfter(expirationTime);
    });
    
    await _saveStories();
    notifyListeners();
  }
  
  // Save the media file to local storage
  Future<String> _saveMediaFile(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final storiesDir = Directory('${directory.path}/stories');
    
    if (!await storiesDir.exists()) {
      await storiesDir.create(recursive: true);
    }
    
    final filename = '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}${extension(sourceFile.path)}';
    final targetPath = '${storiesDir.path}/$filename';
    
    await sourceFile.copy(targetPath);
    
    return targetPath;
  }
  
  // Get the file extension from a path
  String extension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }
  
  // Load stories from local storage
  Future<void> _loadStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load my stories
      final myStoriesJson = prefs.getStringList('my_stories') ?? [];
      _myStories.clear();
      
      for (final storyJson in myStoriesJson) {
        final storyMap = jsonDecode(storyJson) as Map<String, dynamic>;
        final story = Story.fromJson(storyMap);
        
        // Check if the media file exists
        final mediaFile = File(story.mediaPath);
        if (await mediaFile.exists()) {
          _myStories.add(story);
        }
      }
      
      // Load available stories
      final availableStoriesJson = prefs.getStringList('available_stories') ?? [];
      _availableStories.clear();
      
      for (final storyJson in availableStoriesJson) {
        final storyMap = jsonDecode(storyJson) as Map<String, dynamic>;
        _availableStories.add(Story.fromJson(storyMap));
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stories: $e');
    }
  }
  
  // Save stories to local storage
  Future<void> _saveStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save my stories
      final myStoriesJson = _myStories.map((story) => jsonEncode(story.toJson())).toList();
      await prefs.setStringList('my_stories', myStoriesJson);
      
      // Save available stories
      final availableStoriesJson = _availableStories.map((story) => jsonEncode(story.toJson())).toList();
      await prefs.setStringList('available_stories', availableStoriesJson);
    } catch (e) {
      debugPrint('Error saving stories: $e');
    }
  }
  
  // Request location permission
  Future<void> _requestLocationPermission() async {
    try {
      final hasPermission = await _location.hasPermission();
      
      if (hasPermission == PermissionStatus.denied) {
        await _location.requestPermission();
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
    }
  }
  
  // Check if the user is within a geo-fence
  Future<bool> _isWithinGeoFence(GeoFence geoFence) async {
    try {
      final locationData = await _location.getLocation();
      
      // Calculate distance from the center of the geo-fence
      final distance = _calculateDistance(
        locationData.latitude ?? 0,
        locationData.longitude ?? 0,
        geoFence.latitude,
        geoFence.longitude,
      );
      
      // Check if within the radius
      return distance <= geoFence.radius;
    } catch (e) {
      debugPrint('Error checking geo-fence: $e');
      return false;
    }
  }
  
  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2,
  ) {
    const R = 6371000; // Earth radius in meters
    
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;
    
    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
            math.cos(phi1) * math.cos(phi2) *
            math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return R * c; // Distance in meters
  }
  
  // Authenticate with biometrics
  Future<bool> _authenticateWithBiometrics() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      
      if (!canAuthenticate) {
        return false;
      }
      
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to view this story',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }
  
  // Check if device supports biometrics
  Future<bool> get supportsBiometrics async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }
}

// Story model
class Story {
  final String id;
  final String userId;
  final String mediaPath;
  final StoryMediaType mediaType;
  final String? caption;
  final EmotionFilter? emotionFilter;
  final GeoFence? geoFence;
  final bool requireBiometric;
  final bool isCrisisMode;
  final String? hiddenSOSMessage;
  final DateTime createdAt;
  final List<String> views;
  
  Story({
    required this.id,
    required this.userId,
    required this.mediaPath,
    required this.mediaType,
    this.caption,
    this.emotionFilter,
    this.geoFence,
    this.requireBiometric = false,
    this.isCrisisMode = false,
    this.hiddenSOSMessage,
    required this.createdAt,
    required this.views,
  });
  
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      userId: json['userId'],
      mediaPath: json['mediaPath'],
      mediaType: StoryMediaType.values[json['mediaType']],
      caption: json['caption'],
      emotionFilter: json['emotionFilter'] != null
          ? EmotionFilter.values[json['emotionFilter']]
          : null,
      geoFence: json['geoFence'] != null
          ? GeoFence.fromJson(json['geoFence'])
          : null,
      requireBiometric: json['requireBiometric'] ?? false,
      isCrisisMode: json['isCrisisMode'] ?? false,
      hiddenSOSMessage: json['hiddenSOSMessage'],
      createdAt: DateTime.parse(json['createdAt']),
      views: List<String>.from(json['views'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mediaPath': mediaPath,
      'mediaType': mediaType.index,
      'caption': caption,
      'emotionFilter': emotionFilter?.index,
      'geoFence': geoFence?.toJson(),
      'requireBiometric': requireBiometric,
      'isCrisisMode': isCrisisMode,
      'hiddenSOSMessage': hiddenSOSMessage,
      'createdAt': createdAt.toIso8601String(),
      'views': views,
    };
  }
  
  // Copy the story with new values
  Story copyWith({
    String? id,
    String? userId,
    String? mediaPath,
    StoryMediaType? mediaType,
    String? caption,
    EmotionFilter? emotionFilter,
    GeoFence? geoFence,
    bool? requireBiometric,
    bool? isCrisisMode,
    String? hiddenSOSMessage,
    DateTime? createdAt,
    List<String>? views,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      emotionFilter: emotionFilter ?? this.emotionFilter,
      geoFence: geoFence ?? this.geoFence,
      requireBiometric: requireBiometric ?? this.requireBiometric,
      isCrisisMode: isCrisisMode ?? this.isCrisisMode,
      hiddenSOSMessage: hiddenSOSMessage ?? this.hiddenSOSMessage,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
    );
  }
  
  // Check if the story is expired
  bool get isExpired {
    final now = DateTime.now();
    final expirationTime = createdAt.add(const Duration(milliseconds: StoryService.storyDuration));
    
    return now.isAfter(expirationTime);
  }
  
  // Get time left before expiration
  Duration get timeLeft {
    final now = DateTime.now();
    final expirationTime = createdAt.add(const Duration(milliseconds: StoryService.storyDuration));
    
    if (now.isAfter(expirationTime)) {
      return Duration.zero;
    }
    
    return expirationTime.difference(now);
  }
  
  // Get expiration time as a formatted string
  String get expirationTimeFormatted {
    final expirationTime = createdAt.add(const Duration(milliseconds: StoryService.storyDuration));
    
    final hours = expirationTime.hour.toString().padLeft(2, '0');
    final minutes = expirationTime.minute.toString().padLeft(2, '0');
    
    return '$hours:$minutes';
  }
  
  // Calculate percentage of time left
  double get timeLeftPercentage {
    if (isExpired) return 0.0;
    
    final totalDuration = StoryService.storyDuration;
    final elapsedTime = DateTime.now().difference(createdAt).inMilliseconds;
    
    return (totalDuration - elapsedTime) / totalDuration;
  }
}

// Media type enum
enum StoryMediaType {
  image,
  video,
  text,
  audio,
  ar,
}

// Emotion filter enum
enum EmotionFilter {
  none,
  joy,
  sadness,
  fear,
  anger,
  surprise,
  disgust,
  love,
  hope,
  pride,
}

// Geo-fence model
class GeoFence {
  final double latitude;
  final double longitude;
  final double radius; // In meters
  
  GeoFence({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });
  
  factory GeoFence.fromJson(Map<String, dynamic> json) {
    return GeoFence(
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }
} 