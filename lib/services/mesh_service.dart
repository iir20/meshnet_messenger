import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Model for a peer in the mesh network
class Peer {
  final String id;
  final String name;
  final String publicKey;
  bool isConnected;
  bool isVerified;
  double trustScore;
  DateTime lastSeen;
  
  Peer({
    required this.id,
    required this.name,
    required this.publicKey,
    this.isConnected = false,
    this.isVerified = false,
    this.trustScore = 0.0,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  // Clone with changes
  Peer copyWith({
    String? id,
    String? name,
    String? publicKey,
    bool? isConnected,
    bool? isVerified,
    double? trustScore,
    DateTime? lastSeen,
  }) {
    return Peer(
      id: id ?? this.id,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      isConnected: isConnected ?? this.isConnected,
      isVerified: isVerified ?? this.isVerified,
      trustScore: trustScore ?? this.trustScore,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

// Model for a message sent through the mesh
class MeshMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime timestamp;
  final bool isEncrypted;
  final String? encryptionType;
  final bool isDelivered;
  final bool isRead;
  
  MeshMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    DateTime? timestamp,
    this.isEncrypted = true,
    this.encryptionType,
    this.isDelivered = false,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Callback typedefs
typedef PeerDiscoveredCallback = void Function(Peer peer);
typedef MessageReceivedCallback = void Function(MeshMessage message);
typedef ConnectionStatusCallback = void Function(bool isConnected);

class MeshService with ChangeNotifier {
  // Local peer
  late Peer _localPeer;
  
  // List of discovered peers
  final List<Peer> _peers = [];
  
  // Pending messages
  final List<MeshMessage> _pendingMessages = [];
  
  // Subscription for peer discovery
  Timer? _discoveryTimer;
  Timer? _connectionTimer;
  
  // Random for mock implementation
  final math.Random _random = math.Random();
  
  // Stream controllers for events
  final StreamController<Peer> _peerDiscoveredController = StreamController<Peer>.broadcast();
  final StreamController<MeshMessage> _messageReceivedController = StreamController<MeshMessage>.broadcast();
  
  // Getters
  Peer get localPeer => _localPeer;
  List<Peer> get peers => List.unmodifiable(_peers);
  List<MeshMessage> get pendingMessages => List.unmodifiable(_pendingMessages);
  
  // Streams
  Stream<Peer> get onPeerDiscovered => _peerDiscoveredController.stream;
  Stream<MeshMessage> get onMessageReceived => _messageReceivedController.stream;
  
  // Constructor
  MeshService() {
    // Initialize local peer
    _initLocalPeer();
  }
  
  // Initialize the local peer with mock data
  void _initLocalPeer() {
    _localPeer = Peer(
      id: _generateRandomId(),
      name: 'LocalPeer',
      publicKey: _generateRandomKey(),
      isVerified: true,
      trustScore: 1.0,
    );
  }
  
  // Start peer discovery
  void startDiscovery() {
    // Cancel existing timer
    _discoveryTimer?.cancel();
    
    // Start periodic discovery
    _discoveryTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _discoverPeers(),
    );
    
    // Start connection management
    _connectionTimer = Timer.periodic(
      const Duration(seconds: 7),
      (_) => _manageConnections(),
    );
    
    // Initial discovery
    _discoverPeers();
    
    notifyListeners();
  }
  
  // Stop peer discovery
  void stopDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    
    _connectionTimer?.cancel();
    _connectionTimer = null;
    
    notifyListeners();
  }
  
  // Mock peer discovery
  void _discoverPeers() {
    // Simulate discovering new peers
    if (_random.nextDouble() < 0.7) {
      // 70% chance to discover a new peer
      final numNewPeers = _random.nextInt(2) + 1; // 1 or 2 new peers
      
      for (var i = 0; i < numNewPeers; i++) {
        if (_peers.length < 10) { // Limit to 10 peers for demo
          final newPeer = Peer(
            id: _generateRandomId(),
            name: _generateRandomName(),
            publicKey: _generateRandomKey(),
            isConnected: false,
            isVerified: _random.nextBool() && _random.nextBool(), // 25% chance to be verified
            trustScore: _random.nextDouble() * 0.7 + 0.3, // Score between 0.3 and 1.0
          );
          
          _peers.add(newPeer);
          _peerDiscoveredController.add(newPeer);
        }
      }
      
      notifyListeners();
    }
  }
  
  // Manage connections to peers
  void _manageConnections() {
    // Randomly connect/disconnect to simulate network conditions
    for (var i = 0; i < _peers.length; i++) {
      if (_random.nextDouble() < 0.3) { // 30% chance to change connection state
        final peer = _peers[i];
        
        // Update connection state
        _peers[i] = peer.copyWith(
          isConnected: !peer.isConnected,
          lastSeen: DateTime.now(),
        );
        
        // If connected, maybe increase trust score slightly
        if (_peers[i].isConnected && _random.nextDouble() < 0.5) {
          _peers[i] = _peers[i].copyWith(
            trustScore: math.min(1.0, _peers[i].trustScore + 0.05),
          );
        }
      }
    }
    
    // Remove peers that haven't been seen for a long time (in a real implementation)
    // Here we'll just randomly remove peers with low trust scores
    if (_peers.length > 5 && _random.nextDouble() < 0.1) {
      _peers.removeWhere((peer) => 
        !peer.isConnected && 
        peer.trustScore < 0.4 && 
        _random.nextDouble() < 0.3
      );
    }
    
    notifyListeners();
  }
  
  // Connect to a specific peer
  Future<bool> connectToPeer(String peerId) async {
    final peerIndex = _peers.indexWhere((p) => p.id == peerId);
    if (peerIndex == -1) {
      return false;
    }
    
    // Simulate connection delay
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));
    
    // 80% chance of successful connection
    final success = _random.nextDouble() < 0.8;
    
    if (success) {
      _peers[peerIndex] = _peers[peerIndex].copyWith(
        isConnected: true,
        lastSeen: DateTime.now(),
      );
      
      notifyListeners();
    }
    
    return success;
  }
  
  // Disconnect from a specific peer
  Future<bool> disconnectFromPeer(String peerId) async {
    final peerIndex = _peers.indexWhere((p) => p.id == peerId);
    if (peerIndex == -1) {
      return false;
    }
    
    // Simulate disconnection delay
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(300)));
    
