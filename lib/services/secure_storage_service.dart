import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Private keys
  static const String _privateKeyPrefix = 'private_key_';
  
  // Biometric authentication
  static const String _biometricEnabledKey = 'biometric_enabled';
  
  // Save a private key
  Future<void> savePrivateKey(String userId, String privateKey) async {
    await _secureStorage.write(key: '$_privateKeyPrefix$userId', value: privateKey);
  }
  
  // Get a private key
  Future<String?> getPrivateKey(String userId) async {
    return await _secureStorage.read(key: '$_privateKeyPrefix$userId');
  }
  
  // Delete a private key
  Future<void> deletePrivateKey(String userId) async {
    await _secureStorage.delete(key: '$_privateKeyPrefix$userId');
  }
  
  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }
  
  // Set biometric authentication enabled/disabled
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
  }
  
  // Save a secure value
  Future<void> saveSecureValue(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  // Get a secure value
  Future<String?> getSecureValue(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  // Delete a secure value
  Future<void> deleteSecureValue(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  // Delete all stored values
  Future<void> deleteAllSecureValues() async {
    await _secureStorage.deleteAll();
  }
} 