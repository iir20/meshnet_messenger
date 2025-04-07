import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:secure_mesh_messenger/models/chat.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/models/user.dart';
import 'package:secure_mesh_messenger/services/crypto_service.dart';
import 'package:secure_mesh_messenger/services/message_service.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  List<Chat> _archivedChats = [];
  Chat? _currentChat;
  bool _isLoading = false;
  String _error = '';
  final MessageService _messageService = MessageService();
  final CryptoService _cryptoService = CryptoService();
  
  // Backup of the last deleted chat for potential restoration
  Chat? _lastDeletedChat;
  
  // Getters
  List<Chat> get chats => _chats;
  List<Chat> get archivedChats => _archivedChats;
  Chat? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // Load all chats
  Future<void> loadChats() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Initialize Hive if not already initialized
      if (!Hive.isBoxOpen(HiveBoxNames.chats)) {
        await Hive.openBox(HiveBoxNames.chats);
      }
      
      final chatBox = Hive.box(HiveBoxNames.chats);
      final List<Chat> loadedChats = [];
      final List<Chat> loadedArchivedChats = [];
      
      // Load all chats from storage
      for (final key in chatBox.keys) {
        final chatData = chatBox.get(key);
        if (chatData != null) {
          final chat = Chat.fromJson(Map<String, dynamic>.from(chatData));
          
          if (chat.isArchived) {
            loadedArchivedChats.add(chat);
          } else {
            loadedChats.add(chat);
          }
        }
      }
      
      // Sort chats by most recent message
      loadedChats.sort((a, b) {
        if (a.lastMessage == null && b.lastMessage == null) return 0;
        if (a.lastMessage == null) return 1;
        if (b.lastMessage == null) return -1;
        
        return b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp);
      });
      
      // Sort archived chats similarly
      loadedArchivedChats.sort((a, b) {
        if (a.lastMessage == null && b.lastMessage == null) return 0;
        if (a.lastMessage == null) return 1;
        if (b.lastMessage == null) return -1;
        
        return b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp);
      });
      
      _chats = loadedChats;
      _archivedChats = loadedArchivedChats;
    } catch (e) {
      _error = 'Failed to load chats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get a chat by ID
  Future<Chat?> getChatById(String chatId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (!Hive.isBoxOpen(HiveBoxNames.chats)) {
        await Hive.openBox(HiveBoxNames.chats);
      }
      
      final chatBox = Hive.box(HiveBoxNames.chats);
      final chatData = chatBox.get(chatId);
      
      if (chatData != null) {
        _currentChat = Chat.fromJson(Map<String, dynamic>.from(chatData));
        return _currentChat;
      }
      
      return null;
    } catch (e) {
      _error = 'Failed to get chat: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a new chat with a user
  Future<Chat?> createChat(User participant) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Check if a chat with this user already exists
      final existingChat = _chats.firstWhere(
        (chat) => chat.participantId == participant.id,
        orElse: () => _archivedChats.firstWhere(
          (chat) => chat.participantId == participant.id,
          orElse: () => Chat(
            id: '',
            name: '',
            participantId: '',
            createdAt: DateTime.now(),
            encryptionKey: '',
          ),
        ),
      );
      
      if (existingChat.id.isNotEmpty) {
        // Unarchive the chat if it was archived
        if (existingChat.isArchived) {
          await toggleArchiveChat(existingChat.id, false);
        }
        return existingChat;
      }
      
      // Generate a unique chat ID
      final chatId = const Uuid().v4();
      
      // Generate a symmetric encryption key for the chat
      final encryptionKey = await _cryptoService.generateSymmetricKey();
      
      // Create the new chat
      final newChat = Chat(
        id: chatId,
        name: participant.displayName.isNotEmpty ? participant.displayName : participant.username,
        participantId: participant.id,
        avatarUrl: participant.avatarUrl,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        encryptionKey: encryptionKey,
      );
      
      // Save the chat to Hive
      if (!Hive.isBoxOpen(HiveBoxNames.chats)) {
        await Hive.openBox(HiveBoxNames.chats);
      }
      
      final chatBox = Hive.box(HiveBoxNames.chats);
      await chatBox.put(chatId, newChat.toJson());
      
      // Add to the list of chats
      _chats.add(newChat);
      
      // Set as current chat
      _currentChat = newChat;
      
      return newChat;
    } catch (e) {
      _error = 'Failed to create chat: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Send a message to a chat
  Future<Message?> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    String? replyToMessageId,
    bool selfDestruct = false,
    int? selfDestructTimeout,
    Map<String, dynamic>? embeddedData,
    String? mediaPath,
    double? mediaWidth,
    double? mediaHeight,
    double? fileSizeKb,
    String? fileName,
    String? arEffectId,
    Map<String, dynamic>? arMetadata,
  }) async {
    try {
      // Generate a unique message ID
      final messageId = const Uuid().v4();
      
      // Get the current chat
      final chat = await getChatById(chatId);
      if (chat == null) {
        _error = 'Chat not found';
        notifyListeners();
        return null;
      }
      
      // Create the message based on type
      Message message;
      
      switch (type) {
        case MessageType.text:
          message = Message.text(
            id: messageId,
            chatId: chatId,
            senderId: 'current_user_id', // Replace with actual user ID
            content: content,
            isMe: true,
            status: MessageStatus.sending,
            replyToMessageId: replyToMessageId,
            selfDestruct: selfDestruct,
            selfDestructTimeout: selfDestructTimeout,
            embeddedData: embeddedData,
          );
          break;
          
        case MessageType.image:
          message = Message.image(
            id: messageId,
            chatId: chatId,
            senderId: 'current_user_id', // Replace with actual user ID
            content: content,
            isMe: true,
            mediaPath: mediaPath!,
            width: mediaWidth,
            height: mediaHeight,
            fileSizeKb: fileSizeKb,
            selfDestruct: selfDestruct,
            selfDestructTimeout: selfDestructTimeout,
            embeddedData: embeddedData,
          );
          break;
          
        case MessageType.ar:
          message = Message.ar(
            id: messageId,
            chatId: chatId,
            senderId: 'current_user_id', // Replace with actual user ID
            content: content,
            isMe: true,
            mediaPath: mediaPath!,
            arEffectId: arEffectId!,
            arMetadata: arMetadata,
          );
          break;
          
        default:
          // For simplicity, handle other types as text for now
          message = Message.text(
            id: messageId,
            chatId: chatId,
            senderId: 'current_user_id', // Replace with actual user ID
            content: content,
            isMe: true,
            status: MessageStatus.sending,
          );
      }
      
      // Encrypt the message if needed
      // await _encryptMessage(message, chat.encryptionKey);
      
      // Save the message
      await _messageService.saveMessage(chatId, message);
      
      // Update the chat's last message
      final updatedChat = chat.copyWith(
        lastMessage: message,
        lastUpdatedAt: DateTime.now(),
      );
      
      // Save the updated chat
      await _saveChat(updatedChat);
      
      // Update the current chat
      _currentChat = updatedChat;
      
      // Update the chats list
      _updateChatInList(updatedChat);
      
      notifyListeners();
      
      // Simulate sending the message over the network
      await _simulateSendingMessage(message);
      
      return message;
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
      return null;
    }
  }
  
  // Load messages for a chat
  Future<List<Message>> loadMessages(String chatId, {int limit = 50, int offset = 0}) async {
    try {
      return await _messageService.getMessages(chatId, limit: limit, offset: offset);
    } catch (e) {
      _error = 'Failed to load messages: $e';
      notifyListeners();
      return [];
    }
  }
  
  // Mark a chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null || chat.unreadCount == 0) return;
      
      final updatedChat = chat.copyWith(unreadCount: 0);
      
      // Save the updated chat
      await _saveChat(updatedChat);
      
      // Update the current chat
      _currentChat = updatedChat;
      
      // Update the chats list
      _updateChatInList(updatedChat);
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark chat as read: $e';
      notifyListeners();
    }
  }
  
  // Toggle mute status for a chat
  Future<void> toggleMuteChat(String chatId, bool mute) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return;
      
      final updatedChat = chat.copyWith(isMuted: mute);
      
      // Save the updated chat
      await _saveChat(updatedChat);
      
      // Update the current chat
      _currentChat = updatedChat;
      
      // Update the chats list
      _updateChatInList(updatedChat);
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update mute status: $e';
      notifyListeners();
    }
  }
  
  // Toggle archive status for a chat
  Future<void> toggleArchiveChat(String chatId, bool archive) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return;
      
      final updatedChat = chat.copyWith(isArchived: archive);
      
      // Save the updated chat
      await _saveChat(updatedChat);
      
      // Update chats lists
      if (archive) {
        _chats.removeWhere((c) => c.id == chatId);
        _archivedChats.add(updatedChat);
      } else {
        _archivedChats.removeWhere((c) => c.id == chatId);
        _chats.add(updatedChat);
      }
      
      // Sort the lists
      _sortChats();
      
      // Update the current chat if needed
      if (_currentChat?.id == chatId) {
        _currentChat = updatedChat;
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to archive/unarchive chat: $e';
      notifyListeners();
    }
  }
  
  // Delete a chat
  Future<bool> deleteChat(String chatId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return false;
      
      // Save for potential restoration
      _lastDeletedChat = chat;
      
      // Remove from lists
      _chats.removeWhere((c) => c.id == chatId);
      _archivedChats.removeWhere((c) => c.id == chatId);
      
      // Remove from storage
      if (!Hive.isBoxOpen(HiveBoxNames.chats)) {
        await Hive.openBox(HiveBoxNames.chats);
      }
      
      final chatBox = Hive.box(HiveBoxNames.chats);
      await chatBox.delete(chatId);
      
      // Delete messages
      await _messageService.deleteAllMessages(chatId);
      
      // Clear current chat if it was deleted
      if (_currentChat?.id == chatId) {
        _currentChat = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete chat: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Restore the last deleted chat
  Future<bool> restoreChat(Chat chat) async {
    try {
      // Save the chat
      await _saveChat(chat);
      
      // Add to the appropriate list
      if (chat.isArchived) {
        _archivedChats.add(chat);
      } else {
        _chats.add(chat);
      }
      
      // Sort the lists
      _sortChats();
      
      // Clear the last deleted chat
      _lastDeletedChat = null;
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to restore chat: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Helper method to save a chat to storage
  Future<void> _saveChat(Chat chat) async {
    if (!Hive.isBoxOpen(HiveBoxNames.chats)) {
      await Hive.openBox(HiveBoxNames.chats);
    }
    
    final chatBox = Hive.box(HiveBoxNames.chats);
    await chatBox.put(chat.id, chat.toJson());
  }
  
  // Helper method to update a chat in the lists
  void _updateChatInList(Chat updatedChat) {
    if (updatedChat.isArchived) {
      final index = _archivedChats.indexWhere((c) => c.id == updatedChat.id);
      if (index != -1) {
        _archivedChats[index] = updatedChat;
      }
    } else {
      final index = _chats.indexWhere((c) => c.id == updatedChat.id);
      if (index != -1) {
        _chats[index] = updatedChat;
      }
    }
    
    // Sort the lists
    _sortChats();
  }
  
  // Helper method to sort the chat lists
  void _sortChats() {
    _chats.sort((a, b) {
      if (a.lastMessage == null && b.lastMessage == null) return 0;
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return -1;
      
      return b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp);
    });
    
    _archivedChats.sort((a, b) {
      if (a.lastMessage == null && b.lastMessage == null) return 0;
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return -1;
      
      return b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp);
    });
  }
  
  // Simulate sending a message over the network
  Future<void> _simulateSendingMessage(Message message) async {
    // Wait a random amount of time to simulate network latency
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Update the message status
    final updatedMessage = message.copyWith(
      status: MessageStatus.sent,
    );
    
    // Save the updated message
    await _messageService.updateMessage(message.chatId, updatedMessage);
    
    // Wait a bit more to simulate delivery
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Update the message status to delivered
    final deliveredMessage = updatedMessage.copyWith(
      status: MessageStatus.delivered,
      deliveredAt: DateTime.now(),
    );
    
    // Save the updated message
    await _messageService.updateMessage(message.chatId, deliveredMessage);
    
    // If this is the current chat, update its last message
    if (_currentChat?.id == message.chatId) {
      final updatedChat = _currentChat!.copyWith(
        lastMessage: deliveredMessage,
      );
      
      // Save the updated chat
      await _saveChat(updatedChat);
      
      // Update the current chat
      _currentChat = updatedChat;
      
      // Update the chats list
      _updateChatInList(updatedChat);
      
      notifyListeners();
    }
  }
} 