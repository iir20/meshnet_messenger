import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:secure_mesh_messenger/services/theme_service.dart';
import 'package:secure_mesh_messenger/models/chat.dart';
import 'package:secure_mesh_messenger/models/message.dart';

class ConversationView extends StatefulWidget {
  final Chat chat;
  
  const ConversationView({
    super.key,
    required this.chat,
  });
  
  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> with SingleTickerProviderStateMixin {
  late AnimationController _bubbleController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  String _currentEmotion = 'neutral';
  
  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Initialize with sample messages
    _initializeMessages();
  }
  
  void _initializeMessages() {
    // Sample messages - replace with actual data
    _messages.addAll([
      Message(
        id: '1',
        senderId: 'user1',
        content: 'Hello! How are you?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: MessageType.text,
        emotion: 'happy',
      ),
      Message(
        id: '2',
        senderId: 'user2',
        content: 'I\'m doing great! Working on a new project.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        type: MessageType.text,
        emotion: 'excited',
      ),
      Message(
        id: '3',
        senderId: 'user1',
        content: 'That sounds interesting! Tell me more.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        type: MessageType.text,
        emotion: 'curious',
      ),
    ]);
  }
  
  @override
  void dispose() {
    _bubbleController.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(themeService),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeService.currentColorScheme.background,
              themeService.currentColorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _buildMessageList(themeService),
            ),
            _buildInputField(themeService),
          ],
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(ThemeService themeService) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: themeService.currentColorScheme.primary,
            child: Text(
              widget.chat.name[0],
              style: TextStyle(
                color: themeService.currentColorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chat.name,
                style: TextStyle(
                  color: themeService.currentColorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Last active: ${_formatTime(widget.chat.lastActive)}',
                style: TextStyle(
                  color: themeService.currentColorScheme.onBackground.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: themeService.currentColorScheme.onBackground,
          ),
          onPressed: () {
            // Show more options
          },
        ),
      ],
    );
  }
  
  Widget _buildMessageList(ThemeService themeService) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == 'user1'; // Replace with actual user ID
        
        return _buildMessageBubble(
          message,
          isMe,
          themeService,
        ).animate(
          onPlay: (controller) => controller.forward(),
        ).slideX(
          begin: isMe ? 0.2 : -0.2,
          end: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }
  
  Widget _buildMessageBubble(Message message, bool isMe, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(message, themeService),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? themeService.currentColorScheme.primary.withOpacity(0.2)
                    : themeService.currentColorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeService.currentColorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeService.currentColorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: themeService.currentColorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: themeService.currentColorScheme.onSurface.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(message, themeService),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAvatar(Message message, ThemeService themeService) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeService.currentColorScheme.secondary,
        border: Border.all(
          color: themeService.currentColorScheme.primary,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          message.senderId[0].toUpperCase(),
          style: TextStyle(
            color: themeService.currentColorScheme.onSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputField(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.currentColorScheme.surface,
        border: Border(
          top: BorderSide(
            color: themeService.currentColorScheme.primary.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(
                color: themeService.currentColorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: themeService.currentColorScheme.onSurface.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: themeService.currentColorScheme.surface.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeService.currentColorScheme.primary,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: themeService.currentColorScheme.onPrimary,
              ),
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  _sendMessage(_messageController.text);
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _sendMessage(String content) {
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'user1', // Replace with actual user ID
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.text,
      emotion: _currentEmotion,
    );
    
    setState(() {
      _messages.add(newMessage);
    });
    
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 