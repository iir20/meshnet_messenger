import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

/// A message that is locked until a specific time in the future
class TimeCapsuleMessage {
  final String id;
  final String sender;
  final String receiver;
  final String content;
  final String? mediaPath;
  final Color color;
  final DateTime createdAt;
  final DateTime unlockTime;
  final bool unlocked;
  final String proofHash; // For tamper detection

  const TimeCapsuleMessage({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    this.mediaPath,
    required this.color,
    required this.createdAt,
    required this.unlockTime,
    this.unlocked = false,
    required this.proofHash,
  });

  /// Check if this message can be unlocked now
  bool get canUnlock => DateTime.now().isAfter(unlockTime);

  /// Time remaining until unlock
  Duration get timeRemaining => unlockTime.difference(DateTime.now());

  /// Convert message to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'mediaPath': mediaPath,
      'color': color.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'unlockTime': unlockTime.millisecondsSinceEpoch,
      'unlocked': unlocked,
      'proofHash': proofHash,
    };
  }

  /// Create a message from a map
  factory TimeCapsuleMessage.fromMap(Map<String, dynamic> map) {
    return TimeCapsuleMessage(
      id: map['id'],
      sender: map['sender'],
      receiver: map['receiver'],
      content: map['content'],
      mediaPath: map['mediaPath'],
      color: Color(map['color']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      unlockTime: DateTime.fromMillisecondsSinceEpoch(map['unlockTime']),
      unlocked: map['unlocked'],
      proofHash: map['proofHash'],
    );
  }

  /// Create a copy of this message with updated properties
  TimeCapsuleMessage copyWith({
    String? id,
    String? sender,
    String? receiver,
    String? content,
    String? mediaPath,
    Color? color,
    DateTime? createdAt,
    DateTime? unlockTime,
    bool? unlocked,
    String? proofHash,
  }) {
    return TimeCapsuleMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      content: content ?? this.content,
      mediaPath: mediaPath ?? this.mediaPath,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      unlockTime: unlockTime ?? this.unlockTime,
      unlocked: unlocked ?? this.unlocked,
      proofHash: proofHash ?? this.proofHash,
    );
  }

  /// Verify if the message has been tampered with
  bool verifyIntegrity() {
    final rawContent = '$sender:$receiver:$content:${createdAt.millisecondsSinceEpoch}:${unlockTime.millisecondsSinceEpoch}';
    final contentHash = _generateHash(rawContent);
    return contentHash == proofHash;
  }
}

class TimeCapsuleService extends ChangeNotifier {
  List<TimeCapsuleMessage> _messages = [];
  Timer? _unlockTimer;
  final String _userId;

  bool get hasUnlockedMessages => _messages.any((msg) => msg.unlocked);
  bool get hasPendingMessages => _messages.any((msg) => !msg.unlocked);
  
  List<TimeCapsuleMessage> get unlockedMessages => 
      _messages.where((msg) => msg.unlocked).toList();
  
  List<TimeCapsuleMessage> get pendingMessages => 
      _messages.where((msg) => !msg.unlocked).toList();

  TimeCapsuleService(this._userId) {
    _loadMessages();
    _startUnlockTimer();
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }

  /// Create a new time capsule message
  Future<TimeCapsuleMessage> createMessage({
    required String receiver,
    required String content,
    String? mediaPath,
    required Color color,
    required DateTime unlockTime,
  }) async {
    final id = const Uuid().v4();
    final createdAt = DateTime.now();
    
    // Generate the proof hash (ZK-proof like mechanism)
    final rawContent = '$_userId:$receiver:$content:${createdAt.millisecondsSinceEpoch}:${unlockTime.millisecondsSinceEpoch}';
    final proofHash = _generateHash(rawContent);

    final message = TimeCapsuleMessage(
      id: id,
      sender: _userId,
      receiver: receiver,
      content: content,
      mediaPath: mediaPath,
      color: color,
      createdAt: createdAt,
      unlockTime: unlockTime,
      proofHash: proofHash,
    );

    _messages.add(message);
    await _saveMessages();
    notifyListeners();
    return message;
  }

  /// Manually try to unlock a message
  Future<bool> tryUnlockMessage(String messageId) async {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return false;

    final message = _messages[index];
    
    // Check if it can be unlocked
    if (!message.canUnlock) return false;
    
    // Verify message integrity
    if (!message.verifyIntegrity()) {
      // Message was tampered with
      return false;
    }

    // Unlock the message
    _messages[index] = message.copyWith(unlocked: true);
    await _saveMessages();
    notifyListeners();
    return true;
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    _messages.removeWhere((msg) => msg.id == messageId);
    await _saveMessages();
    notifyListeners();
  }

  /// Get a message by ID
  TimeCapsuleMessage? getMessage(String messageId) {
    return _messages.firstWhere((msg) => msg.id == messageId);
  }

  // Private methods for internal service functionality

  /// Generate a hash for tamper detection
  String _generateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Load messages from storage
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('time_capsule_messages');
      
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _messages = jsonList
            .map((item) => TimeCapsuleMessage.fromMap(item))
            .toList();
        
        // Get only messages for this user
        _messages = _messages.where((msg) => 
            msg.sender == _userId || msg.receiver == _userId).toList();
            
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading time capsule messages: $e');
    }
  }

  /// Save messages to storage
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((msg) => msg.toMap()).toList();
      await prefs.setString('time_capsule_messages', jsonEncode(messagesJson));
    } catch (e) {
      debugPrint('Error saving time capsule messages: $e');
    }
  }

  /// Start timer to check for unlockable messages
  void _startUnlockTimer() {
    _unlockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkUnlockableMessages();
    });
    
    // Also check immediately
    _checkUnlockableMessages();
  }

  /// Check for messages that can be unlocked
  Future<void> _checkUnlockableMessages() async {
    bool hasUnlocked = false;
    
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      
      if (!message.unlocked && message.canUnlock && message.verifyIntegrity()) {
        _messages[i] = message.copyWith(unlocked: true);
        hasUnlocked = true;
      }
    }
    
    if (hasUnlocked) {
      await _saveMessages();
      notifyListeners();
    }
  }
} 