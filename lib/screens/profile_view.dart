import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/crypto_service.dart';
import '../widgets/holographic_avatar.dart';
import 'dart:math' as math;

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _usernameController = TextEditingController(text: 'Neonix');
  
  // User settings
  bool _isNightModeEnabled = true;
  bool _isEncryptionEnabled = true;
  bool _isPrivacyModeEnabled = false;
  bool _isLocalStorageOnly = true;
  bool _isNotificationsEnabled = true;
  String _selectedEncryptionType = 'AES-256-GCM';
  
  final List<String> _encryptionTypes = [
    'AES-256-GCM',
    'ChaCha20-Poly1305',
    'XChaCha20-Poly1305',
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cryptoService = Provider.of<CryptoService>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black12,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildSecuritySettings(cryptoService),
                    const SizedBox(height: 16),
                    _buildPrivacySettings(),
                    const SizedBox(height: 16),
                    _buildStorageSettings(),
                    const SizedBox(height: 16),
                    _buildAboutSection(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a2e),
                const Color(0xFF16213e),
              ],
            ),
          ),
          child: CustomPaint(
            painter: ProfileBackgroundPainter(
              primaryColor: Colors.purple,
              secondaryColor: Colors.purple.withOpacity(0.2),
              size: MediaQuery.of(context).size,
            ),
            child: Container(),
          ),
        );
      },
    );
  }
  
  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          HolographicAvatar(
            initials: _usernameController.text.isNotEmpty ? _usernameController.text[0].toUpperCase() : 'N',
            size: 130,
            primaryColor: Colors.purple,
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: Add image picker functionality
            },
          ),
          const SizedBox(height: 16),
          _buildUsernameField(),
          const SizedBox(height: 8),
          Text(
            'Mesh ID: 0x7A3B...F91D',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Colors.purple,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Secured',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildUsernameField() {
    return Container(
      width: 200,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _usernameController,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          hintText: 'Username',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSecuritySettings(CryptoService cryptoService) {
    return _buildCard(
      title: 'Security & Encryption',
      icon: Icons.security,
      iconColor: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggleOption(
            title: 'End-to-End Encryption',
            value: _isEncryptionEnabled,
            onChanged: (value) {
              setState(() {
                _isEncryptionEnabled = value;
              });
              HapticFeedback.selectionClick();
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Encryption Algorithm',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: Colors.black87,
                isExpanded: true,
                value: _selectedEncryptionType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                items: _encryptionTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedEncryptionType = newValue;
                    });
                    HapticFeedback.selectionClick();
                    cryptoService.setEncryptionType(newValue);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getEncryptionDescription(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      color: Colors.blue.withOpacity(0.7),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Public Key: ${cryptoService.getPublicKey().substring(0, 20)}...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getEncryptionDescription() {
    switch (_selectedEncryptionType) {
      case 'AES-256-GCM':
        return 'AES-256-GCM is a widely used encryption algorithm that provides authenticated encryption with associated data.';
      case 'ChaCha20-Poly1305':
        return 'ChaCha20-Poly1305 is a symmetric authenticated encryption algorithm that combines the ChaCha20 stream cipher with the Poly1305 message authentication code.';
      case 'XChaCha20-Poly1305':
        return 'XChaCha20-Poly1305 extends ChaCha20-Poly1305 with an extended nonce, making it more suitable for secure communication.';
      default:
        return 'Select an encryption algorithm for end-to-end communication security.';
    }
  }
  
  Widget _buildPrivacySettings() {
    return _buildCard(
      title: 'Privacy',
      icon: Icons.privacy_tip_outlined,
      iconColor: Colors.amber,
      child: Column(
        children: [
          _buildToggleOption(
            title: 'Enhanced Privacy Mode',
            subtitle: 'Hide your online status and typing indicators',
            value: _isPrivacyModeEnabled,
            onChanged: (value) {
              setState(() {
                _isPrivacyModeEnabled = value;
              });
              HapticFeedback.selectionClick();
            },
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            title: 'Notifications',
            subtitle: 'Show message previews and alerts',
            value: _isNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                _isNotificationsEnabled = value;
              });
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStorageSettings() {
    return _buildCard(
      title: 'Storage & Sync',
      icon: Icons.storage_outlined,
      iconColor: Colors.green,
      child: Column(
        children: [
          _buildToggleOption(
            title: 'Local Storage Only',
            subtitle: 'Messages will not be synced between devices',
            value: _isLocalStorageOnly,
            onChanged: (value) {
              setState(() {
                _isLocalStorageOnly = value;
              });
              HapticFeedback.selectionClick();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage Usage',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.27,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '27.4 MB used of 1 GB',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.green.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              // TODO: Implement clear cache functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            label: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAboutSection() {
    return _buildCard(
      title: 'About',
      icon: Icons.info_outline,
      iconColor: Colors.purple,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.code,
              color: Colors.purple.withOpacity(0.7),
            ),
            title: Text(
              'Version',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            subtitle: const Text(
              '1.0.0-beta',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            dense: true,
          ),
          const Divider(
            color: Colors.white24,
          ),
          ListTile(
            leading: Icon(
              Icons.policy_outlined,
              color: Colors.purple.withOpacity(0.7),
            ),
            title: Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
            dense: true,
            onTap: () {
              HapticFeedback.selectionClick();
              // TODO: Navigate to privacy policy
            },
          ),
          const Divider(
            color: Colors.white24,
          ),
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: Colors.purple.withOpacity(0.7),
            ),
            title: Text(
              'Help & Support',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
            dense: true,
            onTap: () {
              HapticFeedback.selectionClick();
              // TODO: Navigate to help & support
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: iconColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Colors.white10,
                height: 1,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildToggleOption({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Colors.blue,
          inactiveThumbColor: Colors.white70,
          inactiveTrackColor: Colors.blueGrey.withOpacity(0.3),
        ),
      ],
    );
  }
}

class ProfileBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Size size;

  ProfileBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Create a path for a flowing background
    final path = Path();
    path.moveTo(0, size.height * 0.7);

    // Create wave-like curve
    for (double i = 0; i <= size.width; i += 10) {
      final amplitude = 30.0 * math.sin(i / 50);
      final y = size.height * 0.7 + amplitude;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Add some particles for depth
    _drawParticles(canvas, size);
  }

  void _drawParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = secondaryColor.withOpacity(0.5);

    final random = math.Random();

    // Draw some floating particles
    for (int i = 0; i < 40; i++) {
      final progress = (i / 40);
      final x = math.sin(progress * math.pi * 2) * 100 + size.width / 2;
      final y = math.cos(progress * math.pi * 4) * 150 + size.height / 3;
      final particleSize = 2.0 + progress * 4;
      
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 