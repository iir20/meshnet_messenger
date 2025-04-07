import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling steganographic operations - hiding messages in images
class SteganographyService extends ChangeNotifier {
  // Constants for maximum message length and metadata size
  static const int _metadataSize = 16; // 16 bytes for metadata (12 bytes header + 4 bytes length)
  static const String _magicHeader = 'MSGNET_STEG_';  // 12 bytes header
  
  // Cache of steganographic images the user has created or received
  final Map<String, SteganographicMessage> _messageCache = {};
  
  // Getter for the message cache
  List<SteganographicMessage> get messages => _messageCache.values.toList();
  
  // Constructor
  SteganographyService() {
    _loadCache();
  }
  
  /// Hide a text message inside an image
  /// 
  /// Returns the path to the new image with the embedded message
  Future<String> hideMessage({
    required File originalImage, 
    required String message,
    required String password,
    String? recipientId,
    String? senderId,
  }) async {
    try {
      // Read and decode the image
      final List<int> imageBytes = await originalImage.readAsBytes();
      final img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Check if the image is large enough to hold the message
      final int maxMessageSize = (image.width * image.height * 3) ~/ 8 - _metadataSize;
      final List<int> messageBytes = utf8.encode(message);
      
      if (messageBytes.length > maxMessageSize) {
        throw Exception('Message too large for this image. Maximum size: $maxMessageSize bytes');
      }
      
      // Encrypt the message with the password
      final List<int> encryptedMessage = _encryptMessage(messageBytes, password);
      
      // Create metadata: magic header + message length
      final ByteData metadata = ByteData(_metadataSize);
      for (int i = 0; i < _magicHeader.length; i++) {
        metadata.setUint8(i, _magicHeader.codeUnitAt(i));
      }
      metadata.setUint32(_magicHeader.length, encryptedMessage.length);
      
      // Convert metadata to bit array
      final List<bool> metadataBits = _bytesToBits(metadata.buffer.asUint8List());
      
      // Convert encrypted message to bit array
      final List<bool> messageBits = _bytesToBits(Uint8List.fromList(encryptedMessage));
      
      // Combine metadata and message bits
      final List<bool> allBits = [...metadataBits, ...messageBits];
      
      // Embed bits into image
      final img.Image stegoImage = _embedBitsInImage(image, allBits);
      
      // Save the steganographic image
      final String outputPath = await _saveStegoImage(stegoImage, originalImage.path);
      
      // Create and cache the steganographic message
      final SteganographicMessage stegoMessage = SteganographicMessage(
        id: _generateId(),
        imagePath: outputPath,
        createdAt: DateTime.now(),
        senderId: senderId,
        recipientId: recipientId,
        isEncrypted: true,
        originalImagePath: originalImage.path,
      );
      
      _messageCache[stegoMessage.id] = stegoMessage;
      _saveCache();
      notifyListeners();
      
      return outputPath;
    } catch (e) {
      debugPrint('Error hiding message: $e');
      rethrow;
    }
  }
  
  /// Extract and decrypt a hidden message from an image
  Future<String> extractMessage({
    required String imagePath,
    required String password,
  }) async {
    try {
      // Read and decode the image
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Extract the first 16 bytes as metadata
      final List<bool> metadataBits = _extractBitsFromImage(image, 0, _metadataSize * 8);
      final Uint8List metadataBytes = _bitsToBytes(metadataBits);
      
      // Check the magic header
      final ByteData metadata = ByteData.view(metadataBytes.buffer);
      final String header = String.fromCharCodes(metadataBytes.sublist(0, _magicHeader.length));
      
      if (header != _magicHeader) {
        throw Exception('No hidden message found in this image');
      }
      
      // Extract message length from metadata
      final int messageLength = metadata.getUint32(_magicHeader.length);
      
      // Extract the encrypted message bits
      final List<bool> encryptedMessageBits = _extractBitsFromImage(
        image, 
        _metadataSize * 8, 
        messageLength * 8
      );
      
      // Convert bits back to bytes
      final Uint8List encryptedMessageBytes = _bitsToBytes(encryptedMessageBits);
      
      // Decrypt the message
      final List<int> decryptedBytes = _decryptMessage(
        encryptedMessageBytes.toList(), 
        password
      );
      
      // Convert bytes to string
      final String decryptedMessage = utf8.decode(decryptedBytes);
      
      // Update the cache if this is a new message
      final String messageId = _generateIdFromPath(imagePath);
      if (!_messageCache.containsKey(messageId)) {
        final SteganographicMessage stegoMessage = SteganographicMessage(
          id: messageId,
          imagePath: imagePath,
          createdAt: DateTime.now(),
          isEncrypted: false, // Now decrypted
          originalImagePath: null,
        );
        
        _messageCache[messageId] = stegoMessage;
        _saveCache();
        notifyListeners();
      } else {
        // Update the existing message to mark as decrypted
        _messageCache[messageId] = _messageCache[messageId]!.copyWith(isEncrypted: false);
        _saveCache();
        notifyListeners();
      }
      
      return decryptedMessage;
    } catch (e) {
      debugPrint('Error extracting message: $e');
      rethrow;
    }
  }
  
