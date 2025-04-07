import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:location/location.dart';
import '../../services/story_service.dart';
import '../../widgets/glass_card.dart';

class StoryViewer extends StatefulWidget {
  final Story story;
  final VoidCallback onClose;

  const StoryViewer({
    Key? key,
    required this.story,
    required this.onClose,
  }) : super(key: key);

  @override
  _StoryViewerState createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  bool _isAuthorized = false;
  bool _isLocationAuthorized = false;
  bool _isLoading = true;
  bool _showSOSMessage = false;
  int _tapCount = 0;
  String _errorMessage = '';
  
  late AnimationController _progressController;
  Location _location = Location();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
      if (_progressController.value >= 1.0) {
        widget.onClose();
      }
    });
    
    _checkAccessRestrictions();
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _checkAccessRestrictions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Check biometric authentication if required
    if (widget.story.requireBiometric) {
      final authenticated = await _authenticateWithBiometrics();
      if (!authenticated) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Biometric authentication required';
        });
        return;
      }
    }

    // Check geo-fence if required
    if (widget.story.geoFence != null) {
      final locationAuthorized = await _checkLocation();
      if (!locationAuthorized) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location not authorized or outside geo-fence';
        });
        return;
      }
    }

    // Mark the story as viewed
    if (_errorMessage.isEmpty) {
      Provider.of<StoryService>(context, listen: false)
          .markStoryAsViewed(widget.story.id);
      
      setState(() {
        _isAuthorized = true;
        _isLoading = false;
      });
      
      _progressController.forward();
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    final localAuth = LocalAuthentication();
    try {
      return await localAuth.authenticate(
        localizedReason: 'Authenticate to view this private story',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return false;
        }
      }

      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != PermissionStatus.granted) {
          return false;
        }
      }

      // If we have a geo-fence, check if we're within the allowed radius
      if (widget.story.geoFence != null) {
        final currentLocation = await _location.getLocation();
        
        final double distance = _calculateDistance(
          currentLocation.latitude!,
          currentLocation.longitude!,
          widget.story.geoFence!.latitude,
          widget.story.geoFence!.longitude,
        );
        
        if (distance > widget.story.geoFence!.radius) {
          return false;
        }
      }

      setState(() {
        _isLocationAuthorized = true;
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Haversine formula to calculate distance between two points
  double _calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        (1 - Math.cos(dLat)) / 2 +
        Math.cos(_toRadians(lat1)) * Math.cos(_toRadians(lat2)) * (1 - Math.cos(dLon)) / 2;
    
    final double distance = earthRadius * 2 * Math.asin(Math.sqrt(a));
    return distance;
  }

  double _toRadians(double degrees) {
    return degrees * Math.pi / 180;
  }

  void _handleTripleTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 3 && widget.story.isCrisisMode) {
        _showSOSMessage = true;
      }
    });
    
    // Reset tap count after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _tapCount = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _errorMessage.contains('Biometric') 
                      ? Icons.fingerprint 
                      : Icons.location_off,
                  color: Colors.red.withOpacity(0.8),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _checkAccessRestrictions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('TRY AGAIN'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTripleTap,
      child: Stack(
        children: [
          // Story content
          Positioned.fill(
            child: _buildStoryContent(),
          ),
          
          // Progress bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progressController.value,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getEmotionColor(widget.story.emotionFilter),
              ),
            ),
          ),
          
          // Caption
          if (widget.story.caption != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GlassCard(
                blur: 5,
                opacity: 0.2,
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.story.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // SOS message for crisis mode stories
          if (_showSOSMessage && widget.story.sosMessage != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'SOS MESSAGE',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.story.sosMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showSOSMessage = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('CLOSE'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Location and biometric indicators
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.story.requireBiometric)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fingerprint,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Secured',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.story.requireBiometric && widget.story.geoFence != null)
                  const SizedBox(width: 8),
                if (widget.story.geoFence != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Geo-fenced',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Crisis mode indicator
          if (widget.story.isCrisisMode && !_showSOSMessage)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Crisis Mode',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Close button
          Positioned(
            top: 24,
            right: 16,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    if (widget.story.mediaType == StoryMediaType.image) {
      return Image.file(
        File(widget.story.mediaPath),
        fit: BoxFit.cover,
      );
    } else if (widget.story.mediaType == StoryMediaType.video) {
      // In a real app, you would use a video player here
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.video_library,
            color: Colors.white,
            size: 64,
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'Unsupported media type',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      );
    }
  }

  Color _getEmotionColor(EmotionFilter? filter) {
    switch (filter) {
      case EmotionFilter.joy:
        return Colors.amber;
      case EmotionFilter.sadness:
        return Colors.blue;
      case EmotionFilter.fear:
        return Colors.deepPurple;
      case EmotionFilter.anger:
        return Colors.red;
      case EmotionFilter.surprise:
        return Colors.orange;
      case EmotionFilter.disgust:
        return Colors.green;
      case EmotionFilter.love:
        return Colors.pink;
      case EmotionFilter.hope:
        return Colors.teal;
      case EmotionFilter.pride:
        return Colors.deepOrange;
      default:
        return Colors.purpleAccent;
    }
  }
}

// Adding Math utility class because dart:math doesn't have all these functions
class Math {
  static const double pi = 3.1415926535897932;
  
  static double cos(double x) {
    return math.cos(x);
  }
  
  static double asin(double x) {
    return math.asin(x);
  }
  
  static double sqrt(double x) {
    return math.sqrt(x);
  }
} 