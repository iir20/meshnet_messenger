import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'peer.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

part 'chat.g.dart';

@HiveType(typeId: 4)
enum ChatType {
  @HiveField(0)
  individual,
  
  @HiveField(1)
  group,
  
  @HiveField(2)
  broadcast,
  
  @HiveField(3)
  story,
  
  @HiveField(4)
  anonymous,
  
  @HiveField(5)
  emergency,
}

@HiveType(typeId: 5)
class Chat {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final ChatType type;
  
  @HiveField(3)
  final List<String> participantIds;
  
  @HiveField(4)
  final String? avatarPath;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime lastMessageAt;
  
  @HiveField(7)
  final bool isEncrypted;
  
  @HiveField(8)
  final bool isMuted;
  
  @HiveField(9)
  final bool isPinned;
  
  @HiveField(10)
  final bool isArchived;
  
  @HiveField(11)
  final String? lastMessageText;
  
  @HiveField(12)
  final String? lastMessageSenderId;
  
  @HiveField(13)
  final int unreadCount;
  
  @HiveField(14)
  final Map<String, dynamic>? metadata;
  
  @HiveField(15)
  final bool isGeoFenced;
  
  @HiveField(16)
  final Map<String, double>? geoFenceCoordinates;
  
  @HiveField(17)
  final double? geoFenceRadius;
  
  @HiveField(18)
  final bool requiresBiometric;
  
  @HiveField(19)
  final bool isSelfDestructing;
  
  @HiveField(20)
  final int? selfDestructTime; // in seconds
  
  @HiveField(21)
  final bool isEmotionAnalysisEnabled;
  
  const Chat({
    required this.id,
    required this.name,
    required this.type,
    required this.participantIds,
    required this.createdAt,
    required this.lastMessageAt,
    this.avatarPath,
    this.isEncrypted = true,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.metadata,
    this.isGeoFenced = false,
    this.geoFenceCoordinates,
    this.geoFenceRadius,
    this.requiresBiometric = false,
    this.isSelfDestructing = false,
    this.selfDestructTime,
    this.isEmotionAnalysisEnabled = false,
  });
  
  // Factory for creating a new individual chat
  factory Chat.individual({
    required String id,
    required String peerId,
    required String peerName,
    String? avatarPath,
  }) {
    return Chat(
      id: id,
      name: peerName,
      type: ChatType.individual,
      participantIds: [peerId],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      avatarPath: avatarPath,
    );
  }
  
  // Factory for creating a new group chat
  factory Chat.group({
    required String id,
    required String name,
    required List<String> participantIds,
    String? avatarPath,
    bool isEncrypted = true,
  }) {
    return Chat(
      id: id,
      name: name,
      type: ChatType.group,
      participantIds: participantIds,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      avatarPath: avatarPath,
      isEncrypted: isEncrypted,
    );
  }
  
  // Factory for creating a new story
  factory Chat.story({
    required String id,
    required String ownerId,
    required String ownerName,
    required List<String> viewerIds,
    String? avatarPath,
    bool requiresBiometric = false,
    bool isGeoFenced = false,
    Map<String, double>? geoFenceCoordinates,
    double? geoFenceRadius,
  }) {
    return Chat(
      id: id,
      name: "$ownerName's Story",
      type: ChatType.story,
      participantIds: [ownerId, ...viewerIds],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      avatarPath: avatarPath,
      requiresBiometric: requiresBiometric,
      isGeoFenced: isGeoFenced,
      geoFenceCoordinates: geoFenceCoordinates,
      geoFenceRadius: geoFenceRadius,
    );
  }
  
  // Factory for creating a new anonymous chat
  factory Chat.anonymous({
    required String id,
    required List<String> participantIds,
  }) {
    return Chat(
      id: id,
      name: "Anonymous Chat",
      type: ChatType.anonymous,
      participantIds: participantIds,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );
  }
  
  // Factory for creating a new emergency chat
  factory Chat.emergency({
    required String id,
    required String ownerId,
    required List<String> emergencyContactIds,
    String? avatarPath,
  }) {
    return Chat(
      id: id,
      name: "SOS",
      type: ChatType.emergency,
      participantIds: [ownerId, ...emergencyContactIds],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      avatarPath: avatarPath,
      isPinned: true,
    );
  }
  
