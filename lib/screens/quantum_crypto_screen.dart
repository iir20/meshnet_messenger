import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quantum_crypto_service.dart';
import '../widgets/glass_card.dart';

class QuantumCryptoScreen extends StatefulWidget {
  const QuantumCryptoScreen({Key? key}) : super(key: key);

  @override
  _QuantumCryptoScreenState createState() => _QuantumCryptoScreenState();
}

class _QuantumCryptoScreenState extends State<QuantumCryptoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _messageController = TextEditingController();
  String? _selectedKeyId;
  String? _encryptionResult;
  String? _decryptionResult;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background animation
          CustomPaint(
            painter: QuantumPainter(
              animation: _animationController,
            ),
            size: MediaQuery.of(context).size,
          ),
          
          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAppBar(),
                Expanded(
                  child: Consumer<QuantumCryptoService>(
                    builder: (context, service, child) {
                      return _buildMainContent(service);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.purpleAccent.withOpacity(0.8),
            size: 32,
          ),
          const SizedBox(width: 16),
          const Text(
            'QUANTUM SECURITY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white.withOpacity(0.7),
            ),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainContent(QuantumCryptoService service) {
    final keyPairs = service.getKeyPairs();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildKeysSection(service, keyPairs),
          const SizedBox(height: 24),
          _buildEncryptionSection(service),
          if (_encryptionResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(
              title: 'ENCRYPTED DATA',
              content: _encryptionResult!,
              icon: Icons.enhanced_encryption,
              color: Colors.purpleAccent,
            ),
          ],
          if (_decryptionResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(
              title: 'DECRYPTED MESSAGE',
              content: _decryptionResult!,
              icon: Icons.no_encryption,
              color: Colors.greenAccent,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildKeysSection(QuantumCryptoService service, List<KeyPair> keyPairs) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'POST-QUANTUM KEYS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                _buildKeyGenerationButton(
                  label: 'KYBER',
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await service.generateKyberKeyPair();
                    setState(() => _isLoading = false);
                  },
                  color: Colors.purpleAccent,
                ),
                const SizedBox(width: 8),
                _buildKeyGenerationButton(
                  label: 'NTRU',
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await service.generateNtruKeyPair();
                    setState(() => _isLoading = false);
                  },
                  color: Colors.cyanAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (keyPairs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No keys generated yet. Generate your first post-quantum key pair.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              _buildKeysList(service, keyPairs),
          ],
        ),
      ),
    );
  }
  
  Widget _buildKeyGenerationButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildKeysList(QuantumCryptoService service, List<KeyPair> keyPairs) {
    return Column(
      children: keyPairs.map((keyPair) => _buildKeyCard(service, keyPair)).toList(),
    );
  }
  
  Widget _buildKeyCard(QuantumCryptoService service, KeyPair keyPair) {
    final isSelected = _selectedKeyId == keyPair.keyId;
    final algorithm = keyPair.algorithm.toUpperCase();
    final keyId = keyPair.keyId;
    
    final Color algorithmColor = keyPair.algorithm == 'kyber'
        ? Colors.purpleAccent
        : Colors.cyanAccent;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedKeyId = isSelected ? null : keyPair.keyId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? algorithmColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? algorithmColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: algorithmColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                algorithm,
                style: TextStyle(
                  color: algorithmColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    keyId,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Public Key Size: ${keyPair.publicKey.length} bytes',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.redAccent.withOpacity(0.7),
                size: 20,
              ),
              onPressed: () {
                _showDeleteKeyDialog(service, keyPair);
              },
            ),
            Radio<String>(
              value: keyPair.keyId,
              groupValue: _selectedKeyId,
              onChanged: (value) {
                setState(() {
                  _selectedKeyId = value;
                });
              },
              activeColor: algorithmColor,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEncryptionSection(QuantumCryptoService service) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QUANTUM-RESISTANT ENCRYPTION',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter message to encrypt...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.purpleAccent.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  label: 'ENCRYPT',
                  icon: Icons.enhanced_encryption,
                  onPressed: _selectedKeyId == null || _messageController.text.isEmpty
                      ? null
                      : () => _encryptMessage(service),
                  color: Colors.purpleAccent,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  label: 'DECRYPT',
                  icon: Icons.no_encryption,
                  onPressed: _selectedKeyId == null || _encryptionResult == null
                      ? null
                      : () => _decryptMessage(service),
                  color: Colors.greenAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    final isEnabled = onPressed != null;
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isEnabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
        disabledForegroundColor: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isEnabled ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
  
  Widget _buildResultCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      blur: 5,
      opacity: 0.2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteKeyDialog(QuantumCryptoService service, KeyPair keyPair) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0f0f22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.purpleAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Text(
            'Delete Key',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this ${keyPair.algorithm.toUpperCase()} key? This action cannot be undone.',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedKeyId == keyPair.keyId) {
                  setState(() {
                    _selectedKeyId = null;
                  });
                }
                await service.deleteKeyPair(keyPair.keyId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0f0f22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.purpleAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Text(
            'Post-Quantum Cryptography',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoSection(
                  title: 'Kyber',
                  content: 'Kyber is a lattice-based key encapsulation mechanism (KEM) that provides security against attacks from quantum computers. It is one of the winners of the NIST Post-Quantum Cryptography standardization process.',
                  icon: Icons.security,
                  color: Colors.purpleAccent,
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'NTRU',
                  content: 'NTRU is one of the oldest lattice-based cryptographic systems, known for its efficiency and security. It provides resistance against attacks from both classical and quantum computers.',
                  icon: Icons.shield,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Quantum Threat',
                  content: 'Quantum computers threaten current cryptography by potentially breaking RSA and ECC using Shor\'s algorithm. Post-quantum cryptography ensures security even against quantum attacks.',
                  icon: Icons.warning_amber,
                  color: Colors.amberAccent,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Future<void> _encryptMessage(QuantumCryptoService service) async {
    if (_selectedKeyId == null || _messageController.text.isEmpty) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final message = utf8.encode(_messageController.text);
      final encryptedMessage = await service.encryptMessage(
        _selectedKeyId!,
        Uint8List.fromList(message),
      );
      
      setState(() {
        _encryptionResult = jsonEncode(encryptedMessage.toJson());
        _decryptionResult = null;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorDialog('Encryption failed: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _decryptMessage(QuantumCryptoService service) async {
    if (_selectedKeyId == null || _encryptionResult == null) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final encryptedMessage = EncryptedMessage.fromJson(
        jsonDecode(_encryptionResult!) as Map<String, dynamic>,
      );
      
      final decryptedData = await service.decryptMessage(
        _selectedKeyId!,
        encryptedMessage,
      );
      
      setState(() {
        _decryptionResult = utf8.decode(decryptedData);
        _isLoading = false;
      });
    } catch (e) {
      _showErrorDialog('Decryption failed: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0f0f22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.redAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Error',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class QuantumPainter extends CustomPainter {
  final Animation<double> animation;
  
  QuantumPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Background gradient
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1a1a2e),
          const Color(0xFF0f0f1f),
          Colors.black,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    // Draw quantum circuit pattern
    final circuitPaint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Horizontal quantum circuit lines
    final numHLines = 15;
    final hSpacing = height / numHLines;
    
    for (int i = 1; i < numHLines; i++) {
      final y = i * hSpacing;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(width, y);
      
      canvas.drawPath(path, circuitPaint);
      
      // Draw quantum gates
      final gateCount = 5;
      final gateSpacing = width / gateCount;
      
      for (int j = 0; j < gateCount; j++) {
        final x = j * gateSpacing + gateSpacing / 2;
        final gateType = (i + j) % 4;
        
        // Animate gate positions
        final offset = 10 * math.sin(animation.value * 2 * math.pi + i * j);
        
        switch (gateType) {
          case 0: // Circle gate (X gate)
            canvas.drawCircle(
              Offset(x + offset, y),
              10,
              Paint()
                ..color = Colors.purpleAccent.withOpacity(0.2)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2,
            );
            canvas.drawLine(
              Offset(x + offset - 10, y),
              Offset(x + offset + 10, y),
              Paint()
                ..color = Colors.purpleAccent.withOpacity(0.2)
                ..strokeWidth = 2,
            );
            canvas.drawLine(
              Offset(x + offset, y - 10),
              Offset(x + offset, y + 10),
              Paint()
                ..color = Colors.purpleAccent.withOpacity(0.2)
                ..strokeWidth = 2,
            );
            break;
          case 1: // Square gate (H gate)
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(x + offset, y),
                width: 20,
                height: 20,
              ),
              Paint()
                ..color = Colors.cyanAccent.withOpacity(0.2)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2,
            );
            break;
          case 2: // Control point
            canvas.drawCircle(
              Offset(x + offset, y),
              5,
              Paint()
                ..color = Colors.greenAccent.withOpacity(0.3)
                ..style = PaintingStyle.fill,
            );
            break;
          case 3: // No gate
            break;
        }
      }
    }
    
    // Draw quantum entanglement effect
    final particleCount = 100;
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < particleCount; i++) {
      final particleProgress = (animation.value + i / particleCount) % 1.0;
      final hue = (360 * particleProgress) % 360;
      final particleColor = HSVColor.fromAHSV(
        0.5, // Alpha
        hue, // Hue
        0.7, // Saturation
        0.9, // Value
      ).toColor();
      
      final x = width * particleProgress;
      final y = height / 2 + height / 4 * math.sin(particleProgress * 2 * math.pi);
      
      // Particle size pulse based on animation
      final particleSize = 2.0 + 1.5 * math.sin(animation.value * 2 * math.pi + i);
      
      particlePaint.color = particleColor;
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
      
      // Draw entanglement partner
      final partnerX = width - x;
      final partnerY = height - y;
      
      canvas.drawCircle(Offset(partnerX, partnerY), particleSize, particlePaint);
      
      // Draw faint entanglement line
      if (i % 5 == 0) { // Only draw some lines to avoid clutter
        canvas.drawLine(
          Offset(x, y),
          Offset(partnerX, partnerY),
          Paint()
            ..color = particleColor.withOpacity(0.1)
            ..strokeWidth = 0.5,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(QuantumPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
} 