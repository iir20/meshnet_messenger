import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/models/chat.dart';
import 'package:secure_mesh_messenger/models/peer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:cryptography/cryptography.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

class MessageProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  String? _currentChatId;
  final Map<String, List<Message>> _messages = {};
  
  // Session keys for peer encryption
  final Map<String, List<int>> _sessionKeys = {};
  
  // NLP model for message analysis (placeholder)
  bool _isNlpReady = false;
  
  // Getters
  List<Chat> get chats => List.unmodifiable(_chats);
  String? get currentChatId => _currentChatId;
  bool get isNlpReady => _isNlpReady;
  
  // Get messages for a specific chat
  List<Message> getMessages(String chatId) {
    return List.unmodifiable(_messages[chatId] ?? []);
  }
  
  // Get chat by ID
  Chat? getChatById(String chatId) {
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }
  
  MessageProvider() {
    _initHive();
    _loadNlpModel();
  }
  
  // Initialize Hive boxes
  Future<void> _initHive() async {
    try {
      // Open Hive boxes
      await Hive.openBox<dynamic>(chatsBoxName);
      await Hive.openBox<dynamic>(messagesBoxName);
      
      // Load data
      await _loadChatsAndMessages();
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
    }
  }
  
  // Load chats and messages from Hive
  Future<void> _loadChatsAndMessages() async {
    try {
      final chatsBox = Hive.box<dynamic>(chatsBoxName);
      final messagesBox = Hive.box<dynamic>(messagesBoxName);
      
      // Load chats
      _chats = [];
      for (final key in chatsBox.keys) {
        final chatJson = chatsBox.get(key);
        if (chatJson != null) {
          try {
            final chatMap = jsonDecode(chatJson.toString()) as Map<String, dynamic>;
            _chats.add(Chat.fromJson(chatMap));
          } catch (e) {
            // Skip invalid entries
            debugPrint('Error parsing chat: $e');
          }
        }
      }
      
      // Load messages
      _messages.clear();
      for (final chat in _chats) {
        final messagesJson = messagesBox.get(chat.id);
        if (messagesJson != null) {
          try {
            final List<dynamic> messagesList = jsonDecode(messagesJson.toString()) as List<dynamic>;
            _messages[chat.id] = messagesList
                .map((m) => Message.fromJson(m as Map<String, dynamic>))
                .toList();
          } catch (e) {
            _messages[chat.id] = [];
            debugPrint('Error parsing messages: $e');
          }
        } else {
          _messages[chat.id] = [];
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data from Hive: $e');
    }
  }
  
  // Load NLP model for message analysis
  Future<void> _loadNlpModel() async {
    // In a real implementation, this would load an NLP model
    // for message analysis, privacy checks, etc.
    
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));
    _isNlpReady = true;
    notifyListeners();
  }
  
  // Create or get a chat with a peer
  Future<Chat> getOrCreateChat(Peer peer) async {
    // Check if chat already exists
    try {
      Chat? existingChat = _chats.firstWhere((chat) => chat.peerId == peer.id);
      _currentChatId = existingChat.id;
      notifyListeners();
      return existingChat;
    } catch (e) {
      // Create a new chat
      final newChat = Chat(
        id: const Uuid().v4(),
        peerId: peer.id,
        peerName: peer.name,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        lastMessage: null,
        isEncrypted: true,
      );
      
      // Add to local state
      _chats.add(newChat);
      _messages[newChat.id] = [];
      
      // Save to Hive
      await _saveChat(newChat);
      
      _currentChatId = newChat.id;
      notifyListeners();
      
      return newChat;
    }
  }
  
  // Set current active chat
  void setCurrentChat(String chatId) {
    _currentChatId = chatId;
    notifyListeners();
  }
  
  // Send a message to a peer
  Future<bool> sendMessage(String chatId, String content, MessageType type) async {
    final chat = getChatById(chatId);
    if (chat == null) return false;
    
    // Create the message
    final message = Message(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: 'self', // Self ID
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      type: type,
      isEncrypted: true,
    );
    
    // Add to local state
    if (_messages.containsKey(chatId)) {
      _messages[chatId]!.add(message);
    } else {
      _messages[chatId] = [message];
    }
    
    // Update chat's last message
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index >= 0) {
      _chats[index] = _chats[index].copyWith(
        lastMessage: content,
        lastMessageAt: message.timestamp,
      );
      
      await _saveChat(_chats[index]);
    }
    
    // Save message to Hive
    await _saveMessages(chatId);
    
    notifyListeners();
    
    // TODO: Actually send the message to the peer
    // This would integrate with MeshProvider in a real implementation
    
    return true;
  }
  
  // Receive a message from a peer
  Future<void> receiveMessage(String peerId, String content, MessageType type) async {
    // Find chat with this peer
    Chat? chat;
    try {
      chat = _chats.firstWhere((c) => c.peerId == peerId);
    } catch (e) {
      // We don't have a chat with this peer yet
      // Create a mock peer to create the chat
      final peer = Peer(
        id: peerId,
        name: 'Unknown Peer', // We'll update this later
        lastSeen: DateTime.now(),
      );
      chat = await getOrCreateChat(peer);
    }
    
    // Create the message
    final message = Message(
      id: const Uuid().v4(),
      chatId: chat.id,
      senderId: peerId,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.received,
      type: type,
      isEncrypted: true,
    );
    
    // Check message content with NLP if enabled
    if (_isNlpReady) {
      final isSafe = await _analyzeMessageWithNlp(content);
      if (!isSafe) {
        // Mark the message as potentially unsafe
        // TODO: Add flagging mechanism to Message model
      }
    }
    
    // Add to local state
    if (_messages.containsKey(chat.id)) {
      _messages[chat.id]!.add(message);
    } else {
      _messages[chat.id] = [message];
    }
    
    // Update chat's last message
    final index = _chats.indexWhere((c) => c.id == chat.id);
    if (index >= 0) {
      _chats[index] = _chats[index].copyWith(
        lastMessage: content,
        lastMessageAt: message.timestamp,
      );
      
      await _saveChat(_chats[index]);
    }
    
    // Save message to Hive
    await _saveMessages(chat.id);
    
    notifyListeners();
  }
  
  // Save chat to Hive
  Future<void> _saveChat(Chat chat) async {
    try {
      final chatsBox = Hive.box<dynamic>(chatsBoxName);
      await chatsBox.put(chat.id, jsonEncode(chat.toJson()));
    } catch (e) {
      debugPrint('Error saving chat to Hive: $e');
    }
  }
  
  // Save messages to Hive
  Future<void> _saveMessages(String chatId) async {
    try {
      final messagesBox = Hive.box<dynamic>(messagesBoxName);
      final messages = _messages[chatId] ?? [];
      final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
      await messagesBox.put(chatId, messagesJson);
    } catch (e) {
      debugPrint('Error saving messages to Hive: $e');
    }
  }
  
  // Delete a chat and its messages
  Future<void> deleteChat(String chatId) async {
    try {
      // Remove from Hive
      final chatsBox = Hive.box<dynamic>(chatsBoxName);
      final messagesBox = Hive.box<dynamic>(messagesBoxName);
      
      await chatsBox.delete(chatId);
      await messagesBox.delete(chatId);
      
      // Remove from local state
      _chats.removeWhere((chat) => chat.id == chatId);
      _messages.remove(chatId);
      
      if (_currentChatId == chatId) {
        _currentChatId = null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }
  
  // Setup an encrypted session with a peer
  Future<void> setupEncryptedSession(String peerId) async {
    if (_sessionKeys.containsKey(peerId)) return;
    
    try {
      // In a real implementation, this would perform a key exchange
      // using the Signal Protocol or similar
      
      // For now, just generate a simple AES key
      final algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
      final secretKey = await algorithm.newSecretKey();
      final keyBytes = await secretKey.extractBytes();
      
      _sessionKeys[peerId] = keyBytes;
    } catch (e) {
      debugPrint('Error setting up encrypted session: $e');
    }
  }
  
  // Encrypt a message for a peer
  Future<Uint8List> encryptMessageForPeer(String peerId, String content) async {
    if (!_sessionKeys.containsKey(peerId)) {
      await setupEncryptedSession(peerId);
    }
    
    try {
      final algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
      final secretKey = SecretKey(_sessionKeys[peerId]!);
      
      // Generate a random nonce
      final nonce = algorithm.newNonce();
      
      // Encrypt the message
      final contentBytes = Uint8List.fromList(utf8.encode(content));
      final secretBox = await algorithm.encrypt(
        contentBytes,
        secretKey: secretKey,
        nonce: nonce,
      );
      
      // Combine nonce and ciphertext for transmission
      final result = Uint8List(nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length);
      result.setRange(0, nonce.length, nonce);
      result.setRange(nonce.length, nonce.length + secretBox.cipherText.length, secretBox.cipherText);
      result.setRange(nonce.length + secretBox.cipherText.length, result.length, secretBox.mac.bytes);
      
      return result;
    } catch (e) {
      debugPrint('Error encrypting message: $e');
      throw Exception('Encryption failed: $e');
    }
  }
  
  // Decrypt a message from a peer
  Future<String> decryptMessageFromPeer(String peerId, Uint8List encryptedData) async {
    if (!_sessionKeys.containsKey(peerId)) {
      throw Exception('No session key available for peer');
    }
    
    try {
      final algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
      final secretKey = SecretKey(_sessionKeys[peerId]!);
      
      // Extract nonce (IV), ciphertext, and MAC
      final nonceLength = algorithm.ivLength;
      final macLength = 32; // SHA-256 produces 32 bytes
      
      final nonce = encryptedData.sublist(0, nonceLength);
      final cipherText = encryptedData.sublist(
        nonceLength, 
        encryptedData.length - macLength,
      );
      final mac = Mac(encryptedData.sublist(encryptedData.length - macLength));
      
      // Create a SecretBox for decryption
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: mac,
      );
      
      // Decrypt the message
      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      debugPrint('Error decrypting message: $e');
      throw Exception('Decryption failed: $e');
    }
  }
  
  // Analyze message with NLP for safety/privacy
  Future<bool> _analyzeMessageWithNlp(String content) async {
    // In a real implementation, this would use an on-device NLP model
    // to check for scams, phishing, or other harmful content
    
    // For now, just do a simple check for suspicious keywords
    final lowerContent = content.toLowerCase();
    final suspiciousTerms = [
      'password', 'credit card', 'account number', 'social security',
      'transfer money', 'click this link', 'urgent action', 'send funds',
    ];
    
    for (final term in suspiciousTerms) {
      if (lowerContent.contains(term)) {
        return false; // Message flagged as potentially unsafe
      }
    }
    
    return true; // Message is probably safe
  }
} 