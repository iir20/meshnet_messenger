import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

part 'message.g.dart';

@HiveType(typeId: 1)
enum MessageType {
  @HiveField(0)
  text,
  
  @HiveField(1)
  image,
  
  @HiveField(2)
  video,
  
  @HiveField(3)
  audio,
  
  @HiveField(4)
  file,
  
  @HiveField(5)
  location,
  
  @HiveField(6)
  contact,
  
  @HiveField(7)
  ar,
  
  @HiveField(8)
  system,
}

@HiveType(typeId: 2)
enum MessageStatus {
  @HiveField(0)
  sending,
  
  @HiveField(1)
  sent,
  
  @HiveField(2)
  delivered,
  
  @HiveField(3)
  read,
  
  @HiveField(4)
  failed,
  
  @HiveField(5)
  deleted,
}

@HiveType(typeId: 3)
class Message {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String chatId;
  
  @HiveField(2)
  final String senderId;
  
  @HiveField(3)
  final MessageType type;
  
  @HiveField(4)
  final String content;
  
  @HiveField(5)
  final DateTime timestamp;
  
  @HiveField(6)
  final MessageStatus status;
  
  @HiveField(7)
  final bool isMe;
  
  @HiveField(8)
  final String? mediaUrl;
  
  @HiveField(9)
  final String? mediaPath;
  
  @HiveField(10)
  final String? thumbnailUrl;
  
  @HiveField(11)
  final String? thumbnailPath;
  
  @HiveField(12)
  final double? mediaWidth;
  
  @HiveField(13)
  final double? mediaHeight;
  
  @HiveField(14)
  final double? fileSizeKb;
  
  @HiveField(15)
  final String? fileName;
  
  @HiveField(16)
  final String? fileExtension;
  
  @HiveField(17)
  final Map<String, double>? locationCoordinates;
  
  @HiveField(18)
  final String? locationName;
  
  @HiveField(19)
  final String? contactId;
  
  @HiveField(20)
  final String? contactName;
  
  @HiveField(21)
  final String? replyToMessageId;
  
  @HiveField(22)
  final bool selfDestruct;
  
  @HiveField(23)
  final int? selfDestructTimeout;
  
  @HiveField(24)
  final DateTime? expiryTime;
  
  @HiveField(25)
  final DateTime? readAt;
  
  @HiveField(26)
  final DateTime? deliveredAt;
  
  @HiveField(27)
  final Map<String, bool>? readBy;
  
  @HiveField(28)
  final Map<String, dynamic>? embeddedData;
  
  @HiveField(29)
  final String? emotionDetected;
  
  @HiveField(30)
  final String? arEffectId;
  
