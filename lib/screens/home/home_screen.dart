import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_mesh_messenger/models/chat.dart';
import 'package:secure_mesh_messenger/models/peer.dart';
import 'package:secure_mesh_messenger/providers/auth_provider.dart';
import 'package:secure_mesh_messenger/providers/mesh_provider.dart';
import 'package:secure_mesh_messenger/providers/message_provider.dart';
import 'package:secure_mesh_messenger/screens/chat/chat_screen.dart';
import 'package:secure_mesh_messenger/screens/settings/settings_screen.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:secure_mesh_messenger/widgets/connection_status_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initMeshNetwork();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initMeshNetwork() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meshProvider = Provider.of<MeshProvider>(context, listen: false);
    
    // Start advertising presence
    final userId = authProvider.userId;
    final userName = authProvider.userName;
    
    if (userId != null && userName != null) {
      await meshProvider.startAdvertising(userId, userName);
    }
  }

  Future<void> _toggleDiscovery() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meshProvider = Provider.of<MeshProvider>(context, listen: false);
    
    final userId = authProvider.userId;
    final userName = authProvider.userName;
    
    if (userId != null && userName != null) {
      setState(() {
        _isDiscovering = !_isDiscovering;
      });
      
      if (_isDiscovering) {
        await meshProvider.startDiscovery(userId, userName);
      } else {
        await meshProvider.stopDiscovery();
      }
    }
  }

  Future<void> _connectToPeer(Peer peer) async {
    final meshProvider = Provider.of<MeshProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    // Show connecting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Connecting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Establishing secure connection...'),
          ],
        ),
      ),
    );
    
    try {
      // Connect to peer
      final connected = await meshProvider.connectToPeer(peer);
      
      if (connected) {
        // Create or get chat
        final chat = await messageProvider.getOrCreateChat(peer);
        
        // Navigate to chat screen
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatId: chat.id),
            ),
          );
        }
      } else {
        // Show error
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection failed')),
          );
        }
      }
    } catch (e) {
      // Show error
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    }
  }

  void _openChat(Chat chat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chat.id),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meshProvider = Provider.of<MeshProvider>(context);
    final messageProvider = Provider.of<MessageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Mesh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Peers'),
          ],
        ),
      ),
      body: Column(
        children: [
          ConnectionStatusBar(
            isBluetoothEnabled: meshProvider.bluetoothEnabled,
            isLocationEnabled: meshProvider.locationEnabled,
            isDiscovering: meshProvider.isDiscovering,
            isAdvertising: meshProvider.isAdvertising,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Chats tab
                _buildChatsTab(messageProvider),
                // Peers tab
                _buildPeersTab(meshProvider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tabController.index == 0 ? null : _toggleDiscovery,
        backgroundColor: _tabController.index == 0 ? Colors.grey : primaryColor,
        child: Icon(
          _tabController.index == 0
              ? Icons.add
              : (_isDiscovering ? Icons.stop : Icons.search),
        ),
        tooltip: _tabController.index == 0
            ? 'New Chat'
            : (_isDiscovering ? 'Stop Discovery' : 'Start Discovery'),
      ),
    );
  }

  Widget _buildChatsTab(MessageProvider messageProvider) {
    final chats = messageProvider.chats;
    
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Discover peers nearby to start messaging securely',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Discover Peers'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primaryColor,
            child: Text(
              chat.peerName.isNotEmpty ? chat.peerName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(chat.peerName),
          subtitle: Text(
            chat.lastMessage ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatChatTime(chat.lastMessageAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (chat.isEncrypted)
                const Icon(Icons.lock, size: 14, color: Colors.green),
            ],
          ),
          onTap: () => _openChat(chat),
        );
      },
    );
  }

  Widget _buildPeersTab(MeshProvider meshProvider) {
    final discoveredPeers = meshProvider.discoveredPeers;
    
    if (discoveredPeers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No peers discovered',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Start discovering to find peers nearby',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _toggleDiscovery,
              icon: Icon(_isDiscovering ? Icons.stop : Icons.search),
              label: Text(_isDiscovering ? 'Stop Discovery' : 'Start Discovery'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: discoveredPeers.length,
      itemBuilder: (context, index) {
        final peer = discoveredPeers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: peer.isConnected ? Colors.green : Colors.grey,
            child: Text(
              peer.name.isNotEmpty ? peer.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(peer.name),
          subtitle: Text(
            peer.isConnected ? 'Connected' : 'Last seen: ${_formatLastSeen(peer.lastSeen)}',
          ),
          trailing: IconButton(
            icon: Icon(
              peer.isConnected ? Icons.chat : Icons.link,
              color: peer.isConnected ? Colors.green : primaryColor,
            ),
            onPressed: () => _connectToPeer(peer),
          ),
          onTap: () => _connectToPeer(peer),
        );
      },
    );
  }

  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _formatLastSeen(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
} 