import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

class MessageService {
  // Save a message to Hive
  Future<void> saveMessage(String chatId, Message message) async {
    final boxName = '${HiveBoxNames.messagesPrefix}_$chatId';
    
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    
    final messageBox = Hive.box(boxName);
    await messageBox.put(message.id, message.toJson());
  }
  
  // Get messages for a specific chat
  Future<List<Message>> getMessages(String chatId, {int limit = 50, int offset = 0}) async {
    final boxName = '${HiveBoxNames.messagesPrefix}_$chatId';
    
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    
    final messageBox = Hive.box(boxName);
    final List<Message> messages = [];
    
    // Convert all messages to a list and sort by timestamp
    final allMessages = messageBox.values
        .map((data) => Message.fromJson(Map<String, dynamic>.from(data)))
        .toList();
    
    // Sort messages by timestamp (newest first for easier pagination)
    allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Apply pagination
    final paginatedMessages = allMessages.skip(offset).take(limit).toList();
    
    // Reverse the order so oldest messages come first
    return paginatedMessages.reversed.toList();
  }
  
  // Get a single message by ID
  Future<Message?> getMessageById(String chatId, String messageId) async {
    final boxName = '${HiveBoxNames.messagesPrefix}_$chatId';
    
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    
    final messageBox = Hive.box(boxName);
    final messageData = messageBox.get(messageId);
    
    if (messageData != null) {
      return Message.fromJson(Map<String, dynamic>.from(messageData));
    }
    
    return null;
  }
  
  // Update an existing message
  Future<void> updateMessage(String chatId, Message message) async {
    final boxName = '${HiveBoxNames.messagesPrefix}_$chatId';
    
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    
    final messageBox = Hive.box(boxName);
    
    // Check if the message exists
    if (messageBox.containsKey(message.id)) {
      await messageBox.put(message.id, message.toJson());
    }
  }
  
  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    final boxName = '${HiveBoxNames.messagesPrefix}_$chatId';
    
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    
    final messageBox = Hive.box(boxName);
    await messageBox.delete(messageId);
  }
  
  // Delete all messages for a chat
  Future<void> deleteAllMessages(String chatId) async {
    final boxName = '${HiveBoxNames.messagesPrefix}_$chatId';
    
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    
    final messageBox = Hive.box(boxName);
    await messageBox.clear();
  }
  
  // Mark a message as read
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    final message = await getMessageById(chatId, messageId);
    
    if (message != null && message.status != MessageStatus.read) {
      final updatedMessage = message.copyWith(
        status: MessageStatus.read,
        readAt: DateTime.now(),
      );
      
      await updateMessage(chatId, updatedMessage);
    }
  }
  
  // Mark all messages in a chat as read
  Future<void> markAllMessagesAsRead(String chatId) async {
    final boxName = '${HiveBoxNames.messagesPrefix}_$chatId';
    
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    
    final messageBox = Hive.box(boxName);
    
    for (final key in messageBox.keys) {
      final messageData = messageBox.get(key);
      if (messageData != null) {
        final message = Message.fromJson(Map<String, dynamic>.from(messageData));
        
        if (!message.isMe && message.status != MessageStatus.read) {
          final updatedMessage = message.copyWith(
            status: MessageStatus.read,
            readAt: DateTime.now(),
          );
          
          await messageBox.put(key, updatedMessage.toJson());
        }
      }
    }
  }
  
  // Get the count of unread messages in a chat
  Future<int> getUnreadMessageCount(String chatId) async {
    final boxName = '${HiveBoxNames.messagesPrefix}_$chatId';
    
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    
    final messageBox = Hive.box(boxName);
    int count = 0;
    
    for (final key in messageBox.keys) {
      final messageData = messageBox.get(key);
      if (messageData != null) {
        final message = Message.fromJson(Map<String, dynamic>.from(messageData));
        
        if (!message.isMe && message.status != MessageStatus.read) {
          count++;
        }
      }
    }
    
    return count;
  }
  
  // Clean up expired self-destructing messages
  Future<void> cleanupExpiredMessages() async {
    // Get all message box names
    final messageBoxPattern = RegExp('^${HiveBoxNames.messagesPrefix}_.*');
    
    for (final boxName in Hive.boxes.keys.where((box) => messageBoxPattern.hasMatch(box))) {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      
      final messageBox = Hive.box(boxName);
      final List<String> keysToDelete = [];
      
      for (final key in messageBox.keys) {
        final messageData = messageBox.get(key);
        if (messageData != null) {
          final message = Message.fromJson(Map<String, dynamic>.from(messageData));
          
          if (message.selfDestruct && message.isExpired) {
            keysToDelete.add(key);
          }
        }
      }
      
      // Delete expired messages
      for (final key in keysToDelete) {
        await messageBox.delete(key);
      }
    }
  }
} 