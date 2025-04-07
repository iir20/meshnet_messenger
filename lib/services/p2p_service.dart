import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// This is a simulation of LibP2P functionality since we can't directly
// call Rust LibP2P from Flutter without a proper FFI bridge
// In a real implementation, this would use FFI to call Rust LibP2P

class Peer {
  final String id;
  final String name;
  final int trustScore;
  final bool isOnline;
  final DateTime lastSeen;
  final List<String> supportedProtocols;
  final String? address;

  Peer({
    required this.id,
    required this.name,
    required this.trustScore,
    required this.isOnline,
    required this.lastSeen,
    required this.supportedProtocols,
    this.address,
  });

  factory Peer.fromJson(Map<String, dynamic> json) {
    return Peer(
      id: json['id'],
      name: json['name'],
      trustScore: json['trustScore'],
      isOnline: json['isOnline'],
      lastSeen: DateTime.parse(json['lastSeen']),
      supportedProtocols: List<String>.from(json['supportedProtocols']),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'trustScore': trustScore,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'supportedProtocols': supportedProtocols,
      'address': address,
    };
  }
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isEncrypted;
  final bool isDelivered;
  final bool isRead;
  final int priority;
  final List<String> routingPath;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isEncrypted,
    this.isDelivered = false,
    this.isRead = false,
    this.priority = 1,
    this.routingPath = const [],
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isEncrypted: json['isEncrypted'],
      isDelivered: json['isDelivered'],
      isRead: json['isRead'],
      priority: json['priority'] ?? 1,
      routingPath: List<String>.from(json['routingPath'] ?? []),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isEncrypted': isEncrypted,
      'isDelivered': isDelivered,
      'isRead': isRead,
      'priority': priority,
      'routingPath': routingPath,
      'metadata': metadata,
    };
  }
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

enum NetworkType {
  wifi,
  bluetooth,
  cellular,
  offline,
}

class P2PService extends ChangeNotifier {
  final String _peerId = const Uuid().v4();
  String _peerName = 'Anonymous';
  ConnectionState _connectionState = ConnectionState.disconnected;
  NetworkType _networkType = NetworkType.offline;
  final List<Peer> _knownPeers = [];
  final List<Message> _messages = [];
  final List<Message> _pendingMessages = [];
  final Map<String, WebSocketChannel> _peerConnections = {};
  final Map<String, int> _peerTrustScores = {};
  
  Timer? _discoveryTimer;
  Timer? _heartbeatTimer;
  Timer? _retryTimer;
  Timer? _storeForwardTimer;
  
  final _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Getters
  String get peerId => _peerId;
  String get peerName => _peerName;
  ConnectionState get connectionState => _connectionState;
  NetworkType get networkType => _networkType;
  List<Peer> get knownPeers => List.unmodifiable(_knownPeers);
  List<Message> get messages => List.unmodifiable(_messages);
  List<Message> get pendingMessages => List.unmodifiable(_pendingMessages);
  
  P2PService() {
    _init();
  }
  
  Future<void> _init() async {
    // Load stored data
    await _loadStoredData();
    
    // Monitor connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateNetworkType);
    
    // Initial connectivity check
    _updateNetworkType(await _connectivity.checkConnectivity());
    
    // Start timers for network operations
    _startTimers();
  }
  
  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load peer name
    _peerName = prefs.getString('peerName') ?? 'User-${_peerId.substring(0, 6)}';
    
    // Load known peers
    final storedPeers = prefs.getStringList('knownPeers') ?? [];
    for (final peerJson in storedPeers) {
      try {
        final peer = Peer.fromJson(jsonDecode(peerJson));
        _knownPeers.add(peer);
        _peerTrustScores[peer.id] = peer.trustScore;
      } catch (e) {
        print('Error loading peer: $e');
      }
    }
    
    // Load pending messages
    final storedMessages = prefs.getStringList('pendingMessages') ?? [];
    for (final messageJson in storedMessages) {
      try {
        final message = Message.fromJson(jsonDecode(messageJson));
        _pendingMessages.add(message);
      } catch (e) {
        print('Error loading message: $e');
      }
    }
    
