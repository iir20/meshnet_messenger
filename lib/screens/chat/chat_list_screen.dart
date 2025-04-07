import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_mesh_messenger/models/chat.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/providers/auth_provider.dart';
import 'package:secure_mesh_messenger/providers/chat_provider.dart';
import 'package:secure_mesh_messenger/screens/chat/chat_screen.dart';
import 'package:secure_mesh_messenger/screens/contacts/contact_list_screen.dart';
import 'package:secure_mesh_messenger/services/message_service.dart';
import 'package:secure_mesh_messenger/services/notification_service.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:secure_mesh_messenger/utils/date_formatter.dart';
import 'package:secure_mesh_messenger/widgets/common/custom_search_bar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);
  
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<Chat> _filteredChats = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _searchDebounce;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChats();
    
    // Setup listener for chat updates
    Provider.of<ChatProvider>(context, listen: false).addListener(_onChatsChanged);
    
    // Initialize search controller
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Provider.of<ChatProvider>(context, listen: false).removeListener(_onChatsChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadChats();
    }
  }
  
  void _onChatsChanged() {
    _filterChats();
  }
  
  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
          _filterChats();
        });
      }
    });
  }
  
  Future<void> _loadChats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      await Provider.of<ChatProvider>(context, listen: false).loadChats();
    } catch (e) {
      // Show error if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chats: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _filterChats();
        });
      }
    }
  }
  
  void _filterChats() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chats = chatProvider.chats;
    
    if (_searchQuery.isEmpty) {
      _filteredChats = List.from(chats);
    } else {
      _filteredChats = chats.where((chat) {
        final lowerQuery = _searchQuery.toLowerCase();
        final nameMatches = chat.name.toLowerCase().contains(lowerQuery);
        final lastMessageMatches = chat.lastMessage?.content.toLowerCase().contains(lowerQuery) ?? false;
        
        return nameMatches || lastMessageMatches;
      }).toList();
    }
    
    // Sort chats by most recent message
    _filteredChats.sort((a, b) {
      if (a.lastMessage == null && b.lastMessage == null) return 0;
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return -1;
      
      return b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp);
    });
    
    if (mounted) setState(() {});
  }
  
  void _navigateToChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chat.id),
      ),
    );
  }
  
  void _navigateToContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactListScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChats,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              // Handle menu selections
              if (value == 'settings') {
                Navigator.pushNamed(context, Routes.settings);
              } else if (value == 'archived') {
                Navigator.pushNamed(context, Routes.archivedChats);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              if (enableArchivedChats)
                const PopupMenuItem(
                  value: 'archived',
                  child: Text('Archived Chats'),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Search conversations...',
              onClear: () {
                _searchController.clear();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChats.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) => _buildChatItem(_filteredChats[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToContacts,
        tooltip: 'New Chat',
        child: const Icon(Icons.message),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No matches for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to start a new chat',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToContacts,
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatItem(Chat chat) {
    final themeData = Theme.of(context);
    final hasUnread = chat.unreadCount > 0;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isUserOnline = authProvider.isUserOnline(chat.participantId);
    
    return Dismissible(
      key: Key('chat_${chat.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Chat'),
              content: const Text('Are you sure you want to delete this chat? All messages will be permanently removed from this device.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await Provider.of<ChatProvider>(context, listen: false).deleteChat(chat.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Chat deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // Undo delete operation
                  Provider.of<ChatProvider>(context, listen: false).restoreChat(chat);
                },
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete chat: $e')),
          );
        }
      },
      child: ListTile(
        onTap: () => _navigateToChat(chat),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: hasUnread ? themeData.colorScheme.primary : Colors.grey[300],
              child: CircleAvatar(
                radius: hasUnread ? 26 : 28,
                backgroundImage: chat.avatarUrl != null ? NetworkImage(chat.avatarUrl!) : null,
                child: chat.avatarUrl == null
                    ? Text(
                        chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 22,
                          color: hasUnread
                              ? Colors.white
                              : themeData.colorScheme.onPrimary,
                        ),
                      )
                    : null,
              ),
            ),
            if (isUserOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeData.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chat.name,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: chat.lastMessage != null
            ? _buildLastMessagePreview(chat.lastMessage!)
            : const Text(
                'No messages yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chat.lastMessage != null
                  ? DateFormatter.formatChatTimestamp(chat.lastMessage!.timestamp)
                  : '',
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? themeData.colorScheme.primary : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            if (hasUnread)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                  style: TextStyle(
                    color: themeData.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (chat.isMuted)
              const Icon(
                Icons.volume_off,
                size: 16,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLastMessagePreview(Message message) {
    String preview = '';
    
    // Generate preview based on message type
    switch (message.type) {
      case MessageType.text:
        preview = message.content;
        break;
      case MessageType.image:
        preview = '📷 Photo';
        break;
      case MessageType.video:
        preview = '📹 Video';
        break;
      case MessageType.audio:
        preview = '🎵 Audio message';
        break;
      case MessageType.file:
        preview = '📎 File: ${message.fileName ?? 'Document'}';
        break;
      case MessageType.location:
        preview = '📍 Location';
        break;
      case MessageType.contact:
        preview = '👤 Contact: ${message.contactName ?? 'Contact'}';
        break;
      case MessageType.ar:
        preview = '✨ AR Message';
        break;
      default:
        preview = 'Message';
    }
    
    // Add emoji for self-destruct messages
    if (message.selfDestruct) {
      preview = '⏱️ ' + preview;
    }
    
    return Row(
      children: [
        if (message.status == MessageStatus.failed)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.error_outline,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        Expanded(
          child: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: message.status == MessageStatus.failed
                  ? Theme.of(context).colorScheme.error
                  : null,
              fontWeight: message.status == MessageStatus.failed
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
} 