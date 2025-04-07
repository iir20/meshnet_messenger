import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:uuid/uuid.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuth();
  final _uuid = const Uuid();
  
  // Encryption keys
  late RSAPrivateKey _privateKey;
  late RSAPublicKey _publicKey;
  late Uint8List _symmetricKey;
  late Uint8List _hmacKey;
  
  // Security settings
  bool _isInitialized = false;
  bool _isBiometricEnabled = false;
  int _failedAttempts = 0;
  DateTime? _lastFailedAttempt;
  final int _maxFailedAttempts = 5;
  final Duration _lockoutDuration = const Duration(minutes: 30);
  
  // Initialize security service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Generate or load RSA keys
      await _initializeRSAKeys();
      
      // Generate or load symmetric key
      await _initializeSymmetricKey();
      
      // Generate or load HMAC key
      await _initializeHMACKey();
      
      // Check biometric availability
      _isBiometricEnabled = await _localAuth.canCheckBiometrics;
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Security initialization failed: $e');
      rethrow;
    }
  }
  
  // Initialize RSA keys
  Future<void> _initializeRSAKeys() async {
    try {
      // Try to load existing keys
      final privateKeyStr = await _secureStorage.read(key: 'private_key');
      final publicKeyStr = await _secureStorage.read(key: 'public_key');
      
      if (privateKeyStr != null && publicKeyStr != null) {
        _privateKey = _decodeRSAPrivateKey(privateKeyStr);
        _publicKey = _decodeRSAPublicKey(publicKeyStr);
      } else {
        // Generate new RSA keys
        final keyGen = RSAKeyGenerator()
          ..init(ParametersWithRandom(
            RSAKeyGeneratorParameters(
              BigInt.parse('65537'),
              4096, // 4096-bit RSA
              64,
            ),
            FortunaRandom()..seed(KeyParameter(Uint8List(32))),
          ));
        
        final keyPair = keyGen.generateKeyPair();
        _privateKey = keyPair.privateKey as RSAPrivateKey;
        _publicKey = keyPair.publicKey as RSAPublicKey;
        
        // Store keys
        await _secureStorage.write(
          key: 'private_key',
          value: _encodeRSAPrivateKey(_privateKey),
        );
        await _secureStorage.write(
          key: 'public_key',
          value: _encodeRSAPublicKey(_publicKey),
        );
      }
    } catch (e) {
      debugPrint('RSA key initialization failed: $e');
      rethrow;
    }
  }
  
  // Initialize symmetric key
  Future<void> _initializeSymmetricKey() async {
    try {
      final keyStr = await _secureStorage.read(key: 'symmetric_key');
      
      if (keyStr != null) {
        _symmetricKey = base64Decode(keyStr);
      } else {
        // Generate new symmetric key
        final random = FortunaRandom()..seed(KeyParameter(Uint8List(32)));
        _symmetricKey = Uint8List(32);
        random.nextBytes(_symmetricKey);
        
        // Store key
        await _secureStorage.write(
          key: 'symmetric_key',
          value: base64Encode(_symmetricKey),
        );
      }
    } catch (e) {
      debugPrint('Symmetric key initialization failed: $e');
      rethrow;
    }
  }
  
  // Initialize HMAC key
  Future<void> _initializeHMACKey() async {
    try {
      final keyStr = await _secureStorage.read(key: 'hmac_key');
      
      if (keyStr != null) {
        _hmacKey = base64Decode(keyStr);
      } else {
        // Generate new HMAC key
        final random = FortunaRandom()..seed(KeyParameter(Uint8List(32)));
        _hmacKey = Uint8List(64);
        random.nextBytes(_hmacKey);
        
        // Store key
        await _secureStorage.write(
          key: 'hmac_key',
          value: base64Encode(_hmacKey),
        );
      }
    } catch (e) {
      debugPrint('HMAC key initialization failed: $e');
      rethrow;
    }
  }
  
  // Authenticate user
  Future<bool> authenticate() async {
    if (_isLockedOut()) {
      throw SecurityException('Account is temporarily locked. Please try again later.');
    }
    
    try {
      if (_isBiometricEnabled) {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access your messages',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        
        if (didAuthenticate) {
          _resetFailedAttempts();
          return true;
        }
      }
      
      // Fallback to PIN/password if biometric fails
      final storedPin = await _secureStorage.read(key: 'pin');
      if (storedPin != null) {
        // Implement PIN verification logic here
        // For now, we'll just increment failed attempts
        _incrementFailedAttempts();
        return false;
      }
      
      return false;
    } catch (e) {
      _incrementFailedAttempts();
      return false;
    }
  }
  
  // Encrypt message
  Future<String> encryptMessage(String message) async {
    if (!_isInitialized) {
      throw SecurityException('Security service not initialized');
    }
    
    try {
      // Generate random IV
      final random = FortunaRandom()..seed(KeyParameter(Uint8List(32)));
      final iv = Uint8List(16);
      random.nextBytes(iv);
      
      // Encrypt with AES-256-CBC
      final cipher = PaddedBlockCipherImpl(
        PKCS7Padding(),
        CBCBlockCipher(AESEngine()),
      );
      
      cipher.init(
        true,
        ParametersWithIV(
          KeyParameter(_symmetricKey),
          iv,
        ),
      );
      
      final encrypted = cipher.process(Uint8List.fromList(utf8.encode(message)));
      
      // Sign with RSA
      final signer = RSASigner(SHA512Digest(), '0609608648016503040201');
      signer.init(true, PrivateKeyParameter(_privateKey));
      final signature = signer.generateSignature(encrypted);
      
      // Create HMAC
      final hmac = HMac(SHA512Digest(), 64)..init(KeyParameter(_hmacKey));
      hmac.update(encrypted, 0, encrypted.length);
      final mac = hmac.doFinal();
      
      // Combine all components
      final result = {
        'iv': base64Encode(iv),
        'data': base64Encode(encrypted),
        'signature': base64Encode(signature.bytes),
        'mac': base64Encode(mac),
      };
      
      return jsonEncode(result);
    } catch (e) {
      debugPrint('Encryption failed: $e');
      rethrow;
    }
  }
  
  // Decrypt message
  Future<String> decryptMessage(String encryptedMessage) async {
    if (!_isInitialized) {
      throw SecurityException('Security service not initialized');
    }
    
    try {
      final data = jsonDecode(encryptedMessage);
      
      final iv = base64Decode(data['iv']);
      final encrypted = base64Decode(data['data']);
      final signature = base64Decode(data['signature']);
      final mac = base64Decode(data['mac']);
      
      // Verify HMAC
      final hmac = HMac(SHA512Digest(), 64)..init(KeyParameter(_hmacKey));
      hmac.update(encrypted, 0, encrypted.length);
      final calculatedMac = hmac.doFinal();
      
      if (!_constantTimeCompare(mac, calculatedMac)) {
        throw SecurityException('Message integrity check failed');
      }
      
      // Verify signature
      final signer = RSASigner(SHA512Digest(), '0609608648016503040201');
      signer.init(false, PublicKeyParameter(_publicKey));
      
      if (!signer.verifySignature(encrypted, RSASignature(signature))) {
        throw SecurityException('Message signature verification failed');
      }
      
      // Decrypt
      final cipher = PaddedBlockCipherImpl(
        PKCS7Padding(),
        CBCBlockCipher(AESEngine()),
      );
      
      cipher.init(
        false,
        ParametersWithIV(
          KeyParameter(_symmetricKey),
          iv,
        ),
      );
      
      final decrypted = cipher.process(encrypted);
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('Decryption failed: $e');
      rethrow;
    }
  }
  
  // Generate secure random token
  String generateSecureToken() {
    return _uuid.v4();
  }
  
  // Wipe all security data
  Future<void> wipeSecurityData() async {
    try {
      await _secureStorage.deleteAll();
      _isInitialized = false;
      _isBiometricEnabled = false;
      _failedAttempts = 0;
      _lastFailedAttempt = null;
    } catch (e) {
      debugPrint('Failed to wipe security data: $e');
      rethrow;
    }
  }
  
  // Helper methods
  bool _isLockedOut() {
    if (_lastFailedAttempt == null) return false;
    
    final timeSinceLastAttempt = DateTime.now().difference(_lastFailedAttempt!);
    return _failedAttempts >= _maxFailedAttempts && 
           timeSinceLastAttempt < _lockoutDuration;
  }
  
  void _incrementFailedAttempts() {
    _failedAttempts++;
    _lastFailedAttempt = DateTime.now();
  }
  
  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lastFailedAttempt = null;
  }
  
  bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
  
  // Key encoding/decoding
  String _encodeRSAPrivateKey(RSAPrivateKey key) {
    final params = key.parameters;
    return jsonEncode({
      'modulus': key.modulus.toString(),
      'privateExponent': key.privateExponent.toString(),
      'p': params.p.toString(),
      'q': params.q.toString(),
      'dP': params.dP.toString(),
      'dQ': params.dQ.toString(),
      'qInv': params.qInv.toString(),
    });
  }
  
  String _encodeRSAPublicKey(RSAPublicKey key) {
    return jsonEncode({
      'modulus': key.modulus.toString(),
      'exponent': key.exponent.toString(),
    });
  }
  
  RSAPrivateKey _decodeRSAPrivateKey(String encoded) {
    final data = jsonDecode(encoded);
    return RSAPrivateKey(
      BigInt.parse(data['modulus']),
      BigInt.parse(data['privateExponent']),
      RSAPrivateKeyParameters(
        BigInt.parse(data['modulus']),
        BigInt.parse(data['privateExponent']),
        BigInt.parse(data['p']),
        BigInt.parse(data['q']),
        BigInt.parse(data['dP']),
        BigInt.parse(data['dQ']),
        BigInt.parse(data['qInv']),
      ),
    );
  }
  
  RSAPublicKey _decodeRSAPublicKey(String encoded) {
    final data = jsonDecode(encoded);
    return RSAPublicKey(
      BigInt.parse(data['modulus']),
      BigInt.parse(data['exponent']),
    );
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
} 