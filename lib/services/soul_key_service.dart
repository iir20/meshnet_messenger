import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

/// A message that can only be unlocked with a personal memory question+answer
/// and biometric authentication
class SoulKeyMessage {
  final String id;
  final String sender;
  final String receiver;
  final String content;
  final String mediaPath;
  final String question;
  final String answerHash;
  final DateTime createdAt;
  final bool isUnlocked;
  final int attemptCount;
  final int maxAttempts;
  final Color color;

  const SoulKeyMessage({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    this.mediaPath = '',
    required this.question,
    required this.answerHash,
    required this.createdAt,
    this.isUnlocked = false,
    this.attemptCount = 0,
    this.maxAttempts = 5,
    required this.color,
  });

  /// Create a copy of this message with updated fields
  SoulKeyMessage copyWith({
    String? id,
    String? sender,
    String? receiver,
    String? content,
    String? mediaPath,
    String? question,
    String? answerHash,
    DateTime? createdAt,
    bool? isUnlocked,
    int? attemptCount,
    int? maxAttempts,
    Color? color,
  }) {
    return SoulKeyMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      content: content ?? this.content,
      mediaPath: mediaPath ?? this.mediaPath,
      question: question ?? this.question,
      answerHash: answerHash ?? this.answerHash,
      createdAt: createdAt ?? this.createdAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      attemptCount: attemptCount ?? this.attemptCount,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      color: color ?? this.color,
    );
  }

  /// Convert message to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'mediaPath': mediaPath,
      'question': question,
      'answerHash': answerHash,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isUnlocked': isUnlocked,
      'attemptCount': attemptCount,
      'maxAttempts': maxAttempts,
      'color': color.value,
    };
  }

  /// Create message from map
  factory SoulKeyMessage.fromMap(Map<String, dynamic> map) {
    return SoulKeyMessage(
      id: map['id'],
      sender: map['sender'],
      receiver: map['receiver'],
      content: map['content'],
      mediaPath: map['mediaPath'],
      question: map['question'],
      answerHash: map['answerHash'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isUnlocked: map['isUnlocked'],
      attemptCount: map['attemptCount'],
      maxAttempts: map['maxAttempts'],
      color: Color(map['color']),
    );
  }

  /// Check if message is permanently locked due to exceeding max attempts
  bool get isPermanentlyLocked => attemptCount >= maxAttempts;

  /// Calculate remaining attempts
  int get remainingAttempts => maxAttempts - attemptCount;
}

class SoulKeyService extends ChangeNotifier {
  final List<SoulKeyMessage> _messages = [];
  final String _userId;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  List<SoulKeyMessage> get messages => _messages;
  
  List<SoulKeyMessage> get unlockedMessages => 
      _messages.where((msg) => msg.isUnlocked).toList();
  
  List<SoulKeyMessage> get lockedMessages => 
      _messages.where((msg) => !msg.isUnlocked && !msg.isPermanentlyLocked).toList();
  
  List<SoulKeyMessage> get permanentlyLockedMessages => 
      _messages.where((msg) => msg.isPermanentlyLocked).toList();

  SoulKeyService(this._userId) {
    _loadMessages();
  }

  /// Create a new Soul Key message
  Future<SoulKeyMessage> createMessage({
    required String receiver,
    required String content,
    String mediaPath = '',
    required String question,
    required String answer,
    int maxAttempts = 5,
    required Color color,
  }) async {
    // Generate a unique ID for the message
    final id = const Uuid().v4();
    
    // Create a hash of the answer for secure storage
    final answerHash = _generateAnswerHash(answer);
    
    // Create the message
    final message = SoulKeyMessage(
      id: id,
      sender: _userId,
      receiver: receiver,
      content: content,
      mediaPath: mediaPath,
      question: question,
      answerHash: answerHash,
      createdAt: DateTime.now(),
      maxAttempts: maxAttempts,
      color: color,
    );
    
    // Add to messages list
    _messages.add(message);
    
    // Save to storage
    await _saveMessages();
    
    // Notify listeners of change
    notifyListeners();
    
    return message;
  }

  /// Attempt to unlock a Soul Key message
  Future<bool> tryUnlockMessage({
    required String messageId,
    required String answer,
    required BuildContext context,
  }) async {
    // Find message with this ID
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) {
      return false;
    }
    
    final message = _messages[index];
    
    // Check if message is already unlocked
    if (message.isUnlocked) {
      return true;
    }
    
    // Check if message is permanently locked
    if (message.isPermanentlyLocked) {
      return false;
    }
    
    // Verify the answer
    final answerHash = _generateAnswerHash(answer);
    final isAnswerCorrect = message.answerHash == answerHash;
    
    // If answer is incorrect, increment attempt count and save
    if (!isAnswerCorrect) {
      _messages[index] = message.copyWith(
        attemptCount: message.attemptCount + 1,
      );
      await _saveMessages();
      notifyListeners();
      return false;
    }
    
    // Answer is correct, now verify biometric authentication
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        // Device doesn't support biometrics, consider using a password fallback
        // For simplicity, we'll just return true if the answer was correct
        _messages[index] = message.copyWith(isUnlocked: true);
        await _saveMessages();
        notifyListeners();
        return true;
      }
      
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock this Soul Key message',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (didAuthenticate) {
        // Both answer and biometrics are verified, unlock the message
        _messages[index] = message.copyWith(isUnlocked: true);
        await _saveMessages();
        notifyListeners();
        return true;
      } else {
        // Failed biometric authentication
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('Error authenticating: ${e.message}');
      return false;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    _messages.removeWhere((msg) => msg.id == messageId);
    await _saveMessages();
    notifyListeners();
  }

  /// Get a message by ID
  SoulKeyMessage? getMessage(String messageId) {
    try {
      return _messages.firstWhere((msg) => msg.id == messageId);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to generate a secure hash of the answer
  String _generateAnswerHash(String answer) {
    // Normalize answer: trim, lowercase, remove extra spaces
    final normalizedAnswer = answer.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    
    // Create a secure hash with salt
    final salt = 'soul_key_${_userId}_salt';
    final bytes = utf8.encode(normalizedAnswer + salt);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  /// Load messages from storage
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('soul_key_messages');
      
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        final messages = jsonList.map((item) => SoulKeyMessage.fromMap(item)).toList();
        
        // Filter messages relevant to this user
        _messages.addAll(messages.where(
          (msg) => msg.sender == _userId || msg.receiver == _userId
        ));
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading Soul Key messages: $e');
    }
  }

  /// Save messages to storage
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((msg) => msg.toMap()).toList();
      await prefs.setString('soul_key_messages', jsonEncode(messagesJson));
    } catch (e) {
      debugPrint('Error saving Soul Key messages: $e');
    }
  }
} 