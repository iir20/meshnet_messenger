import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:secure_mesh_messenger/services/crypto_service.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

class ARService {
  final CryptoService _cryptoService;
  final Uuid _uuid = const Uuid();
  
  // Camera controller for AR and face masking
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  // AR controllers
  ArCoreController? _arCoreController;
  
  // Face detection
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  
  // Emotion detection
  final StreamController<String> _emotionController = StreamController<String>.broadcast();
  Stream<String> get onEmotionDetected => _emotionController.stream;
  
  // AR message events
  final StreamController<String> _arMessageController = StreamController<String>.broadcast();
  Stream<String> get onARMessageReceived => _arMessageController.stream;
  
  // Face mask filters
  final List<String> _availableMasks = [
    'anonymous',
    'robot',
    'animal',
    'superhero',
    'emoji',
  ];
  String _currentMask = 'none';
  
  // Stream controllers for various AR states
  final _arReadyController = StreamController<bool>.broadcast();
  final _recordingTimeController = StreamController<int>.broadcast();
  final _isRecordingController = StreamController<bool>.broadcast();
  final _emotionDetectedController = StreamController<String?>.broadcast();
  
  // Getters for streams
  Stream<bool> get arReadyStream => _arReadyController.stream;
  Stream<int> get recordingTimeStream => _recordingTimeController.stream;
  Stream<bool> get isRecordingStream => _isRecordingController.stream;
  Stream<String?> get emotionDetectedStream => _emotionDetectedController.stream;
  
  // Current values
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  String? get videoPath => _videoPath;
  int get recordingTimeInSeconds => _recordingTimeInSeconds;
  
  bool _isInitialized = false;
  bool _isRecording = false;
  String? _videoPath;
  Timer? _recordingTimer;
  int _recordingTimeInSeconds = 0;
  
  ARService(this._cryptoService);
  
