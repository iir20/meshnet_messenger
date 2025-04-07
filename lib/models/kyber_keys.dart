/// Represents a pair of post-quantum cryptographic keys
class KyberKeys {
  /// Base64 encoded private key
  final String privateKey;
  
  /// Base64 encoded public key 
  final String publicKey;
  
  const KyberKeys({
    required this.privateKey,
    required this.publicKey,
  });
  
  @override
  String toString() {
    return 'KyberKeys(publicKey: ${publicKey.substring(0, 10)}...)';
  }
} 