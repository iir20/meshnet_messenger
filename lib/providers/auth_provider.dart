import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:secure_mesh_messenger/models/user.dart';
import 'package:secure_mesh_messenger/services/crypto_service.dart';
import 'package:secure_mesh_messenger/services/secure_storage_service.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:uuid/uuid.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String _error = '';
  bool _biometricEnabled = false;
  final Map<String, bool> _onlineUsers = {};
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String get error => _error;
  bool get biometricEnabled => _biometricEnabled;
  
  // Constructor
  AuthProvider() {
    _init();
  }
  
  // Initialize the provider
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Open user box
      await Hive.openBox(HiveBoxNames.user);
      
      // Check if user exists
      final userBox = Hive.box(HiveBoxNames.user);
      final userData = userBox.get('current_user');
      
      if (userData != null) {
        _currentUser = User.fromJson(Map<String, dynamic>.from(userData));
        _isAuthenticated = true;
        
        // Load biometric setting
        _biometricEnabled = userBox.get('biometric_enabled', defaultValue: false);
      }
    } catch (e) {
      _error = 'Failed to initialize: $e';
    } finally {
      _isLoading = false;
    notifyListeners();
  }
  }
  
  // Register a new user
  Future<bool> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Check if username is available
      // In a real app, this would check with a server
      final userBox = Hive.box(HiveBoxNames.user);
      
      // Generate keys for the user
      final cryptoService = CryptoService();
      final keyPair = await cryptoService.generateKeyPair();
      
      // Create a new user
      final user = User(
        id: const Uuid().v4(),
        username: username,
        displayName: displayName,
        publicKey: keyPair.publicKey,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Store private key in secure storage
      final secureStorage = SecureStorageService();
      await secureStorage.savePrivateKey(user.id, keyPair.privateKey);
      
      // Hash the password
      final salt = cryptoService.generateSalt();
      final hashedPassword = await cryptoService.hashPassword(password, salt);
      
      // Store user and credentials
      await userBox.put('current_user', user.toJson());
      await userBox.put('credentials', {
        'salt': base64Encode(salt),
        'password_hash': hashedPassword,
      });
      
      _currentUser = user;
      _isAuthenticated = true;
      
      // Save some mock users for development
      await _createMockUsers();
      
      return true;
    } catch (e) {
      _error = 'Registration failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Login the user
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final userBox = Hive.box(HiveBoxNames.user);
      final userData = userBox.get('current_user');
      
      if (userData == null) {
        _error = 'User not found';
        return false;
      }
      
      final user = User.fromJson(Map<String, dynamic>.from(userData));
      
      // Verify username
      if (user.username != username) {
        _error = 'Invalid username or password';
        return false;
      }
      
      // Get stored credentials
      final credentials = userBox.get('credentials');
      if (credentials == null) {
        _error = 'Credentials not found';
        return false;
      }
      
      // Verify password
      final salt = base64Decode(credentials['salt']);
      final storedHash = credentials['password_hash'];
      
      final cryptoService = CryptoService();
      final providedHash = await cryptoService.hashPassword(password, salt);
      
      if (providedHash != storedHash) {
        _error = 'Invalid username or password';
        return false;
      }
      
      _currentUser = user;
      _isAuthenticated = true;
      
      return true;
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Logout the user
  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
  
  // Check if a user is online
  bool isUserOnline(String userId) {
    return _onlineUsers[userId] ?? false;
  }
  
  // Update a user's online status
  void updateUserOnlineStatus(String userId, bool isOnline) {
    _onlineUsers[userId] = isOnline;
    notifyListeners();
  }
  
  // Toggle biometric authentication
  Future<void> toggleBiometricAuth(bool enabled) async {
    _biometricEnabled = enabled;
    
    final userBox = Hive.box(HiveBoxNames.user);
    await userBox.put('biometric_enabled', enabled);
    
    notifyListeners();
  }
  
  // Create mock users for development
  Future<void> _createMockUsers() async {
    final usersBox = await Hive.openBox(HiveBoxNames.contacts);
    
    if (usersBox.isEmpty) {
      final random = Random();
      
      final avatarUrls = [
        'https://randomuser.me/api/portraits/women/8.jpg',
        'https://randomuser.me/api/portraits/men/32.jpg',
        'https://randomuser.me/api/portraits/women/68.jpg',
        'https://randomuser.me/api/portraits/men/4.jpg',
        'https://randomuser.me/api/portraits/women/65.jpg',
      ];
      
      final users = [
        User(
          id: const Uuid().v4(),
          username: 'alice',
          displayName: 'Alice Smith',
          avatarUrl: avatarUrls[0],
          isOnline: random.nextBool(),
          lastSeen: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
          publicKey: 'mock_public_key_1',
          isVerified: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        User(
          id: const Uuid().v4(),
          username: 'bob',
          displayName: 'Bob Johnson',
          avatarUrl: avatarUrls[1],
          isOnline: random.nextBool(),
          lastSeen: DateTime.now().subtract(Duration(hours: random.nextInt(5))),
          publicKey: 'mock_public_key_2',
          isVerified: true,
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        User(
          id: const Uuid().v4(),
          username: 'carol',
          displayName: 'Carol Williams',
          avatarUrl: avatarUrls[2],
          isOnline: random.nextBool(),
          lastSeen: DateTime.now().subtract(Duration(minutes: random.nextInt(120))),
          publicKey: 'mock_public_key_3',
          isVerified: false,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        User(
          id: const Uuid().v4(),
          username: 'dave',
          displayName: 'Dave Brown',
          avatarUrl: avatarUrls[3],
          isOnline: random.nextBool(),
          lastSeen: DateTime.now().subtract(Duration(days: random.nextInt(2))),
          publicKey: 'mock_public_key_4',
          isVerified: false,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        User(
          id: const Uuid().v4(),
          username: 'eve',
          displayName: 'Eve Miller',
          avatarUrl: avatarUrls[4],
          isOnline: random.nextBool(),
          lastSeen: DateTime.now().subtract(Duration(minutes: random.nextInt(30))),
          publicKey: 'mock_public_key_5',
          isVerified: true,
          isEmergencyContact: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
      
      for (final user in users) {
        await usersBox.put(user.id, user.toJson());
        _onlineUsers[user.id] = user.isOnline;
      }
    }
  }
} 