  @HiveField(31)
  final Map<String, dynamic>? arMetadata;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.status,
    required this.isMe,
    this.mediaUrl,
    this.mediaPath,
    this.thumbnailUrl,
    this.thumbnailPath,
    this.mediaWidth,
    this.mediaHeight,
    this.fileSizeKb,
    this.fileName,
    this.fileExtension,
    this.locationCoordinates,
    this.locationName,
    this.contactId,
    this.contactName,
    this.replyToMessageId,
    this.selfDestruct = false,
    this.selfDestructTimeout,
    this.expiryTime,
    this.readAt,
    this.deliveredAt,
    this.readBy,
    this.embeddedData,
    this.emotionDetected,
    this.arEffectId,
    this.arMetadata,
  });
  
  // Create a text message
  factory Message.text({
    required String id,
    required String chatId,
    required String senderId,
    required String content,
    required bool isMe,
    MessageStatus status = MessageStatus.sending,
    DateTime? timestamp,
    String? replyToMessageId,
    bool selfDestruct = false,
    int? selfDestructTimeout,
    Map<String, dynamic>? embeddedData,
  }) {
    final now = timestamp ?? DateTime.now();
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      type: MessageType.text,
      content: content,
      timestamp: now,
      status: status,
      isMe: isMe,
      replyToMessageId: replyToMessageId,
      selfDestruct: selfDestruct,
      selfDestructTimeout: selfDestructTimeout,
      expiryTime: selfDestruct && selfDestructTimeout != null
          ? now.add(Duration(seconds: selfDestructTimeout))
          : null,
      embeddedData: embeddedData,
    );
  }
  
  // Create an image message
  factory Message.image({
    required String id,
    required String chatId,
    required String senderId,
    required bool isMe,
    String? content,
    required String mediaPath,
    String? mediaUrl,
    String? thumbnailPath,
    String? thumbnailUrl,
    double? width,
    double? height,
    double? fileSizeKb,
    MessageStatus status = MessageStatus.sending,
    DateTime? timestamp,
    String? replyToMessageId,
    bool selfDestruct = false,
    int? selfDestructTimeout,
    Map<String, dynamic>? embeddedData,
  }) {
    final now = timestamp ?? DateTime.now();
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      type: MessageType.image,
      content: content ?? 'Image',
      timestamp: now,
      status: status,
      isMe: isMe,
      mediaPath: mediaPath,
      mediaUrl: mediaUrl,
      thumbnailPath: thumbnailPath,
      thumbnailUrl: thumbnailUrl,
      mediaWidth: width,
      mediaHeight: height,
      fileSizeKb: fileSizeKb,
      replyToMessageId: replyToMessageId,
      selfDestruct: selfDestruct,
      selfDestructTimeout: selfDestructTimeout,
      expiryTime: selfDestruct && selfDestructTimeout != null
          ? now.add(Duration(seconds: selfDestructTimeout))
          : null,
      embeddedData: embeddedData,
    );
  }
  
  // Create an AR message
  factory Message.ar({
    required String id,
    required String chatId,
    required String senderId,
    required bool isMe,
    String? content,
    required String mediaPath,
    String? mediaUrl,
    String? thumbnailPath,
    String? thumbnailUrl,
    required String arEffectId,
    Map<String, dynamic>? arMetadata,
    MessageStatus status = MessageStatus.sending,
    DateTime? timestamp,
  }) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      type: MessageType.ar,
      content: content ?? 'AR Message',
      timestamp: timestamp ?? DateTime.now(),
      status: status,
      isMe: isMe,
      mediaPath: mediaPath,
      mediaUrl: mediaUrl,
      thumbnailPath: thumbnailPath,
      thumbnailUrl: thumbnailUrl,
      arEffectId: arEffectId,
      arMetadata: arMetadata,
    );
  }
  
  // Create a copy of the message with updated fields
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isMe,
    String? mediaUrl,
    String? mediaPath,
    String? thumbnailUrl,
    String? thumbnailPath,
    double? mediaWidth,
    double? mediaHeight,
    double? fileSizeKb,
    String? fileName,
    String? fileExtension,
    Map<String, double>? locationCoordinates,
    String? locationName,
    String? contactId,
    String? contactName,
    String? replyToMessageId,
    bool? selfDestruct,
    int? selfDestructTimeout,
    DateTime? expiryTime,
    DateTime? readAt,
    DateTime? deliveredAt,
    Map<String, bool>? readBy,
    Map<String, dynamic>? embeddedData,
    String? emotionDetected,
    String? arEffectId,
    Map<String, dynamic>? arMetadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isMe: isMe ?? this.isMe,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaPath: mediaPath ?? this.mediaPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      fileSizeKb: fileSizeKb ?? this.fileSizeKb,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      locationCoordinates: locationCoordinates ?? this.locationCoordinates,
      locationName: locationName ?? this.locationName,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      selfDestruct: selfDestruct ?? this.selfDestruct,
      selfDestructTimeout: selfDestructTimeout ?? this.selfDestructTimeout,
      expiryTime: expiryTime ?? this.expiryTime,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readBy: readBy ?? this.readBy,
      embeddedData: embeddedData ?? this.embeddedData,
      emotionDetected: emotionDetected ?? this.emotionDetected,
      arEffectId: arEffectId ?? this.arEffectId,
      arMetadata: arMetadata ?? this.arMetadata,
    );
  }
  
  // Convert message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'type': type.index,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
      'isMe': isMe,
      'mediaUrl': mediaUrl,
      'mediaPath': mediaPath,
      'thumbnailUrl': thumbnailUrl,
      'thumbnailPath': thumbnailPath,
      'mediaWidth': mediaWidth,
      'mediaHeight': mediaHeight,
      'fileSizeKb': fileSizeKb,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'locationCoordinates': locationCoordinates,
      'locationName': locationName,
      'contactId': contactId,
      'contactName': contactName,
      'replyToMessageId': replyToMessageId,
      'selfDestruct': selfDestruct,
      'selfDestructTimeout': selfDestructTimeout,
      'expiryTime': expiryTime?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readBy': readBy,
      'embeddedData': embeddedData,
      'emotionDetected': emotionDetected,
      'arEffectId': arEffectId,
      'arMetadata': arMetadata,
    };
  }
  
  // Create message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      type: MessageType.values[json['type'] as int],
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values[json['status'] as int],
      isMe: json['isMe'] as bool,
      mediaUrl: json['mediaUrl'] as String?,
      mediaPath: json['mediaPath'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      mediaWidth: json['mediaWidth'] as double?,
      mediaHeight: json['mediaHeight'] as double?,
      fileSizeKb: json['fileSizeKb'] as double?,
      fileName: json['fileName'] as String?,
      fileExtension: json['fileExtension'] as String?,
      locationCoordinates: json['locationCoordinates'] != null
          ? Map<String, double>.from(json['locationCoordinates'] as Map)
          : null,
      locationName: json['locationName'] as String?,
      contactId: json['contactId'] as String?,
      contactName: json['contactName'] as String?,
      replyToMessageId: json['replyToMessageId'] as String?,
      selfDestruct: json['selfDestruct'] as bool? ?? false,
      selfDestructTimeout: json['selfDestructTimeout'] as int?,
      expiryTime: json['expiryTime'] != null
          ? DateTime.parse(json['expiryTime'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readBy: json['readBy'] != null
          ? Map<String, bool>.from(json['readBy'] as Map)
          : null,
      embeddedData: json['embeddedData'] as Map<String, dynamic>?,
      emotionDetected: json['emotionDetected'] as String?,
      arEffectId: json['arEffectId'] as String?,
      arMetadata: json['arMetadata'] as Map<String, dynamic>?,
    );
  }
  
  // Check if message is expired
  bool get isExpired {
    if (!selfDestruct || expiryTime == null) return false;
    return DateTime.now().isAfter(expiryTime!);
  }
  
  // Get remaining time in seconds until expiry
  int get remainingTimeInSeconds {
    if (!selfDestruct || expiryTime == null) return 0;
    final remaining = expiryTime!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

// EncryptedMessage for transmission over the network
class EncryptedMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String nonce;  // Base64 encoded
  final String ciphertext;  // Base64 encoded
  final String signature;  // Base64 encoded
  final MessageType type;
  final DateTime timestamp;
  
  EncryptedMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.nonce,
    required this.ciphertext,
    required this.signature,
    required this.type,
    required this.timestamp,
  });
  
  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'nonce': nonce,
      'ciphertext': ciphertext,
      'signature': signature,
      'type': type.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
  
  // Create from map after deserialization
  factory EncryptedMessage.fromMap(Map<String, dynamic> map) {
    return EncryptedMessage(
      id: map['id'],
      senderId: map['senderId'],
      recipientId: map['recipientId'],
      nonce: map['nonce'],
      ciphertext: map['ciphertext'],
      signature: map['signature'],
      type: MessageType.values[map['type']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
} 