    // 95% chance of successful disconnection
    final success = _random.nextDouble() < 0.95;
    
    if (success) {
      _peers[peerIndex] = _peers[peerIndex].copyWith(
        isConnected: false,
        lastSeen: DateTime.now(),
      );
      
      notifyListeners();
    }
    
    return success;
  }
  
  // Send a message to a peer
  Future<bool> sendMessage(String content, String recipientId, {bool isEncrypted = true, String? encryptionType}) async {
    final peerIndex = _peers.indexWhere((p) => p.id == recipientId);
    if (peerIndex == -1) {
      return false;
    }
    
    // Simulate some network conditions
    final isConnected = _peers[peerIndex].isConnected;
    final networkQuality = _random.nextDouble(); // 0 = bad, 1 = excellent
    
    // Create the message
    final message = MeshMessage(
      id: _generateRandomId(),
      senderId: _localPeer.id,
      recipientId: recipientId,
      content: content,
      isEncrypted: isEncrypted,
      encryptionType: encryptionType,
    );
    
    // Decide on immediate delivery or pending based on connection
    if (isConnected && networkQuality > 0.3) {
      // Simulate message transmission delay
      await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(500)));
      
      // Successfully delivered
      _messageReceivedController.add(message);
      
      // Maybe send a mock reply
      if (_random.nextDouble() < 0.4) {
        _sendMockReply(recipientId);
      }
      
      return true;
    } else {
      // Store as pending
      _pendingMessages.add(message);
      notifyListeners();
      
      return false;
    }
  }
  
  // Try to send pending messages
  Future<int> sendPendingMessages() async {
    if (_pendingMessages.isEmpty) {
      return 0;
    }
    
    // Simulate delay
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(700)));
    
    // Count how many were sent
    int sentCount = 0;
    
    // Try to send each pending message
    final List<MeshMessage> stillPending = [];
    
    for (final message in _pendingMessages) {
      final peerIndex = _peers.indexWhere((p) => p.id == message.recipientId);
      
      // If peer is connected, try to send the message
      if (peerIndex != -1 && _peers[peerIndex].isConnected && _random.nextDouble() > 0.2) {
        // Successfully delivered
        _messageReceivedController.add(message);
        sentCount++;
      } else {
        // Keep as pending
        stillPending.add(message);
      }
    }
    
    // Update pending messages
    _pendingMessages.clear();
    _pendingMessages.addAll(stillPending);
    
    notifyListeners();
    return sentCount;
  }
  
  // Helper to create and receive a mock reply
  void _sendMockReply(String senderId) {
    // Find the peer
    final peerIndex = _peers.indexWhere((p) => p.id == senderId);
    if (peerIndex == -1) {
      return;
    }
    
    // Wait a bit before sending the reply
    Future.delayed(Duration(seconds: 1 + _random.nextInt(3)), () {
      final replies = [
        'Got your message!',
        'Thanks for connecting.',
        'I received your data.',
        'How\'s the mesh network working for you?',
        'Signal strength is good on my end.',
        'Let me know if you receive this.',
      ];
      
      final replyMessage = MeshMessage(
        id: _generateRandomId(),
        senderId: senderId,
        recipientId: _localPeer.id,
        content: replies[_random.nextInt(replies.length)],
        isEncrypted: true,
      );
      
      _messageReceivedController.add(replyMessage);
    });
  }
  
  // Generate a random ID for peers or messages
  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      List.generate(12, (index) => chars.codeUnitAt(_random.nextInt(chars.length)))
    );
  }
  
  // Generate a random name for mock peers
  String _generateRandomName() {
    final firstNames = ['Alex', 'Sam', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Quinn', 'Skyler', 'Dakota'];
    return firstNames[_random.nextInt(firstNames.length)];
  }
  
  // Generate a random public key for mock peers
  String _generateRandomKey() {
    final keyData = List<int>.generate(32, (i) => _random.nextInt(256));
    return 'pk_' + keyData.map((e) => e.toRadixString(16).padLeft(2, '0')).join('').substring(0, 16);
  }
  
  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _connectionTimer?.cancel();
    _peerDiscoveredController.close();
    _messageReceivedController.close();
    super.dispose();
  }
} 