  /// Check if an image contains a steganographic message
  Future<bool> containsHiddenMessage(String imagePath) async {
    try {
      // Read and decode the image
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));
      
      if (image == null) {
        return false;
      }
      
      // Extract the first 12 bytes to check header
      final List<bool> headerBits = _extractBitsFromImage(image, 0, _magicHeader.length * 8);
      final Uint8List headerBytes = _bitsToBytes(headerBits);
      final String header = String.fromCharCodes(headerBytes);
      
      return header == _magicHeader;
    } catch (e) {
      debugPrint('Error checking for hidden message: $e');
      return false;
    }
  }
  
  /// Delete a steganographic message from cache
  void deleteMessage(String messageId) {
    if (_messageCache.containsKey(messageId)) {
      _messageCache.remove(messageId);
      _saveCache();
      notifyListeners();
    }
  }
  
  /// Convert bytes to a list of bits
  List<bool> _bytesToBits(Uint8List bytes) {
    final List<bool> bits = [];
    
    for (final byte in bytes) {
      for (int i = 7; i >= 0; i--) {
        bits.add(((byte >> i) & 1) == 1);
      }
    }
    
    return bits;
  }
  
  /// Convert a list of bits back to bytes
  Uint8List _bitsToBytes(List<bool> bits) {
    final int byteCount = (bits.length + 7) ~/ 8;
    final Uint8List bytes = Uint8List(byteCount);
    
    for (int i = 0; i < byteCount; i++) {
      int byte = 0;
      for (int j = 0; j < 8 && (i * 8 + j) < bits.length; j++) {
        if (bits[i * 8 + j]) {
          byte |= (1 << (7 - j));
        }
      }
      bytes[i] = byte;
    }
    
    return bytes;
  }
  
  /// Encrypt a message using the password
  List<int> _encryptMessage(List<int> message, String password) {
    // Generate key from password
    final List<int> passwordBytes = utf8.encode(password);
    final Digest digest = sha256.convert(passwordBytes);
    final List<int> key = digest.bytes;
    
    // Simple XOR encryption with key cycling
    final List<int> encrypted = [];
    for (int i = 0; i < message.length; i++) {
      encrypted.add(message[i] ^ key[i % key.length]);
    }
    
    return encrypted;
  }
  
  /// Decrypt a message using the password
  List<int> _decryptMessage(List<int> encrypted, String password) {
    // The same XOR operation decrypts the message
    return _encryptMessage(encrypted, password);
  }
  
  /// Embed bits into the least significant bits of image pixels
  img.Image _embedBitsInImage(img.Image image, List<bool> bits) {
    // Create a copy of the image to avoid modifying the original
    final img.Image outputImage = img.copyResize(image, width: image.width, height: image.height);
    
    int bitIndex = 0;
    
    // Slightly randomize starting position for added security
    final math.Random random = math.Random(42);
    int startIndex = random.nextInt(100);
    
    // We have 3 color channels (RGB) per pixel to hide data
    final int totalPixels = image.width * image.height;
    final int totalChannels = totalPixels * 3;
    
    for (int i = startIndex; i < totalChannels && bitIndex < bits.length; i++) {
      // Calculate pixel position and color channel
      final int pixelIndex = i ~/ 3;
      final int y = pixelIndex ~/ image.width;
      final int x = pixelIndex % image.width;
      final int channel = i % 3;
      
      // Get the pixel color
      final img.Pixel pixel = outputImage.getPixel(x, y);
      
      // Modify the least significant bit of the appropriate channel
      switch (channel) {
        case 0: // Red
          outputImage.setPixel(x, y, img.Pixel.fromRgba(
            (pixel.r & 0xFE) | (bits[bitIndex] ? 1 : 0),
            pixel.g,
            pixel.b,
            pixel.a
          ));
          break;
        case 1: // Green
          outputImage.setPixel(x, y, img.Pixel.fromRgba(
            pixel.r,
            (pixel.g & 0xFE) | (bits[bitIndex] ? 1 : 0),
            pixel.b,
            pixel.a
          ));
          break;
        case 2: // Blue
          outputImage.setPixel(x, y, img.Pixel.fromRgba(
            pixel.r,
            pixel.g,
            (pixel.b & 0xFE) | (bits[bitIndex] ? 1 : 0),
            pixel.a
          ));
          break;
      }
      
      bitIndex++;
    }
    
    return outputImage;
  }
  
  /// Extract bits from the least significant bits of image pixels
  List<bool> _extractBitsFromImage(img.Image image, int startBitIndex, int length) {
    final List<bool> bits = [];
    
    // Slightly randomize starting position for added security (must match embedding)
    final math.Random random = math.Random(42);
    int startIndex = random.nextInt(100);
    
    // We have 3 color channels (RGB) per pixel to hide data
    final int totalPixels = image.width * image.height;
    final int totalChannels = totalPixels * 3;
    
    // Calculate the actual starting bit index in the image
    int actualStartIndex = startIndex + startBitIndex;
    
    for (int i = 0; i < length; i++) {
      final int channelIndex = actualStartIndex + i;
      
      if (channelIndex >= totalChannels) {
        break;
      }
      
      // Calculate pixel position and color channel
      final int pixelIndex = channelIndex ~/ 3;
      final int y = pixelIndex ~/ image.width;
      final int x = pixelIndex % image.width;
      final int channel = channelIndex % 3;
      
      // Get the pixel color
      final img.Pixel pixel = image.getPixel(x, y);
      
      // Extract the least significant bit of the appropriate channel
      switch (channel) {
        case 0: // Red
          bits.add((pixel.r & 1) == 1);
          break;
        case 1: // Green
          bits.add((pixel.g & 1) == 1);
          break;
        case 2: // Blue
          bits.add((pixel.b & 1) == 1);
          break;
      }
    }
    
    return bits;
  }
  
  /// Save the steganographic image to the app's documents directory
  Future<String> _saveStegoImage(img.Image image, String originalPath) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String filename = 'stego_${_generateId()}.png';
    final String path = '${appDir.path}/$filename';
    
    final File outputFile = File(path);
    await outputFile.writeAsBytes(img.encodePng(image));
    
    return path;
  }
  
  /// Generate a unique ID for a steganographic message
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           math.Random().nextInt(10000).toString();
  }
  
  /// Generate a message ID from the image path
  String _generateIdFromPath(String path) {
    return path.split('/').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  }
  
  /// Save the message cache to persistent storage
  Future<void> _saveCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      final List<String> messageJsonList = _messageCache.values.map((message) {
        return jsonEncode(message.toJson());
      }).toList();
      
      await prefs.setStringList('steganography_message_cache', messageJsonList);
    } catch (e) {
      debugPrint('Error saving steganography cache: $e');
    }
  }
  
  /// Load the message cache from persistent storage
  Future<void> _loadCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      final List<String>? messageJsonList = prefs.getStringList('steganography_message_cache');
      
      if (messageJsonList != null) {
        for (final String messageJson in messageJsonList) {
          final Map<String, dynamic> messageMap = jsonDecode(messageJson);
          final SteganographicMessage message = SteganographicMessage.fromJson(messageMap);
          
          // Only add messages whose files still exist
          if (message.imagePath != null && File(message.imagePath!).existsSync()) {
            _messageCache[message.id] = message;
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading steganography cache: $e');
    }
  }
}

/// Model representing a steganographic message
class SteganographicMessage {
  final String id;
  final String? imagePath;
  final DateTime createdAt;
  final String? senderId;
  final String? recipientId;
  final bool isEncrypted;
  final String? originalImagePath;
  
  SteganographicMessage({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    this.senderId,
    this.recipientId,
    required this.isEncrypted,
    this.originalImagePath,
  });
  
  /// Create a copy of this message with some fields modified
  SteganographicMessage copyWith({
    String? id,
    String? imagePath,
    DateTime? createdAt,
    String? senderId,
    String? recipientId,
    bool? isEncrypted,
    String? originalImagePath,
  }) {
    return SteganographicMessage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      originalImagePath: originalImagePath ?? this.originalImagePath,
    );
  }
  
  /// Convert this message to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'senderId': senderId,
      'recipientId': recipientId,
      'isEncrypted': isEncrypted,
      'originalImagePath': originalImagePath,
    };
  }
  
  /// Create a message from a JSON map
  factory SteganographicMessage.fromJson(Map<String, dynamic> json) {
    return SteganographicMessage(
      id: json['id'],
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      isEncrypted: json['isEncrypted'],
      originalImagePath: json['originalImagePath'],
    );
  }
} 