  // Create a copy of the chat with updated fields
  Chat copyWith({
    String? id,
    String? name,
    ChatType? type,
    List<String>? participantIds,
    String? avatarPath,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    bool? isEncrypted,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    String? lastMessageText,
    String? lastMessageSenderId,
    int? unreadCount,
    Map<String, dynamic>? metadata,
    bool? isGeoFenced,
    Map<String, double>? geoFenceCoordinates,
    double? geoFenceRadius,
    bool? requiresBiometric,
    bool? isSelfDestructing,
    int? selfDestructTime,
    bool? isEmotionAnalysisEnabled,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      metadata: metadata ?? this.metadata,
      isGeoFenced: isGeoFenced ?? this.isGeoFenced,
      geoFenceCoordinates: geoFenceCoordinates ?? this.geoFenceCoordinates,
      geoFenceRadius: geoFenceRadius ?? this.geoFenceRadius,
      requiresBiometric: requiresBiometric ?? this.requiresBiometric,
      isSelfDestructing: isSelfDestructing ?? this.isSelfDestructing,
      selfDestructTime: selfDestructTime ?? this.selfDestructTime,
      isEmotionAnalysisEnabled: isEmotionAnalysisEnabled ?? this.isEmotionAnalysisEnabled,
    );
  }
  
  // Update the chat with a new message
  Chat withNewMessage({
    required String messageText,
    required String senderId,
    required DateTime timestamp,
  }) {
    return copyWith(
      lastMessageText: messageText,
      lastMessageSenderId: senderId,
      lastMessageAt: timestamp,
      unreadCount: unreadCount + 1,
    );
  }
  
  // Mark all messages as read
  Chat markAsRead() {
    return copyWith(unreadCount: 0);
  }
  
  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'participantIds': participantIds,
      'avatarPath': avatarPath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessageAt': lastMessageAt.millisecondsSinceEpoch,
      'isEncrypted': isEncrypted,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'metadata': metadata,
      'isGeoFenced': isGeoFenced,
      'geoFenceCoordinates': geoFenceCoordinates,
      'geoFenceRadius': geoFenceRadius,
      'requiresBiometric': requiresBiometric,
      'isSelfDestructing': isSelfDestructing,
      'selfDestructTime': selfDestructTime,
      'isEmotionAnalysisEnabled': isEmotionAnalysisEnabled,
    };
  }
  
  // Create from map after deserialization
  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      name: map['name'],
      type: ChatType.values[map['type']],
      participantIds: List<String>.from(map['participantIds']),
      avatarPath: map['avatarPath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(map['lastMessageAt']),
      isEncrypted: map['isEncrypted'] ?? true,
      isMuted: map['isMuted'] ?? false,
      isPinned: map['isPinned'] ?? false,
      isArchived: map['isArchived'] ?? false,
      lastMessageText: map['lastMessageText'],
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: map['unreadCount'] ?? 0,
      metadata: map['metadata'],
      isGeoFenced: map['isGeoFenced'] ?? false,
      geoFenceCoordinates: map['geoFenceCoordinates'] != null 
          ? Map<String, double>.from(map['geoFenceCoordinates']) 
          : null,
      geoFenceRadius: map['geoFenceRadius'],
      requiresBiometric: map['requiresBiometric'] ?? false,
      isSelfDestructing: map['isSelfDestructing'] ?? false,
      selfDestructTime: map['selfDestructTime'],
      isEmotionAnalysisEnabled: map['isEmotionAnalysisEnabled'] ?? false,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Chat(id: $id, name: $name, lastMessage: $lastMessageText)';
  }

  // Get the appropriate Hive box name for storing this chat's messages
  String get messagesBoxName => '${HiveBoxNames.messagesPrefix}_$id';
  
  // Check if the chat has been active recently
  bool get isRecentlyActive {
    if (lastMessageAt == null) return false;
    return DateTime.now().difference(lastMessageAt) < const Duration(days: 7);
  }
} 