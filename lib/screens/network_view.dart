import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/mesh_service.dart';
import '../services/crypto_service.dart';
import '../services/p2p_service.dart';
import '../widgets/glass_card.dart';

class NetworkView extends StatefulWidget {
  const NetworkView({Key? key}) : super(key: key);

  @override
  _NetworkViewState createState() => _NetworkViewState();
}

class _NetworkViewState extends State<NetworkView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _rotationY = 0.0;
  double _rotationX = 0.0;
  double _scale = 1.0;
  final TextEditingController _peerNameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    
    // Initialize peer name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p2pService = Provider.of<P2PService>(context, listen: false);
      _peerNameController.text = p2pService.peerName;
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _peerNameController.dispose();
    _scrollController.dispose();
    
    // Stop discovery when view is disposed
    final meshService = Provider.of<MeshService>(context, listen: false);
    meshService.stopDiscovery();
    
    super.dispose();
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotationY += details.delta.dx * 0.01;
      _rotationX -= details.delta.dy * 0.01;
    });
  }
  
  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _rotationY = 0.0;
      _rotationX = 0.0;
    });
  }
  
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = details.scale.clamp(0.8, 1.5);
    });
  }
  
  void _handleScaleEnd(ScaleEndDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final meshService = Provider.of<MeshService>(context);
    final cryptoService = Provider.of<CryptoService>(context);
    final p2pService = Provider.of<P2PService>(context);
    
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Mesh Network',
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 16),
                    _buildNetworkStatus(meshService),
                    const SizedBox(height: 16),
                    _buildEncryptionSettings(cryptoService),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Consumer<P2PService>(
                        builder: (context, p2pService, child) {
                          return _buildMainContent(p2pService);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Network Visualization
            Positioned.fill(
              child: _buildMeshVisualization(meshService),
            ),
            
            // Instructions overlay
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Drag to rotate • Pinch to zoom',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            p2pService.startDiscovery();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Scanning for peers...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          backgroundColor: Colors.purpleAccent,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
              ],
            ),
          ),
          child: CustomPaint(
            painter: MeshBackgroundPainter(
              animation: _animationController,
            ),
            child: Container(),
          ),
        );
      },
    );
  }
  
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.hub,
            color: Colors.cyanAccent.withOpacity(0.8),
            size: 32,
          ),
          const SizedBox(width: 16),
          const Text(
            'MESH NETWORK',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Consumer<P2PService>(
            builder: (context, p2pService, child) {
              return _buildConnectionIndicator(p2pService);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildConnectionIndicator(P2PService p2pService) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (p2pService.connectionState) {
      case ConnectionState.connected:
        statusColor = Colors.greenAccent;
        statusText = 'CONNECTED';
        statusIcon = Icons.wifi;
        break;
      case ConnectionState.connecting:
        statusColor = Colors.amberAccent;
        statusText = 'CONNECTING';
        statusIcon = Icons.wifi_find;
        break;
      case ConnectionState.error:
        statusColor = Colors.redAccent;
        statusText = 'ERROR';
        statusIcon = Icons.wifi_off;
        break;
      case ConnectionState.disconnected:
      default:
        statusColor = Colors.redAccent;
        statusText = 'DISCONNECTED';
        statusIcon = Icons.wifi_off;
    }
    
    return GestureDetector(
      onTap: () => _showConnectionDialog(p2pService),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMainContent(P2PService p2pService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPeerInfoCard(p2pService),
        const SizedBox(height: 16),
        _buildNetworkStats(p2pService),
        const SizedBox(height: 16),
        Expanded(
          child: _buildPeersList(p2pService),
        ),
      ],
    );
  }
  
  Widget _buildPeerInfoCard(P2PService p2pService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'YOUR NODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => _showPeerNameDialog(p2pService),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${p2pService.peerId}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Name: ${p2pService.peerName}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Network: ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  _buildNetworkTypeChip(p2pService.networkType),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNetworkTypeChip(NetworkType type) {
    Color color;
    String text;
    IconData icon;
    
    switch (type) {
      case NetworkType.wifi:
        color = Colors.greenAccent;
        text = 'Wi-Fi';
        icon = Icons.wifi;
        break;
      case NetworkType.bluetooth:
        color = Colors.blueAccent;
        text = 'Bluetooth';
        icon = Icons.bluetooth;
        break;
      case NetworkType.cellular:
        color = Colors.purpleAccent;
        text = 'Cellular';
        icon = Icons.cell_tower;
        break;
      case NetworkType.offline:
      default:
        color = Colors.redAccent;
        text = 'Offline';
        icon = Icons.signal_wifi_off;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNetworkStats(P2PService p2pService) {
    final connectedPeers = p2pService.knownPeers.where((p) => p.isOnline).length;
    final totalPeers = p2pService.knownPeers.length;
    final pendingMessages = p2pService.pendingMessages.length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'PEERS',
              value: '$connectedPeers/$totalPeers',
              icon: Icons.people,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'PENDING',
              value: pendingMessages.toString(),
              icon: Icons.mail_outline,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'MESSAGES',
              value: p2pService.messages.length.toString(),
              icon: Icons.message,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      opacity: 0.1,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPeersList(P2PService p2pService) {
    final peers = p2pService.knownPeers;
    
    if (peers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.public_off,
              color: Colors.white.withOpacity(0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No peers discovered yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            _buildConnectButton(p2pService),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'DISCOVERED PEERS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _buildConnectButton(p2pService),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: peers.length,
            itemBuilder: (context, index) {
              final peer = peers[index];
              return _buildPeerCard(peer, p2pService);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPeerCard(Peer peer, P2PService p2pService) {
    final isOnline = peer.isOnline;
    final statusColor = isOnline ? Colors.greenAccent : Colors.redAccent;
    final lastSeen = DateTime.now().difference(peer.lastSeen);
    String lastSeenText;
    
    if (isOnline) {
      lastSeenText = 'Online now';
    } else if (lastSeen.inMinutes < 60) {
      lastSeenText = '${lastSeen.inMinutes} minutes ago';
    } else if (lastSeen.inHours < 24) {
      lastSeenText = '${lastSeen.inHours} hours ago';
    } else {
      lastSeenText = '${lastSeen.inDays} days ago';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        opacity: 0.15,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    peer.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Trust: ${peer.trustScore}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${peer.id}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white.withOpacity(0.5),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lastSeenText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildPeerActionButton(
                    icon: Icons.message,
                    label: 'Message',
                    onTap: () => _navigateToChat(peer),
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(width: 12),
                  _buildPeerActionButton(
                    icon: isOnline ? Icons.link : Icons.link_off,
                    label: isOnline ? 'Connected' : 'Connect',
                    onTap: () => _handleConnectionToggle(peer, p2pService),
                    color: isOnline ? Colors.greenAccent : Colors.amberAccent,
                    enabled: !isOnline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPeerActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool enabled = true,
  }) {
    final opacity = enabled ? 1.0 : 0.5;
    
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1 * opacity),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3 * opacity),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color.withOpacity(opacity),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(opacity),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectButton(P2PService p2pService) {
    final isConnected = p2pService.connectionState == ConnectionState.connected;
    final isConnecting = p2pService.connectionState == ConnectionState.connecting;
    
    Color color = isConnected ? Colors.greenAccent : Colors.cyanAccent;
    String text = isConnected ? 'DISCONNECT' : 'CONNECT';
    IconData icon = isConnected ? Icons.link_off : Icons.link;
    
    if (isConnecting) {
      color = Colors.amberAccent;
      text = 'CONNECTING...';
      icon = Icons.sync;
    }
    
    return GestureDetector(
      onTap: isConnecting
          ? null
          : () => isConnected
              ? p2pService.disconnect()
              : p2pService.connect(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isConnecting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showConnectionDialog(P2PService p2pService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0f0f22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.cyanAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Text(
            'Network Connection',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectionStatusItem(
                label: 'Connection State',
                value: p2pService.connectionState.toString().split('.').last,
                color: _getStatusColor(p2pService.connectionState),
              ),
              const SizedBox(height: 8),
              _buildConnectionStatusItem(
                label: 'Network Type',
                value: p2pService.networkType.toString().split('.').last,
                color: _getNetworkColor(p2pService.networkType),
              ),
              const SizedBox(height: 8),
              _buildConnectionStatusItem(
                label: 'Connected Peers',
                value: '${p2pService.knownPeers.where((p) => p.isOnline).length}/${p2pService.knownPeers.length}',
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 8),
              _buildConnectionStatusItem(
                label: 'Pending Messages',
                value: p2pService.pendingMessages.length.toString(),
                color: Colors.amberAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: The P2P network uses LibP2P over WiFi, Bluetooth, and cellular connections to provide decentralized communication.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: p2pService.connectionState == ConnectionState.connected
                  ? p2pService.disconnect
                  : p2pService.connect,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: p2pService.connectionState == ConnectionState.connected
                    ? Colors.redAccent.withOpacity(0.6)
                    : Colors.cyanAccent.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                p2pService.connectionState == ConnectionState.connected
                    ? 'DISCONNECT'
                    : 'CONNECT',
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildConnectionStatusItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showPeerNameDialog(P2PService p2pService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0f0f22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.cyanAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Text(
            'Change Your Node Name',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _peerNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your node name',
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
                  color: Colors.cyanAccent.withOpacity(0.5),
                  width: 1,
                ),
              ),
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
              onPressed: () {
                p2pService.setPeerName(_peerNameController.text);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.cyanAccent.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
  
  Color _getStatusColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return Colors.greenAccent;
      case ConnectionState.connecting:
        return Colors.amberAccent;
      case ConnectionState.error:
        return Colors.redAccent;
      case ConnectionState.disconnected:
      default:
        return Colors.redAccent;
    }
  }
  
  Color _getNetworkColor(NetworkType type) {
    switch (type) {
      case NetworkType.wifi:
        return Colors.greenAccent;
      case NetworkType.bluetooth:
        return Colors.blueAccent;
      case NetworkType.cellular:
        return Colors.purpleAccent;
      case NetworkType.offline:
      default:
        return Colors.redAccent;
    }
  }
  
  void _handleConnectionToggle(Peer peer, P2PService p2pService) {
    // In a real app, this would trigger a connection attempt to the peer
    // For this simulation, we'll just show a "fake" loading dialog
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0f0f22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.cyanAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Text(
            'Connecting to ${peer.name}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              ),
            ),
          ),
        );
      },
    );
    
    // Simulate connection delay and then close dialog
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }
  
  void _navigateToChat(Peer peer) {
    // In a real app, this would navigate to a chat with this peer
    // For this simulation, we'll just show a dialog
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0f0f22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.cyanAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Text(
            'Chat with ${peer.name}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'In a complete implementation, this would open a chat interface with this peer.',
            style: TextStyle(
              color: Colors.white70,
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
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildNetworkStatus(MeshService meshService) {
    final localPeer = meshService.localPeer;
    final connectedPeers = meshService.peers.where((peer) => peer.isConnected).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.1),
            blurRadius: 8,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.wifi_tethering,
                      color: Colors.cyanAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Network Status',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Peer ID',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localPeer.id,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Connected Peers',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${connectedPeers.length}',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '/${meshService.peers.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEncryptionSettings(CryptoService cryptoService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.1),
            blurRadius: 8,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.purpleAccent.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.enhanced_encryption,
                      color: Colors.purpleAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Encryption',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Algorithm:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purpleAccent.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cryptoService.getEncryptionType(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.vpn_key_outlined,
                    color: Colors.purpleAccent.withOpacity(0.7),
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
      ),
    );
  }
  
  Widget _buildMeshVisualization(MeshService meshService) {
    final peers = meshService.peers;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return IgnorePointer(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_rotationX)
              ..rotateY(_rotationY)
              ..scale(_scale),
            child: CustomPaint(
              painter: MeshNetworkPainter(
                peers: peers,
                localPeer: meshService.localPeer,
                animation: _animationController,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class MeshBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  
  MeshBackgroundPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw horizontal lines with wave effect
    double lineSpacing = 40;
    int horizontalLines = (size.height / lineSpacing).ceil();
    
    for (int i = 0; i <= horizontalLines; i++) {
      final y = i * lineSpacing;
      
      final path = Path();
      path.moveTo(0, y);
      
      for (double x = 0; x < size.width; x += 5) {
        final waveHeight = math.sin(x / 50 + animation.value * 2 * math.pi) * 2.0;
        path.lineTo(x, y + waveHeight);
      }
      
      canvas.drawPath(path, paint..color = Colors.cyan.withOpacity(0.05));
    }
    
    // Draw vertical lines with wave effect
    double verticalSpacing = 40;
    int verticalLines = (size.width / verticalSpacing).ceil();
    
    for (int i = 0; i <= verticalLines; i++) {
      final x = i * verticalSpacing;
      
      final path = Path();
      path.moveTo(x, 0);
      
      for (double y = 0; y < size.height; y += 5) {
        final waveWidth = math.sin(y / 50 + animation.value * 2 * math.pi) * 2.0;
        path.lineTo(x + waveWidth, y);
      }
      
      canvas.drawPath(path, paint..color = Colors.purple.withOpacity(0.05));
    }
  }
  
  @override
  bool shouldRepaint(covariant MeshBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class MeshNetworkPainter extends CustomPainter {
  final List<Peer> peers;
  final Peer localPeer;
  final Animation<double> animation;
  
  MeshNetworkPainter({
    required this.peers,
    required this.localPeer,
    required this.animation,
  }) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (peers.isEmpty) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.3;
    
    // Draw local peer at center
    _drawPeer(
      canvas, 
      center, 
      'Local', 
      Colors.blue, 
      30, 
      animation.value,
      true,
    );
    
    // Position peers in a circle around the local peer
    final connectedPeers = peers.where((p) => p.isConnected).toList();
    final disconnectedPeers = peers.where((p) => !p.isConnected).toList();
    
    // First draw connection lines
    for (int i = 0; i < connectedPeers.length; i++) {
      final peer = connectedPeers[i];
      final angle = 2 * math.pi * i / connectedPeers.length;
      final offset = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      _drawConnectionLine(canvas, center, offset, peer.trustScore, animation.value);
    }
    
    // Then draw peer nodes
    for (int i = 0; i < connectedPeers.length; i++) {
      final peer = connectedPeers[i];
      final angle = 2 * math.pi * i / connectedPeers.length;
      final offset = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      _drawPeer(
        canvas, 
        offset, 
        peer.name, 
        _getTrustColor(peer.trustScore),
        20,
        animation.value + i * 0.1,
        peer.isConnected,
      );
    }
    
    // Draw disconnected peers further out and dimmer
    for (int i = 0; i < disconnectedPeers.length; i++) {
      final peer = disconnectedPeers[i];
      final angle = 2 * math.pi * i / disconnectedPeers.length + math.pi / 4;
      final outerRadius = radius * 1.7;
      final offset = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      
      _drawPeer(
        canvas, 
        offset, 
        peer.name, 
        _getTrustColor(peer.trustScore).withOpacity(0.5),
        15,
        animation.value + i * 0.1,
        peer.isConnected,
      );
    }
  }
  
  void _drawConnectionLine(Canvas canvas, Offset from, Offset to, double trustScore, double animValue) {
    final linePaint = Paint()
      ..color = _getTrustColor(trustScore).withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Draw data packets moving along the connection
    final packetCount = (trustScore * 5).round() + 1; // More packets for higher trust
    
    for (int i = 0; i < packetCount; i++) {
      // Calculate position along the line based on animation value
      final progress = (animValue + i / packetCount) % 1.0;
      
      final packetOffset = Offset(
        from.dx + (to.dx - from.dx) * progress,
        from.dy + (to.dy - from.dy) * progress,
      );
      
      final packetPaint = Paint()
        ..color = _getTrustColor(trustScore)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        packetOffset,
        2.0,
        packetPaint,
      );
    }
    
    // Draw the line with gradient effect
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue.withOpacity(0.7),
          _getTrustColor(trustScore).withOpacity(0.7),
        ],
      ).createShader(Rect.fromPoints(from, to));
    
    // Draw dashed line
    const dashLength = 5.0;
    const dashSpace = 3.0;
    
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitVectorX = dx / distance;
    final unitVectorY = dy / distance;
    
    double currentDistance = 0;
    bool drawDash = true;
    
    final path = Path();
    path.moveTo(from.dx, from.dy);
    
    while (currentDistance < distance) {
      final segmentLength = drawDash ? dashLength : dashSpace;
      currentDistance += segmentLength;
      
      if (currentDistance > distance) {
        currentDistance = distance;
      }
      
      final point = Offset(
        from.dx + unitVectorX * currentDistance,
        from.dy + unitVectorY * currentDistance,
      );
      
      if (drawDash) {
        path.lineTo(point.dx, point.dy);
      } else {
        path.moveTo(point.dx, point.dy);
      }
      
      drawDash = !drawDash;
    }
    
    canvas.drawPath(path, gradientPaint..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }
  
  void _drawPeer(Canvas canvas, Offset position, String name, Color color, double size, double animValue, bool isConnected) {
    // Draw outer glow
    final outerPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      position,
      size * 1.5,
      outerPaint,
    );
    
    // Draw pulsating effect if connected
    if (isConnected) {
      final pulseSize = size * (1.0 + math.sin(animValue * math.pi * 2) * 0.2);
      
      final pulsePaint = Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        position,
        pulseSize,
        pulsePaint,
      );
    }
    
    // Draw main circle
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      position,
      size / 2,
      paint,
    );
    
    // Draw orbit ring
    final orbitPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(
      position,
      size * 0.8,
      orbitPaint,
    );
    
    // Add orbital particle
    final particleOffset = Offset(
      position.dx + size * 0.8 * math.cos(animValue * math.pi * 2),
      position.dy + size * 0.8 * math.sin(animValue * math.pi * 2),
    );
    
    canvas.drawCircle(
      particleOffset,
      2.0,
      Paint()..color = color,
    );
    
    // Draw name below peer
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy + size / 2 + 5,
      ),
    );
  }
  
  Color _getTrustColor(double trustScore) {
    if (trustScore < 0.3) {
      return Colors.redAccent;
    } else if (trustScore < 0.7) {
      return Colors.orangeAccent;
    } else {
      return Colors.greenAccent;
    }
  }
  
  @override
  bool shouldRepaint(covariant MeshNetworkPainter oldDelegate) {
    return oldDelegate.animation != animation || 
           oldDelegate.peers != peers;
  }
} 