import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../../services/story_service.dart';
import '../../widgets/glass_card.dart';

class StoryCreator extends StatefulWidget {
  final VoidCallback onStoryCreated;
  
  const StoryCreator({
    Key? key,
    required this.onStoryCreated,
  }) : super(key: key);

  @override
  _StoryCreatorState createState() => _StoryCreatorState();
}

class _StoryCreatorState extends State<StoryCreator> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _sosMessageController = TextEditingController();
  
  File? _mediaFile;
  StoryMediaType _mediaType = StoryMediaType.image;
  EmotionFilter _selectedFilter = EmotionFilter.none;
  bool _useGeoFence = false;
  bool _requireBiometric = false;
  bool _isCrisisMode = false;
  double _geoFenceRadius = 1000.0; // 1km default
  LocationData? _currentLocation;
  bool _isLoading = false;
  bool _supportsBiometrics = false;
  
  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    _sosMessageController.dispose();
    super.dispose();
  }
  
  // Check if the device supports biometrics
  Future<void> _checkBiometricSupport() async {
    final storyService = Provider.of<StoryService>(context, listen: false);
    final supportsBiometrics = await storyService.supportsBiometrics;
    
    setState(() {
      _supportsBiometrics = supportsBiometrics;
    });
  }
  
  // Get current location for geo-fencing
  Future<void> _getCurrentLocation() async {
    try {
      final location = Location();
      final locationData = await location.getLocation();
      
      setState(() {
        _currentLocation = locationData;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }
  
  // Pick image from gallery or camera
  Future<void> _pickMedia(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile.path);
          _mediaType = StoryMediaType.image;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking media: $e');
    }
  }
  
  // Create the story
  Future<void> _createStory() async {
    if (_mediaFile == null) {
      _showErrorSnackBar('Please select an image or video');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storyService = Provider.of<StoryService>(context, listen: false);
      
      // Create geo-fence if enabled
      GeoFence? geoFence;
      if (_useGeoFence && _currentLocation != null) {
        geoFence = GeoFence(
          latitude: _currentLocation!.latitude!,
          longitude: _currentLocation!.longitude!,
          radius: _geoFenceRadius,
        );
      }
      
      // Create the story
      await storyService.createStory(
        mediaFile: _mediaFile!,
        mediaType: _mediaType,
        caption: _captionController.text.isNotEmpty ? _captionController.text : null,
        emotionFilter: _selectedFilter != EmotionFilter.none ? _selectedFilter : null,
        geoFence: geoFence,
        requireBiometric: _requireBiometric,
        isCrisisMode: _isCrisisMode,
        hiddenSOSMessage: _isCrisisMode && _sosMessageController.text.isNotEmpty
            ? _sosMessageController.text
            : null,
      );
      
      // Reset the form
      setState(() {
        _mediaFile = null;
        _captionController.clear();
        _sosMessageController.clear();
        _selectedFilter = EmotionFilter.none;
        _useGeoFence = false;
        _requireBiometric = false;
        _isCrisisMode = false;
      });
      
      // Notify parent that a story was created
      widget.onStoryCreated();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error creating story: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(24),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'CREATE STORY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          
          // Media selection
          _mediaFile == null
              ? _buildMediaSelector()
              : _buildMediaPreview(),
          
          const SizedBox(height: 16),
          
          // Caption input
          TextField(
            controller: _captionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.purpleAccent,
                  width: 1.5,
                ),
              ),
            ),
            maxLines: 3,
            maxLength: 150,
          ),
          
          const SizedBox(height: 16),
          
          // Emotion filters
          _buildEmotionFilterSelector(),
          
          const SizedBox(height: 16),
          
          // Security options
          _buildSecurityOptions(),
          
          const SizedBox(height: 16),
          
          // Crisis mode
          if (_isCrisisMode) _buildCrisisModeOptions(),
          
          const SizedBox(height: 24),
          
          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _mediaFile == null ? null : _createStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Colors.purpleAccent,
                    width: 1.5,
                  ),
                ),
                disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                disabledForegroundColor: Colors.grey,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'CREATE STORY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMediaSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pickMedia(ImageSource.gallery),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.3),
                  width: 1,
                  style: BorderStyle.dashed,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library,
                    color: Colors.purpleAccent.withOpacity(0.7),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GALLERY',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _pickMedia(ImageSource.camera),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.3),
                  width: 1,
                  style: BorderStyle.dashed,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: Colors.purpleAccent.withOpacity(0.7),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CAMERA',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMediaPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _mediaFile!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () {
              setState(() {
                _mediaFile = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmotionFilterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMOTION FILTER',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterOption(EmotionFilter.none, 'None'),
              _buildFilterOption(EmotionFilter.joy, 'Joy'),
              _buildFilterOption(EmotionFilter.sadness, 'Sadness'),
              _buildFilterOption(EmotionFilter.fear, 'Fear'),
              _buildFilterOption(EmotionFilter.anger, 'Anger'),
              _buildFilterOption(EmotionFilter.surprise, 'Surprise'),
              _buildFilterOption(EmotionFilter.love, 'Love'),
              _buildFilterOption(EmotionFilter.hope, 'Hope'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterOption(EmotionFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    
    // Define color based on emotion
    Color filterColor;
    switch (filter) {
      case EmotionFilter.joy:
        filterColor = Colors.amber;
        break;
      case EmotionFilter.sadness:
        filterColor = Colors.blue;
        break;
      case EmotionFilter.fear:
        filterColor = Colors.deepPurple;
        break;
      case EmotionFilter.anger:
        filterColor = Colors.red;
        break;
      case EmotionFilter.surprise:
        filterColor = Colors.orange;
        break;
      case EmotionFilter.disgust:
        filterColor = Colors.green;
        break;
      case EmotionFilter.love:
        filterColor = Colors.pink;
        break;
      case EmotionFilter.hope:
        filterColor = Colors.teal;
        break;
      case EmotionFilter.pride:
        filterColor = Colors.deepOrange;
        break;
      default:
        filterColor = Colors.grey;
        break;
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? filterColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? filterColor : Colors.white.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? filterColor : Colors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSecurityOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SECURITY OPTIONS',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                title: const Text(
                  'Geo-fence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Limit to your location',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                value: _useGeoFence,
                onChanged: _currentLocation == null
                    ? null
                    : (value) {
                        setState(() {
                          _useGeoFence = value;
                        });
                      },
                activeColor: Colors.purpleAccent,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SwitchListTile(
                title: const Text(
                  'Biometric',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Require authentication',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                value: _requireBiometric,
                onChanged: !_supportsBiometrics
                    ? null
                    : (value) {
                        setState(() {
                          _requireBiometric = value;
                        });
                      },
                activeColor: Colors.purpleAccent,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_useGeoFence) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _geoFenceRadius,
                  min: 100,
                  max: 10000,
                  divisions: 99,
                  activeColor: Colors.purpleAccent,
                  inactiveColor: Colors.purpleAccent.withOpacity(0.3),
                  label: '${(_geoFenceRadius / 1000).toStringAsFixed(1)} km',
                  onChanged: (value) {
                    setState(() {
                      _geoFenceRadius = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${(_geoFenceRadius / 1000).toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text(
            'Crisis Mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Include hidden SOS message',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          value: _isCrisisMode,
          onChanged: (value) {
            setState(() {
              _isCrisisMode = value;
            });
          },
          activeColor: Colors.red,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
  
  Widget _buildCrisisModeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'SOS MESSAGE',
              style: TextStyle(
                color: Colors.red.withOpacity(0.9),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sosMessageController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter emergency SOS message...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.red.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Text(
          'This message will only be visible when the viewer performs a special gesture (triple tap).',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 