  Future<bool> initialize() async {
    try {
      // Initialize cameras
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Select front camera for face masking
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        
        // Initialize camera
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: true,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        
        await _cameraController!.initialize();
      }
      
      _isInitialized = true;
      _arReadyController.add(true);
      
      // Set up face detection if supported
      if (enableEmotionDetection) {
        // Start face detection loop
        _startEmotionDetection();
      }
      
      return true;
    } catch (e) {
      _isInitialized = false;
      _arReadyController.add(false);
      debugPrint('ARService: Failed to initialize: $e');
      return false;
    }
  }
  
  // Set AR core controller from the AR view
  void setArCoreController(ArCoreController controller) {
    _arCoreController = controller;
    _setupArCoreController();
  }
  
  void _setupArCoreController() {
    if (_arCoreController == null) return;
    
    _arCoreController!.onPlaneTap = _handlePlaneTap;
    _arCoreController!.onTrackingImage = _handleTrackingImage;
  }
  
  // Handle tap on AR plane - used to place AR messages
  void _handlePlaneTap(List<ArCoreHitTestResult> results) {
    if (results.isEmpty) return;
    
    final hit = results.first;
    _addSphere(hit);
  }
  
  // Handle image tracking - used for AR anchors
  void _handleTrackingImage(ArCoreAugmentedImage augmentedImage) {
    debugPrint('ARService: Tracked image: ${augmentedImage.name}');
    // Handle tracked image
  }
  
  // Add a 3D sphere at a hit position (placeholder for AR hologram)
  void _addSphere(ArCoreHitTestResult hit) {
    if (_arCoreController == null) return;
    
    final material = ArCoreMaterial(
      color: Color.fromARGB(120, 66, 134, 244),
      reflectance: 1.0,
    );
    
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 0.1,
    );
    
    final node = ArCoreNode(
      shape: sphere,
      position: hit.pose.translation,
      rotation: hit.pose.rotation,
    );
    
    _arCoreController!.addArCoreNode(node);
  }
  
  // Create an AR hologram message
  Future<String> createARMessage({
    required Uint8List videoData,
    required String recipientId,
    bool applyFaceMask = false,
    String maskType = 'none',
  }) async {
    try {
      final messageId = _uuid.v4();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/ar_message_$messageId.mp4';
      
      // Save original video
      final videoFile = File(filePath);
      await videoFile.writeAsBytes(videoData);
      
      // Apply face mask if needed
      if (applyFaceMask) {
        await _applyFaceMaskToVideo(filePath, maskType);
      }
      
      // Encrypt the file for the recipient
      final encryptedData = await _cryptoService.encryptFile(
        await videoFile.readAsBytes(),
        recipientId,
      );
      
      // Save encrypted file
      final encryptedFilePath = '${tempDir.path}/encrypted_ar_$messageId.bin';
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(encryptedData);
      
      // Delete original file
      await videoFile.delete();
      
      return encryptedFilePath;
    } catch (e) {
      debugPrint('ARService: Failed to create AR message: $e');
      rethrow;
    }
  }
  
  // Apply face mask to video (placeholder implementation)
  Future<void> _applyFaceMaskToVideo(String videoPath, String maskType) async {
    // In a real implementation, this would process the video frame by frame,
    // detect faces, and apply the selected mask
    debugPrint('ARService: Applying mask $maskType to video $videoPath');
    
    // Placeholder for face masking implementation
  }
  
  // Set current face mask for live video
  void setFaceMask(String maskType) {
    if (!_availableMasks.contains(maskType) && maskType != 'none') {
      throw Exception('Invalid mask type: $maskType');
    }
    _currentMask = maskType;
    debugPrint('ARService: Face mask set to $maskType');
  }
  
  // Get available face masks
  List<String> getAvailableMasks() {
    return ['none', ..._availableMasks];
  }
  
  // Start emotion detection
  void _startEmotionDetection() {
    // In a real app, this would use a machine learning model to detect emotions
    // For this demo, we'll simulate emotion detection
    
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isInitialized || _cameraController == null) {
        timer.cancel();
        return;
      }
      
      // Simulate detecting a random emotion
      final emotions = ['happy', 'sad', 'neutral', 'surprised', null];
      final randomEmotion = emotions[DateTime.now().second % emotions.length];
      
      _emotionDetectedController.add(randomEmotion);
    });
  }
  
  // Stop emotion detection
  Future<void> stopEmotionDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    await _cameraController!.stopImageStream();
  }
  
  // Detect emotion from camera image
  Future<String> _detectEmotion(CameraImage image) async {
    // This is a placeholder for emotion detection
    // In a real implementation, this would use ML to analyze facial expressions
    final faces = await _processCameraImage(image);
    if (faces.isEmpty) return '';
    
    final face = faces.first;
    
    if (face.smilingProbability != null && face.smilingProbability! > 0.8) {
      return 'happy';
    } else if (face.leftEyeOpenProbability != null && 
               face.rightEyeOpenProbability != null &&
               face.leftEyeOpenProbability! < 0.3 && 
               face.rightEyeOpenProbability! < 0.3) {
      return 'angry';
    }
    
    return '';
  }
  
  // Process camera image for face detection
  Future<List<Face>> _processCameraImage(CameraImage image) async {
    final inputImage = InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      inputImageData: InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: InputImageRotation.rotation0deg,
        inputImageFormat: InputImageFormat.nv21,
        planeData: image.planes.map((plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: image.height,
            width: image.width,
          );
        }).toList(),
      ),
    );
    
    return await _faceDetector.processImage(inputImage);
  }
  
  // Helper function to convert camera image format
  Uint8List _concatenatePlanes(List<CameraImagePlane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
  
  // Detect SOS trigger from facial expressions
  Future<bool> detectSOSTrigger(CameraImage image) async {
    final faces = await _processCameraImage(image);
    if (faces.isEmpty) return false;
    
    final face = faces.first;
    
    // Check for double blink (eyes open, then closed, then open again in rapid succession)
    if (face.leftEyeOpenProbability != null && 
        face.rightEyeOpenProbability != null &&
        face.leftEyeOpenProbability! < 0.2 && 
        face.rightEyeOpenProbability! < 0.2) {
      // This is a simplified check, in a real app we'd track the blink sequence
      return true;
    }
    
    return false;
  }
  
  // Display AR message
  Future<void> displayARMessage(String filePath) async {
    if (_arCoreController == null) {
      throw Exception('AR controller not initialized');
    }
    
    try {
      // Decrypt AR message
      final encryptedFile = File(filePath);
      final encryptedData = await encryptedFile.readAsBytes();
      final decryptedData = await _cryptoService.decryptFile(encryptedData);
      
      // Save decrypted file
      final tempDir = await getTemporaryDirectory();
      final decryptedFilePath = '${tempDir.path}/decrypted_ar_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final decryptedFile = File(decryptedFilePath);
      await decryptedFile.writeAsBytes(decryptedData);
      
      // Display AR content
      // In a real app, this would render the video as a 3D hologram in AR
      debugPrint('ARService: Displaying AR message: $decryptedFilePath');
      
      // Notify AR message received
      _arMessageController.add(decryptedFilePath);
    } catch (e) {
      debugPrint('ARService: Failed to display AR message: $e');
      rethrow;
    }
  }
  
  Future<void> dispose() async {
    await _cameraController?.dispose();
    await _faceDetector.close();
    _arCoreController?.dispose();
    await _emotionController.close();
    await _arMessageController.close();
    
    await _stopRecording();
    
    _recordingTimer?.cancel();
    
    _isInitialized = false;
    
    await _arReadyController.close();
    await _recordingTimeController.close();
    await _isRecordingController.close();
    await _emotionDetectedController.close();
  }
  
  // Get the camera preview widget
  Widget getCameraPreview() {
    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CameraPreview(_cameraController!),
    );
  }
  
  // Start recording a video
  Future<bool> startRecording() async {
    if (!_isInitialized || _cameraController == null || _isRecording) {
      return false;
    }
    
    try {
      await _cameraController!.startVideoRecording();
      _isRecording = true;
      _recordingTimeInSeconds = 0;
      _isRecordingController.add(true);
      
      // Start a timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingTimeInSeconds++;
        _recordingTimeController.add(_recordingTimeInSeconds);
        
        // Stop recording if it exceeds maximum duration
        if (_recordingTimeInSeconds >= maxARVideoDuration) {
          _stopRecording();
        }
      });
      
      return true;
    } catch (e) {
      _isRecording = false;
      _isRecordingController.add(false);
      print('Failed to start recording: $e');
      return false;
    }
  }
  
  // Stop recording a video
  Future<String?> stopRecording() async {
    return await _stopRecording();
  }
  
  // Internal method to stop recording
  Future<String?> _stopRecording() async {
    if (!_isRecording || _cameraController == null) {
      return null;
    }
    
    try {
      _recordingTimer?.cancel();
      
      final videoFile = await _cameraController!.stopVideoRecording();
      _videoPath = videoFile.path;
      
      _isRecording = false;
      _isRecordingController.add(false);
      
      return _videoPath;
    } catch (e) {
      _isRecording = false;
      _isRecordingController.add(false);
      print('Failed to stop recording: $e');
      return null;
    }
  }
  
  // Take a photo
  Future<String?> takePhoto() async {
    if (!_isInitialized || _cameraController == null) {
      return null;
    }
    
    try {
      final XFile photo = await _cameraController!.takePicture();
      return photo.path;
    } catch (e) {
      print('Failed to take photo: $e');
      return null;
    }
  }
  
  // Apply an AR effect to the camera stream
  Future<bool> applyAREffect(String effectId) async {
    if (!_isInitialized || _cameraController == null) {
      return false;
    }
    
    // In a real implementation, this would apply the actual effect
    // For this demo, we just simulate applying an effect
    print('Applied AR effect: $effectId');
    return true;
  }
  
  // Remove AR effects
  Future<bool> removeAREffects() async {
    if (!_isInitialized || _cameraController == null) {
      return false;
    }
    
    // In a real implementation, this would remove all effects
    print('Removed all AR effects');
    return true;
  }
  
  // Save the current AR state as a message
  Future<Map<String, dynamic>?> saveARMessage(String effectId, {String? caption}) async {
    if (!_isInitialized || _videoPath == null) {
      return null;
    }
    
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(_videoPath!);
      
      // Save metadata
      final metadata = {
        'effectId': effectId,
        'duration': _recordingTimeInSeconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'caption': caption,
      };
      
      return {
        'videoPath': _videoPath!,
        'metadata': metadata,
      };
    } catch (e) {
      print('Failed to save AR message: $e');
      return null;
    }
  }
} 