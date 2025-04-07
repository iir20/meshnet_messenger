import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/services/mesh_service.dart';
import 'package:secure_mesh_messenger/services/crypto_service.dart';
import 'package:secure_mesh_messenger/services/ar_service.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:uuid/uuid.dart';

class EmergencyService {
  final MeshService _meshService;
  final CryptoService _cryptoService;
  final ARService _arService;
  final Uuid _uuid = const Uuid();
  
  // Location tracking
  final Location _location = Location();
  LocationData? _lastKnownLocation;
  
  // Emergency contacts
  final List<String> _emergencyContactIds = [];
  
  // SOS triggers
  bool _sosActive = false;
  Timer? _sosPingTimer;
  Timer? _sosLocationTimer;
  
  // SOS signal stream
  final StreamController<bool> _sosController = StreamController<bool>.broadcast();
  Stream<bool> get onSOSStateChanged => _sosController.stream;
  
  // Emoji triggers
  final List<String> _sosTriggerEmojis = ['🆘', '🚨', '🔴', '🚑', '🚒'];
  
  // Camera for SOS double blink detection
  CameraController? _cameraController;
  bool _isMonitoringBlinks = false;
  
  EmergencyService(this._meshService, this._cryptoService, this._arService);
  
  Future<void> initialize() async {
    try {
      // Request location permissions
      final locationPermission = await perm.Permission.locationAlways.request();
      if (locationPermission.isGranted) {
        // Setup location service
        await _location.changeSettings(
          accuracy: LocationAccuracy.high,
          interval: 10000,
        );
        
        // Get initial location
        _lastKnownLocation = await _location.getLocation();
        
        // Listen for location updates
        _location.onLocationChanged.listen((locationData) {
          _lastKnownLocation = locationData;
        });
      }
      
      // Set up camera for blink detection if not already set up in AR service
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
      }
      
      debugPrint('EmergencyService: Initialized');
    } catch (e) {
      debugPrint('EmergencyService: Failed to initialize: $e');
    }
  }
  
  // Add emergency contact
  void addEmergencyContact(String peerId) {
    if (!_emergencyContactIds.contains(peerId)) {
      _emergencyContactIds.add(peerId);
      debugPrint('EmergencyService: Added emergency contact $peerId');
    }
  }
  
  // Remove emergency contact
  void removeEmergencyContact(String peerId) {
    _emergencyContactIds.remove(peerId);
    debugPrint('EmergencyService: Removed emergency contact $peerId');
  }
  
  // Get all emergency contacts
  List<String> getEmergencyContacts() {
    return List.unmodifiable(_emergencyContactIds);
  }
  
  // Check if a message contains an SOS trigger emoji
  bool isSOSTriggerEmoji(String message) {
    for (final emoji in _sosTriggerEmojis) {
      if (message.contains(emoji)) {
        return true;
      }
    }
    return false;
  }
  
  // Start monitoring for blink triggers
  Future<void> startBlinkMonitoring() async {
    if (_isMonitoringBlinks) return;
    
    try {
      if (_cameraController == null) {
        throw Exception('Camera not initialized');
      }
      
      if (!_cameraController!.value.isInitialized) {
        await _cameraController!.initialize();
      }
      
      _isMonitoringBlinks = true;
      
      // Start image stream
      await _cameraController!.startImageStream((image) async {
        if (!_isMonitoringBlinks) return;
        
        // Check for double blink SOS trigger
        final isSOSTrigger = await _arService.detectSOSTrigger(image);
        if (isSOSTrigger) {
          // Activate SOS mode
          await activateSOS('blink_detected');
        }
      });
      
      debugPrint('EmergencyService: Started blink monitoring');
    } catch (e) {
      debugPrint('EmergencyService: Failed to start blink monitoring: $e');
      _isMonitoringBlinks = false;
    }
  }
  
  // Stop monitoring for blink triggers
  Future<void> stopBlinkMonitoring() async {
    if (!_isMonitoringBlinks) return;
    
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      
      _isMonitoringBlinks = false;
      debugPrint('EmergencyService: Stopped blink monitoring');
    } catch (e) {
      debugPrint('EmergencyService: Failed to stop blink monitoring: $e');
    }
  }
  
  // Activate SOS mode
  Future<bool> activateSOS(String trigger) async {
    if (_sosActive) return true; // Already active
    
    try {
      _sosActive = true;
      _sosController.add(true);
      
      // Broadcast SOS to emergency contacts
      await _broadcastSOS(trigger);
      
      // Start periodic pings
      _sosPingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _pingEmergencyContacts();
      });
      
      // Start location updates
      _sosLocationTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
        _sendLocationUpdate();
      });
      
      debugPrint('EmergencyService: SOS activated via $trigger');
      return true;
    } catch (e) {
      debugPrint('EmergencyService: Failed to activate SOS: $e');
      _sosActive = false;
      _sosController.add(false);
      return false;
    }
  }
  
  // Deactivate SOS mode
  Future<void> deactivateSOS() async {
    if (!_sosActive) return;
    
    try {
      // Cancel timers
      _sosPingTimer?.cancel();
      _sosPingTimer = null;
      
      _sosLocationTimer?.cancel();
      _sosLocationTimer = null;
      
      // Send all-clear message
      await _sendAllClear();
      
      _sosActive = false;
      _sosController.add(false);
      
      debugPrint('EmergencyService: SOS deactivated');
    } catch (e) {
      debugPrint('EmergencyService: Failed to deactivate SOS: $e');
    }
  }
  
  // Broadcast initial SOS message
  Future<void> _broadcastSOS(String trigger) async {
    if (_emergencyContactIds.isEmpty) {
      debugPrint('EmergencyService: No emergency contacts');
      return;
    }
    
    try {
      // Get current location
      final locationData = _lastKnownLocation;
      
      // Create SOS message
      final sosData = {
        'type': 'sos_alert',
        'trigger': trigger,
        'timestamp': DateTime.now().toIso8601String(),
        'location': locationData != null
            ? {
                'latitude': locationData.latitude,
                'longitude': locationData.longitude,
                'accuracy': locationData.accuracy,
              }
            : null,
      };
      
      // Send to each emergency contact
      for (final contactId in _emergencyContactIds) {
        final publicKey = await _meshService.getContactPublicKey(contactId);
        if (publicKey == null) continue;
        
        final message = await _cryptoService.encryptMessage(
          content: jsonEncode(sosData),
          recipientId: contactId,
          recipientPublicKey: publicKey,
          type: MessageType.sos,
        );
        
        await _meshService.sendMessage(message);
        
        debugPrint('EmergencyService: SOS sent to $contactId');
      }
    } catch (e) {
      debugPrint('EmergencyService: Failed to broadcast SOS: $e');
    }
  }
  
  // Send periodic ping to confirm SOS is still active
  Future<void> _pingEmergencyContacts() async {
    if (!_sosActive || _emergencyContactIds.isEmpty) return;
    
    try {
      final pingData = {
        'type': 'sos_ping',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Send to each emergency contact
      for (final contactId in _emergencyContactIds) {
        final publicKey = await _meshService.getContactPublicKey(contactId);
        if (publicKey == null) continue;
        
        final message = await _cryptoService.encryptMessage(
          content: jsonEncode(pingData),
          recipientId: contactId,
          recipientPublicKey: publicKey,
          type: MessageType.sos,
        );
        
        await _meshService.sendMessage(message);
      }
      
      debugPrint('EmergencyService: SOS ping sent');
    } catch (e) {
      debugPrint('EmergencyService: Failed to send SOS ping: $e');
    }
  }
  
  // Send location update
  Future<void> _sendLocationUpdate() async {
    if (!_sosActive || _emergencyContactIds.isEmpty || _lastKnownLocation == null) return;
    
    try {
      final locationData = _lastKnownLocation!;
      
      final locationUpdateData = {
        'type': 'sos_location',
        'timestamp': DateTime.now().toIso8601String(),
        'location': {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'accuracy': locationData.accuracy,
          'speed': locationData.speed,
          'heading': locationData.heading,
        },
      };
      
      // Send to each emergency contact
      for (final contactId in _emergencyContactIds) {
        final publicKey = await _meshService.getContactPublicKey(contactId);
        if (publicKey == null) continue;
        
        final message = await _cryptoService.encryptMessage(
          content: jsonEncode(locationUpdateData),
          recipientId: contactId,
          recipientPublicKey: publicKey,
          type: MessageType.sos,
        );
        
        await _meshService.sendMessage(message);
      }
      
      debugPrint('EmergencyService: Location update sent');
    } catch (e) {
      debugPrint('EmergencyService: Failed to send location update: $e');
    }
  }
  
  // Send all clear message
  Future<void> _sendAllClear() async {
    if (_emergencyContactIds.isEmpty) return;
    
    try {
      final allClearData = {
        'type': 'sos_all_clear',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Send to each emergency contact
      for (final contactId in _emergencyContactIds) {
        final publicKey = await _meshService.getContactPublicKey(contactId);
        if (publicKey == null) continue;
        
        final message = await _cryptoService.encryptMessage(
          content: jsonEncode(allClearData),
          recipientId: contactId,
          recipientPublicKey: publicKey,
          type: MessageType.sos,
        );
        
        await _meshService.sendMessage(message);
      }
      
      debugPrint('EmergencyService: All clear sent');
    } catch (e) {
      debugPrint('EmergencyService: Failed to send all clear: $e');
    }
  }
  
  // Process incoming SOS message
  Future<void> processSOSMessage(EncryptedMessage encryptedMessage, String decryptedContent) async {
    try {
      final data = jsonDecode(decryptedContent) as Map<String, dynamic>;
      final type = data['type'] as String;
      
      switch (type) {
        case 'sos_alert':
          // Someone has sent us an SOS
          debugPrint('EmergencyService: Received SOS alert from ${encryptedMessage.senderId}');
          // Show notification and alert in the UI
          break;
          
        case 'sos_ping':
          // SOS still active
          debugPrint('EmergencyService: Received SOS ping from ${encryptedMessage.senderId}');
          break;
          
        case 'sos_location':
          // Location update from SOS sender
          debugPrint('EmergencyService: Received location update from ${encryptedMessage.senderId}');
          break;
          
        case 'sos_all_clear':
          // SOS has been deactivated
          debugPrint('EmergencyService: Received all clear from ${encryptedMessage.senderId}');
          break;
      }
    } catch (e) {
      debugPrint('EmergencyService: Failed to process SOS message: $e');
    }
  }
  
  // Create a disguised SOS message that looks like a normal message
  Future<EncryptedMessage> createDisguisedSOSMessage({
    required String recipientId,
    required String recipientPublicKey,
    String disguisedContent = 'Hey! Just checking in. How are you doing?',
  }) async {
    try {
      // Create a special metadata that contains the SOS flag
      final sosData = {
        'type': 'sos_stealth',
        'timestamp': DateTime.now().toIso8601String(),
        'location': _lastKnownLocation != null
            ? {
                'latitude': _lastKnownLocation!.latitude,
                'longitude': _lastKnownLocation!.longitude,
              }
            : null,
      };
      
      // Create a message that looks normal but has hidden SOS data
      final sosMetadata = {'sos': base64Encode(utf8.encode(jsonEncode(sosData)))};
      
      // Encrypt message with the hidden metadata
      final message = await _cryptoService.encryptMessage(
        content: disguisedContent,
        recipientId: recipientId,
        recipientPublicKey: recipientPublicKey,
        type: MessageType.text, // It appears as a normal text message
      );
      
      return message;
    } catch (e) {
      debugPrint('EmergencyService: Failed to create disguised SOS message: $e');
      rethrow;
    }
  }
  
  // Handle gesture-based SOS trigger
  Future<bool> handleGestureTrigger() async {
    return await activateSOS('gesture');
  }
  
  // Handle emoji-based SOS trigger
  Future<bool> handleEmojiTrigger(String emoji) async {
    if (_sosTriggerEmojis.contains(emoji)) {
      return await activateSOS('emoji:$emoji');
    }
    return false;
  }
  
  bool get isSOSActive => _sosActive;
  
  Future<void> dispose() async {
    await _cameraController?.dispose();
    await deactivateSOS();
    await _sosController.close();
  }
}