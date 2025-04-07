import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'peer.g.dart';

/// Represents a peer node in the mesh network
@HiveType(typeId: 3)
class Peer {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final List<String> addresses;
  
  @HiveField(2)
  final DateTime lastSeen;
  
  @HiveField(3)
  final int latency; // in milliseconds
  
  @HiveField(4)
  final String? publicKey;
  
  @HiveField(5)
  final bool isTrusted;
  
  @HiveField(6)
  final int trustScore; // 0-100
  
  @HiveField(7)
  final String? name;
  
  @HiveField(8)
  final String? avatarPath;
  
  @HiveField(9)
  final bool isConnected;
  
  @HiveField(10)
  final bool isRelayNode;
  
  @HiveField(11)
  final List<String>? capabilities;
  
  @HiveField(12)
  final Map<String, dynamic>? metadata;
  
  @HiveField(13)
  final bool supportsPQCrypto;
  
  const Peer({
    required this.id,
    required this.addresses,
    required this.lastSeen,
    this.latency = 0,
    this.publicKey,
    this.isTrusted = false,
    this.trustScore = 0,
    this.name,
    this.avatarPath,
    this.isConnected = false,
    this.isRelayNode = false,
    this.capabilities,
    this.metadata,
    this.supportsPQCrypto = false,
  });
  
  // Factory for creating a new peer
  factory Peer.create({
    required String id,
    required List<String> addresses,
    String? publicKey,
    String? name,
    bool isTrusted = false,
    bool isRelayNode = false,
    bool supportsPQCrypto = false,
  }) {
    return Peer(
      id: id,
      addresses: addresses,
      lastSeen: DateTime.now(),
      publicKey: publicKey,
      isTrusted: isTrusted,
      name: name,
      isConnected: true,
      isRelayNode: isRelayNode,
      supportsPQCrypto: supportsPQCrypto,
    );
  }
  
  // Create a copy of the peer with updated fields
  Peer copyWith({
    String? id,
    List<String>? addresses,
    DateTime? lastSeen,
    int? latency,
    String? publicKey,
    bool? isTrusted,
    int? trustScore,
    String? name,
    String? avatarPath,
    bool? isConnected,
    bool? isRelayNode,
    List<String>? capabilities,
    Map<String, dynamic>? metadata,
    bool? supportsPQCrypto,
  }) {
    return Peer(
      id: id ?? this.id,
      addresses: addresses ?? this.addresses,
      lastSeen: lastSeen ?? this.lastSeen,
      latency: latency ?? this.latency,
      publicKey: publicKey ?? this.publicKey,
      isTrusted: isTrusted ?? this.isTrusted,
      trustScore: trustScore ?? this.trustScore,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      isConnected: isConnected ?? this.isConnected,
      isRelayNode: isRelayNode ?? this.isRelayNode,
      capabilities: capabilities ?? this.capabilities,
      metadata: metadata ?? this.metadata,
      supportsPQCrypto: supportsPQCrypto ?? this.supportsPQCrypto,
    );
  }
  
  // Update peer's last seen timestamp
  Peer withLastSeen(DateTime timestamp) {
    return copyWith(lastSeen: timestamp);
  }
  
  // Update peer's connection status
  Peer withConnectionStatus(bool connected) {
    return copyWith(isConnected: connected, lastSeen: connected ? DateTime.now() : lastSeen);
  }
  
  // Update peer's latency
  Peer withLatency(int newLatency) {
    return copyWith(latency: newLatency);
  }
  
  // Update peer's trust score
  Peer withTrustScore(int newScore) {
    return copyWith(trustScore: newScore, isTrusted: newScore > 70);
  }
  
  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'addresses': addresses,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'latency': latency,
      'publicKey': publicKey,
      'isTrusted': isTrusted,
      'trustScore': trustScore,
      'name': name,
      'avatarPath': avatarPath,
      'isConnected': isConnected,
      'isRelayNode': isRelayNode,
      'capabilities': capabilities,
      'metadata': metadata,
      'supportsPQCrypto': supportsPQCrypto,
    };
  }
  
  // Create from map after deserialization
  factory Peer.fromMap(Map<String, dynamic> map) {
    return Peer(
      id: map['id'],
      addresses: List<String>.from(map['addresses']),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen']),
      latency: map['latency'] ?? 0,
      publicKey: map['publicKey'],
      isTrusted: map['isTrusted'] ?? false,
      trustScore: map['trustScore'] ?? 0,
      name: map['name'],
      avatarPath: map['avatarPath'],
      isConnected: map['isConnected'] ?? false,
      isRelayNode: map['isRelayNode'] ?? false,
      capabilities: map['capabilities'] != null 
          ? List<String>.from(map['capabilities']) 
          : null,
      metadata: map['metadata'],
      supportsPQCrypto: map['supportsPQCrypto'] ?? false,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Peer && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Peer(id: $id, name: $name, connected: $isConnected)';
  }
} 