    notifyListeners();
  }
  
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save peer name
    await prefs.setString('peerName', _peerName);
    
    // Save known peers
    final peerJsonList = _knownPeers.map((peer) => jsonEncode(peer.toJson())).toList();
    await prefs.setStringList('knownPeers', peerJsonList);
    
    // Save pending messages
    final messageJsonList = _pendingMessages.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList('pendingMessages', messageJsonList);
  }
  
  void _startTimers() {
    // Peer discovery every 30 seconds
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 30), (_) => _discoverPeers());
    
    // Connection heartbeats every 10 seconds
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) => _sendHeartbeats());
    
    // Retry connections every minute
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) => _retryConnections());
    
    // Store and forward messages every 2 minutes
    _storeForwardTimer?.cancel();
    _storeForwardTimer = Timer.periodic(const Duration(minutes: 2), (_) => _processPendingMessages());
  }
  
  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _heartbeatTimer?.cancel();
    _retryTimer?.cancel();
    _storeForwardTimer?.cancel();
    _connectivitySubscription?.cancel();
    
    // Close all connections
    for (final connection in _peerConnections.values) {
      connection.sink.close();
    }
    
    super.dispose();
  }
  
  // Update network type based on connectivity
  Future<void> _updateNetworkType(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        _networkType = NetworkType.wifi;
        _connectToNetwork();
        break;
      case ConnectivityResult.mobile:
        _networkType = NetworkType.cellular;
        _connectToNetwork();
        break;
      case ConnectivityResult.bluetooth:
        _networkType = NetworkType.bluetooth;
        _connectToNetwork();
        break;
      default:
        _networkType = NetworkType.offline;
        _setConnectionState(ConnectionState.disconnected);
    }
    
    notifyListeners();
  }
  
  // Connect to the mesh network
  Future<void> _connectToNetwork() async {
    if (_connectionState == ConnectionState.connected) {
      return;
    }
    
    _setConnectionState(ConnectionState.connecting);
    
    // Simulate connection process
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real implementation, this would use LibP2P to connect to the network
    final random = Random();
    if (random.nextDouble() > 0.2) { // 80% success rate
      _setConnectionState(ConnectionState.connected);
      _discoverPeers();
    } else {
      _setConnectionState(ConnectionState.error);
    }
  }
  
  void _setConnectionState(ConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }
  
  // Discover peers on the network
  Future<void> _discoverPeers() async {
    if (_connectionState != ConnectionState.connected) {
      return;
    }
    
    // In a real implementation, this would use LibP2P's peer discovery
    // For simulation, we'll create some random peers
    
    final random = Random();
    final numPeers = random.nextInt(5) + 1;
    
    for (int i = 0; i < numPeers; i++) {
      final peerId = 'peer-${const Uuid().v4()}';
      
      // Skip if we already know this peer
      if (_knownPeers.any((p) => p.id == peerId)) {
        continue;
      }
      
      final peer = Peer(
        id: peerId,
        name: 'User-${peerId.substring(0, 6)}',
        trustScore: random.nextInt(91) + 10, // 10-100
        isOnline: random.nextBool(),
        lastSeen: DateTime.now(),
        supportedProtocols: ['meshnet/1.0', 'libp2p/1.0'],
        address: 'mesh://$peerId',
      );
      
      _knownPeers.add(peer);
      _peerTrustScores[peer.id] = peer.trustScore;
      
      // Simulate connection to online peers
      if (peer.isOnline) {
        _connectToPeer(peer);
      }
    }
    
    await _saveData();
    notifyListeners();
  }
  
  // Connect to a specific peer
  Future<bool> _connectToPeer(Peer peer) async {
    if (_peerConnections.containsKey(peer.id)) {
      return true; // Already connected
    }
    
    // Simulate connection
    // In a real implementation, this would establish a LibP2P connection
    
    try {
      // For simulation purposes only - in a real app we would use actual P2P connections
      // This is just to simulate the WebSocket channel for our example
      final uri = Uri.parse('wss://fakeconnection.meshnet.example.com/${peer.id}');
      final channel = WebSocketChannel.connect(uri);
      
      _peerConnections[peer.id] = channel;
      
      // Listen for messages from this peer
      channel.stream.listen(
        (data) => _handlePeerMessage(peer.id, data),
        onError: (error) => _handlePeerError(peer.id, error),
        onDone: () => _handlePeerDisconnection(peer.id),
      );
      
      // Update peer status
      final index = _knownPeers.indexWhere((p) => p.id == peer.id);
      if (index >= 0) {
        _knownPeers[index] = Peer(
          id: peer.id,
          name: peer.name,
          trustScore: peer.trustScore,
          isOnline: true,
          lastSeen: DateTime.now(),
          supportedProtocols: peer.supportedProtocols,
          address: peer.address,
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      print('Error connecting to peer ${peer.id}: $e');
      return false;
    }
  }
  
  // Send heartbeats to connected peers
  void _sendHeartbeats() {
    if (_connectionState != ConnectionState.connected) {
      return;
    }
    
    for (final peerId in _peerConnections.keys) {
      final heartbeat = {
        'type': 'heartbeat',
        'from': _peerId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      try {
        _peerConnections[peerId]?.sink.add(jsonEncode(heartbeat));
      } catch (e) {
        print('Error sending heartbeat to $peerId: $e');
      }
    }
  }
  
  // Retry connections to offline peers
  void _retryConnections() {
    if (_connectionState != ConnectionState.connected) {
      return;
    }
    
    for (final peer in _knownPeers) {
      if (!peer.isOnline && !_peerConnections.containsKey(peer.id)) {
        _connectToPeer(peer);
      }
    }
  }
  
  // Handle messages from peers
  void _handlePeerMessage(String peerId, dynamic data) {
    try {
      final message = jsonDecode(data as String);
      final type = message['type'];
      
      switch (type) {
        case 'message':
          _processIncomingMessage(message);
          break;
        case 'heartbeat':
          _updatePeerLastSeen(peerId);
          break;
        case 'discovery':
          _handleDiscoveryResponse(message);
          break;
      }
    } catch (e) {
      print('Error handling message from $peerId: $e');
    }
  }
  
  // Update peer's last seen timestamp
  void _updatePeerLastSeen(String peerId) {
    final index = _knownPeers.indexWhere((p) => p.id == peerId);
    if (index >= 0) {
      _knownPeers[index] = Peer(
        id: _knownPeers[index].id,
        name: _knownPeers[index].name,
        trustScore: _knownPeers[index].trustScore,
        isOnline: true,
        lastSeen: DateTime.now(),
        supportedProtocols: _knownPeers[index].supportedProtocols,
        address: _knownPeers[index].address,
      );
      notifyListeners();
    }
  }
  
  // Handle peer discovery responses
  void _handleDiscoveryResponse(Map<String, dynamic> response) {
    final peers = response['peers'] as List;
    for (final peerData in peers) {
      final peer = Peer.fromJson(peerData);
      
      // Add new peer if not already known
      if (!_knownPeers.any((p) => p.id == peer.id)) {
        _knownPeers.add(peer);
        _peerTrustScores[peer.id] = peer.trustScore;
        
        if (peer.isOnline) {
          _connectToPeer(peer);
        }
      }
    }
    
    notifyListeners();
  }
  
  // Handle peer errors
  void _handlePeerError(String peerId, dynamic error) {
    print('Error with peer $peerId: $error');
    _updatePeerStatus(peerId, false);
    _peerConnections.remove(peerId);
  }
  
  // Handle peer disconnections
  void _handlePeerDisconnection(String peerId) {
    _updatePeerStatus(peerId, false);
    _peerConnections.remove(peerId);
  }
  
  // Update a peer's online status
  void _updatePeerStatus(String peerId, bool isOnline) {
    final index = _knownPeers.indexWhere((p) => p.id == peerId);
    if (index >= 0) {
      _knownPeers[index] = Peer(
        id: _knownPeers[index].id,
        name: _knownPeers[index].name,
        trustScore: _knownPeers[index].trustScore,
        isOnline: isOnline,
        lastSeen: isOnline ? DateTime.now() : _knownPeers[index].lastSeen,
        supportedProtocols: _knownPeers[index].supportedProtocols,
        address: _knownPeers[index].address,
      );
      notifyListeners();
    }
  }
  
  // Process incoming messages
  void _processIncomingMessage(Map<String, dynamic> data) {
    final message = Message.fromJson(data['content']);
    
    // Check if the message is for us
    if (message.receiverId == _peerId) {
      // Add to messages list
      _messages.add(message);
      
      // Update sender's trust score (increment for successful delivery)
      _updateTrustScore(message.senderId, 1);
      
      notifyListeners();
    } else {
      // This message is for someone else, store and forward
      _forwardMessage(message);
    }
  }
  
  // Forward a message to its intended recipient
  void _forwardMessage(Message message) {
    // Check if we know the recipient
    final recipientPeer = _knownPeers.firstWhere(
      (p) => p.id == message.receiverId,
      orElse: () => Peer(
        id: '',
        name: '',
        trustScore: 0,
        isOnline: false,
        lastSeen: DateTime.now(),
        supportedProtocols: [],
      ),
    );
    
    // If recipient is unknown or offline, add to pending messages
    if (recipientPeer.id.isEmpty || !recipientPeer.isOnline) {
      if (!_pendingMessages.any((m) => m.id == message.id)) {
        // Add this node to the routing path
        final updatedPath = List<String>.from(message.routingPath)..add(_peerId);
        
        final updatedMessage = Message(
          id: message.id,
          senderId: message.senderId,
          receiverId: message.receiverId,
          content: message.content,
          timestamp: message.timestamp,
          isEncrypted: message.isEncrypted,
          isDelivered: message.isDelivered,
          isRead: message.isRead,
          priority: message.priority,
          routingPath: updatedPath,
          metadata: message.metadata,
        );
        
        _pendingMessages.add(updatedMessage);
        _saveData();
        notifyListeners();
      }
      return;
    }
    
    // If recipient is online and connected, forward the message
    if (_peerConnections.containsKey(recipientPeer.id)) {
      // Add this node to the routing path
      final updatedPath = List<String>.from(message.routingPath)..add(_peerId);
      
      final updatedMessage = Message(
        id: message.id,
        senderId: message.senderId,
        receiverId: message.receiverId,
        content: message.content,
        timestamp: message.timestamp,
        isEncrypted: message.isEncrypted,
        isDelivered: message.isDelivered,
        isRead: message.isRead,
        priority: message.priority,
        routingPath: updatedPath,
        metadata: message.metadata,
      );
      
      final messagePacket = {
        'type': 'message',
        'from': _peerId,
        'to': recipientPeer.id,
        'content': updatedMessage.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      try {
        _peerConnections[recipientPeer.id]?.sink.add(jsonEncode(messagePacket));
        _updateTrustScore(message.senderId, 1); // Reward for successful forward
      } catch (e) {
        print('Error forwarding message to ${recipientPeer.id}: $e');
        _pendingMessages.add(message);
        _saveData();
      }
    } else {
      // Try to connect to the recipient
      _connectToPeer(recipientPeer).then((success) {
        if (success) {
          _forwardMessage(message); // Retry forwarding
        } else {
          // Store for later
          _pendingMessages.add(message);
          _saveData();
        }
      });
    }
  }
  
  // Process pending messages
  void _processPendingMessages() {
    if (_connectionState != ConnectionState.connected || _pendingMessages.isEmpty) {
      return;
    }
    
    // Sort pending messages by priority and timestamp
    _pendingMessages.sort((a, b) {
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority); // Higher priority first
      }
      return a.timestamp.compareTo(b.timestamp); // Older messages first
    });
    
    // Try to send each pending message
    final List<Message> processedMessages = [];
    
    for (final message in _pendingMessages) {
      final recipientPeer = _knownPeers.firstWhere(
        (p) => p.id == message.receiverId,
        orElse: () => Peer(
          id: '',
          name: '',
          trustScore: 0,
          isOnline: false,
          lastSeen: DateTime.now(),
          supportedProtocols: [],
        ),
      );
      
      // If we know the recipient and they're online, try to forward
      if (recipientPeer.id.isNotEmpty && recipientPeer.isOnline) {
        // Try to connect if not already connected
        if (!_peerConnections.containsKey(recipientPeer.id)) {
          _connectToPeer(recipientPeer);
        }
        
        // If connected, forward the message
        if (_peerConnections.containsKey(recipientPeer.id)) {
          final messagePacket = {
            'type': 'message',
            'from': _peerId,
            'to': recipientPeer.id,
            'content': message.toJson(),
            'timestamp': DateTime.now().toIso8601String(),
          };
          
          try {
            _peerConnections[recipientPeer.id]?.sink.add(jsonEncode(messagePacket));
            processedMessages.add(message);
          } catch (e) {
            print('Error sending pending message to ${recipientPeer.id}: $e');
          }
        }
      } else {
        // Try to forward to other peers who might know the recipient
        _knownPeers.where((p) => p.isOnline && p.trustScore > 50).forEach((peer) {
          if (_peerConnections.containsKey(peer.id)) {
            final forwardPacket = {
              'type': 'forward_request',
              'from': _peerId,
              'to': peer.id,
              'target': message.receiverId,
              'content': message.toJson(),
              'timestamp': DateTime.now().toIso8601String(),
            };
            
            try {
              _peerConnections[peer.id]?.sink.add(jsonEncode(forwardPacket));
              // Don't mark as processed yet, wait for confirmation
            } catch (e) {
              print('Error requesting forward to ${peer.id}: $e');
            }
          }
        });
      }
    }
    
    // Remove processed messages
    _pendingMessages.removeWhere((msg) => processedMessages.any((m) => m.id == msg.id));
    
    if (processedMessages.isNotEmpty) {
      _saveData();
      notifyListeners();
    }
  }
  
  // Update a peer's trust score
  void _updateTrustScore(String peerId, int delta) {
    if (!_peerTrustScores.containsKey(peerId)) {
      _peerTrustScores[peerId] = 50; // Default trust score
    }
    
    _peerTrustScores[peerId] = (_peerTrustScores[peerId]! + delta).clamp(0, 100);
    
    final index = _knownPeers.indexWhere((p) => p.id == peerId);
    if (index >= 0) {
      _knownPeers[index] = Peer(
        id: _knownPeers[index].id,
        name: _knownPeers[index].name,
        trustScore: _peerTrustScores[peerId]!,
        isOnline: _knownPeers[index].isOnline,
        lastSeen: _knownPeers[index].lastSeen,
        supportedProtocols: _knownPeers[index].supportedProtocols,
        address: _knownPeers[index].address,
      );
    }
  }
  
  // Public API methods
  
  // Set peer name
  Future<void> setPeerName(String name) async {
    _peerName = name;
    await _saveData();
    notifyListeners();
  }
  
  // Connect to the network
  Future<void> connect() async {
    await _connectToNetwork();
  }
  
  // Disconnect from the network
  void disconnect() {
    _setConnectionState(ConnectionState.disconnected);
    
    // Close all connections
    for (final connection in _peerConnections.values) {
      connection.sink.close();
    }
    _peerConnections.clear();
    
    // Update peer statuses
    for (int i = 0; i < _knownPeers.length; i++) {
      _knownPeers[i] = Peer(
        id: _knownPeers[i].id,
        name: _knownPeers[i].name,
        trustScore: _knownPeers[i].trustScore,
        isOnline: false,
        lastSeen: _knownPeers[i].lastSeen,
        supportedProtocols: _knownPeers[i].supportedProtocols,
        address: _knownPeers[i].address,
      );
    }
    
    notifyListeners();
  }
  
  // Send a message to a peer
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
    required bool isEncrypted,
    int priority = 1,
    Map<String, dynamic>? metadata,
  }) async {
    if (_connectionState != ConnectionState.connected) {
      return false;
    }
    
    final message = Message(
      id: const Uuid().v4(),
      senderId: _peerId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isEncrypted: isEncrypted,
      priority: priority,
      routingPath: [_peerId],
      metadata: metadata,
    );
    
    // Find the recipient peer
    final recipientPeer = _knownPeers.firstWhere(
      (p) => p.id == receiverId,
      orElse: () => Peer(
        id: '',
        name: '',
        trustScore: 0,
        isOnline: false,
        lastSeen: DateTime.now(),
        supportedProtocols: [],
      ),
    );
    
    // If recipient is unknown or offline, add to pending messages
    if (recipientPeer.id.isEmpty || !recipientPeer.isOnline) {
      _pendingMessages.add(message);
      _saveData();
      notifyListeners();
      return true; // Message will be sent when possible
    }
    
    // If recipient is online and connected, send directly
    if (_peerConnections.containsKey(receiverId)) {
      final messagePacket = {
        'type': 'message',
        'from': _peerId,
        'to': receiverId,
        'content': message.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      try {
        _peerConnections[receiverId]?.sink.add(jsonEncode(messagePacket));
        _messages.add(message); // Add to sent messages
        notifyListeners();
        return true;
      } catch (e) {
        print('Error sending message: $e');
        _pendingMessages.add(message);
        _saveData();
        notifyListeners();
        return false;
      }
    } else {
      // Try to connect to the recipient
      final success = await _connectToPeer(recipientPeer);
      if (success) {
        return sendMessage(
          receiverId: receiverId,
          content: content,
          isEncrypted: isEncrypted,
          priority: priority,
          metadata: metadata,
        );
      } else {
        // Store for later
        _pendingMessages.add(message);
        _saveData();
        notifyListeners();
        return true; // Message will be sent when possible
      }
    }
  }
  
  // Get messages for a specific peer
  List<Message> getMessagesForPeer(String peerId) {
    return _messages
        .where((msg) => msg.senderId == peerId || msg.receiverId == peerId)
        .toList();
  }
  
  // Find peers by partial name
  List<Peer> findPeersByName(String nameFragment) {
    return _knownPeers
        .where((peer) => peer.name.toLowerCase().contains(nameFragment.toLowerCase()))
        .toList();
  }
  
  // Get peer by ID
  Peer? getPeerById(String peerId) {
    try {
      return _knownPeers.firstWhere((peer) => peer.id == peerId);
    } catch (e) {
      return null;
    }
  }
} 