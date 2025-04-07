import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 6)
class User {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String username;
  
  @HiveField(2)
  final String displayName;
  
  @HiveField(3)
  final String? avatarUrl;
  
  @HiveField(4)
  final String? avatarPath;
  
  @HiveField(5)
  final bool isOnline;
  
  @HiveField(6)
  final DateTime? lastSeen;
  
  @HiveField(7)
  final String publicKey;
  
  @HiveField(8)
  final List<String>? deviceIds;
  
  @HiveField(9)
  final bool isVerified;
  
  @HiveField(10)
  final bool isBlocked;
  
  @HiveField(11)
  final bool isMuted;
  
  @HiveField(12)
  final bool isEmergencyContact;
  
  @HiveField(13)
  final Map<String, dynamic>? statusData;
  
  @HiveField(14)
  final Map<String, dynamic>? settings;
  
  @HiveField(15)
  final DateTime createdAt;
  
  @HiveField(16)
  final DateTime? updatedAt;
  
  @HiveField(17)
  final Map<String, dynamic>? metadata;
  
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.avatarPath,
    this.isOnline = false,
    this.lastSeen,
    required this.publicKey,
    this.deviceIds,
    this.isVerified = false,
    this.isBlocked = false,
    this.isMuted = false,
    this.isEmergencyContact = false,
    this.statusData,
    this.settings,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });
  
  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? avatarPath,
    bool? isOnline,
    DateTime? lastSeen,
    String? publicKey,
    List<String>? deviceIds,
    bool? isVerified,
    bool? isBlocked,
    bool? isMuted,
    bool? isEmergencyContact,
    Map<String, dynamic>? statusData,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarPath: avatarPath ?? this.avatarPath,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      publicKey: publicKey ?? this.publicKey,
      deviceIds: deviceIds ?? this.deviceIds,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      isMuted: isMuted ?? this.isMuted,
      isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
      statusData: statusData ?? this.statusData,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarPath: json['avatarPath'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      publicKey: json['publicKey'] as String,
      deviceIds: json['deviceIds'] != null
          ? List<String>.from(json['deviceIds'] as List)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      isEmergencyContact: json['isEmergencyContact'] as bool? ?? false,
      statusData: json['statusData'] as Map<String, dynamic>?,
      settings: json['settings'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'avatarPath': avatarPath,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'publicKey': publicKey,
      'deviceIds': deviceIds,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'isMuted': isMuted,
      'isEmergencyContact': isEmergencyContact,
      'statusData': statusData,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  // Get user's display name or username if display name is empty
  String get name => displayName.isNotEmpty ? displayName : username;
  
  // Check if user has been active recently
  bool get isRecentlyActive {
    if (isOnline) return true;
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen!) < const Duration(days: 2);
  }
  
  // Get user's avatar initials (first letter of display name or username)
  String get initials {
    if (displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    } else if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }
    return '?';
  }
} 