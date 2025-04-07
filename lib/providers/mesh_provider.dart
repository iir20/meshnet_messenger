import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:secure_mesh_messenger/models/peer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeshProvider extends ChangeNotifier {
  static const String _peersKey = 'discovered_peers';
  static const String _strategy = Strategy.P2P_POINT_TO_POINT;
  static const String _serviceId = 'com.securemesh.messenger';
  
  final Nearby _nearby = Nearby();
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  
  final List<Peer> _discoveredPeers = [];
  final List<Peer> _connectedPeers = [];
  final Map<String, StreamSubscription> _connections = {};
  
  bool _isDiscovering = false;
  bool _isAdvertising = false;
  bool _bluetoothEnabled = false;
  bool _locationEnabled = false;
  
  // Getters
  List<Peer> get discoveredPeers => List.unmodifiable(_discoveredPeers);
  List<Peer> get connectedPeers => List.unmodifiable(_connectedPeers);
  bool get isDiscovering => _isDiscovering;
  bool get isAdvertising => _isAdvertising;
  bool get bluetoothEnabled => _bluetoothEnabled;
  bool get locationEnabled => _locationEnabled;
  
  MeshProvider() {
    _initBluetooth();
    _loadSavedPeers();
  }
  
  // Initialize Bluetooth
  Future<void> _initBluetooth() async {
    _flutterBlue.state.listen((state) {
      _bluetoothEnabled = state == BluetoothState.on;
      notifyListeners();
    });
    
    // Check current state
    try {
      _bluetoothEnabled = await _flutterBlue.isOn;
    } catch (e) {
      _bluetoothEnabled = false;
    }
    
    notifyListeners();
  }
  
  // Load saved peers from SharedPreferences
  Future<void> _loadSavedPeers() async {
    final prefs = await SharedPreferences.getInstance();
    final peersJson = prefs.getStringList(_peersKey) ?? [];
    
    _discoveredPeers.clear();
    for (final peerJson in peersJson) {
      try {
        final peerMap = jsonDecode(peerJson) as Map<String, dynamic>;
        _discoveredPeers.add(Peer.fromJson(peerMap));
      } catch (e) {
        // Skip invalid entries
      }
    }
    
    notifyListeners();
  }
  
  // Save peers to SharedPreferences
  Future<void> _savePeers() async {
    final prefs = await SharedPreferences.getInstance();
    final peersJson = _discoveredPeers.map((peer) => jsonEncode(peer.toJson())).toList();
    await prefs.setStringList(_peersKey, peersJson);
  }
  
  // Start discovering peers
  Future<void> startDiscovery(String userId, String userName) async {
    if (_isDiscovering) return;
    
    try {
      _isDiscovering = true;
      notifyListeners();
      
      bool permissionGranted = await _nearby.askLocationPermission();
      if (!permissionGranted) {
        _isDiscovering = false;
        notifyListeners();
        return;
      }
      
      _locationEnabled = true;
      
      await _nearby.startDiscovery(
        userName,
        _strategy,
        onEndpointFound: (String id, String name, String serviceId) {
          final peer = Peer(
            id: id,
            name: name,
            lastSeen: DateTime.now(),
            isConnected: false,
          );
          
          // Add to discovered peers if not already present
          if (!_discoveredPeers.any((p) => p.id == id)) {
            _discoveredPeers.add(peer);
            _savePeers();
            notifyListeners();
          }
        },
        onEndpointLost: (String id) {
          // Mark peer as disconnected
          final index = _discoveredPeers.indexWhere((p) => p.id == id);
          if (index >= 0) {
            _discoveredPeers[index] = _discoveredPeers[index].copyWith(isConnected: false);
            notifyListeners();
          }
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      _isDiscovering = false;
      notifyListeners();
    }
  }
  
  // Stop discovering peers
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    
    try {
      await _nearby.stopDiscovery();
      _isDiscovering = false;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
  
  // Start advertising presence to other peers
  Future<void> startAdvertising(String userId, String userName) async {
    if (_isAdvertising) return;
    
    try {
      _isAdvertising = true;
      notifyListeners();
      
      bool permissionGranted = await _nearby.askLocationPermission();
      if (!permissionGranted) {
        _isAdvertising = false;
        notifyListeners();
        return;
      }
      
      _locationEnabled = true;
      
      await _nearby.startAdvertising(
        userName,
        _strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          // Auto-accept connections
          _nearby.acceptConnection(
            id,
            onPayloadReceived: (String id, Payload payload) {
              _handlePayload(id, payload);
            },
            onPayloadTransferUpdate: (String id, PayloadTransferUpdate update) {
              // Handle payload transfer updates
            },
          );
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            // Find the peer in discovered peers
            final index = _discoveredPeers.indexWhere((p) => p.id == id);
            if (index >= 0) {
              _discoveredPeers[index] = _discoveredPeers[index].copyWith(isConnected: true);
              
              // Add to connected peers if not already there
              if (!_connectedPeers.any((p) => p.id == id)) {
                _connectedPeers.add(_discoveredPeers[index]);
              }
              
              notifyListeners();
            }
          }
        },
        onDisconnected: (String id) {
          // Remove from connected peers
          _connectedPeers.removeWhere((p) => p.id == id);
          
          // Update status in discovered peers
          final index = _discoveredPeers.indexWhere((p) => p.id == id);
          if (index >= 0) {
            _discoveredPeers[index] = _discoveredPeers[index].copyWith(isConnected: false);
          }
          
          notifyListeners();
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      _isAdvertising = false;
      notifyListeners();
    }
  }
  
  // Stop advertising
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    
    try {
      await _nearby.stopAdvertising();
      _isAdvertising = false;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
  
  // Connect to a specific peer
  Future<bool> connectToPeer(Peer peer) async {
    try {
      await _nearby.requestConnection(
        peer.name,
        peer.id,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          _nearby.acceptConnection(
            id,
            onPayloadReceived: (String id, Payload payload) {
              _handlePayload(id, payload);
            },
            onPayloadTransferUpdate: (String id, PayloadTransferUpdate update) {
              // Handle payload transfer updates
            },
          );
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            // Update peer status
            final index = _discoveredPeers.indexWhere((p) => p.id == id);
            if (index >= 0) {
              _discoveredPeers[index] = _discoveredPeers[index].copyWith(isConnected: true);
              
              // Add to connected peers
              if (!_connectedPeers.any((p) => p.id == id)) {
                _connectedPeers.add(_discoveredPeers[index]);
              }
              
              notifyListeners();
            }
          }
        },
        onDisconnected: (String id) {
          // Handle disconnection
          _connectedPeers.removeWhere((p) => p.id == id);
          
          final index = _discoveredPeers.indexWhere((p) => p.id == id);
          if (index >= 0) {
            _discoveredPeers[index] = _discoveredPeers[index].copyWith(isConnected: false);
          }
          
          notifyListeners();
        },
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Disconnect from a peer
  Future<void> disconnectFromPeer(String peerId) async {
    try {
      await _nearby.disconnectFromEndpoint(peerId);
      
      // Update peer status
      _connectedPeers.removeWhere((p) => p.id == peerId);
      
      final index = _discoveredPeers.indexWhere((p) => p.id == peerId);
      if (index >= 0) {
        _discoveredPeers[index] = _discoveredPeers[index].copyWith(isConnected: false);
      }
      
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
  
  // Send data to a peer
  Future<bool> sendToPeer(String peerId, Uint8List data) async {
    try {
      await _nearby.sendBytesPayload(peerId, data);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Handle incoming data payload
  void _handlePayload(String id, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      // Process the bytes data
      // This would typically dispatch to a message handler
      
      // Update last seen timestamp
      final index = _discoveredPeers.indexWhere((p) => p.id == id);
      if (index >= 0) {
        _discoveredPeers[index] = _discoveredPeers[index].copyWith(
          lastSeen: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }
  
  // Cleanup resources
  @override
  void dispose() {
    stopDiscovery();
    stopAdvertising();
    
    for (final subscription in _connections.values) {
      subscription.cancel();
    }
    _connections.clear();
    
    super.dispose();
  }
} 