import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/crypto_service.dart';
import '../services/mesh_service.dart';

class Message {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String senderName;
  final String? encryptionType;
  final bool isEncrypted;
  final String mood;
  
  Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.senderName,
    this.encryptionType,
    this.isEncrypted = true,
    this.mood = 'neutral',
  });
}

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  
  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.chatName,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  String _currentMood = 'neutral';
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    
    _loadSampleMessages();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _loadSampleMessages() {
    // Example messages with different moods
    final sampleMessages = [
      Message(
        id: '1',
        text: 'Hey there! How are you doing today?',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        senderName: widget.chatName,
        encryptionType: 'AES-256-GCM',
        mood: 'happy',
      ),
      Message(
        id: '2',
        text: 'I\'m doing great, thanks for asking! Just working on this new mesh network project.',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        senderName: 'You',
        encryptionType: 'AES-256-GCM',
        mood: 'excited',
      ),
      Message(
        id: '3',
        text: 'That sounds really interesting! I\'ve been curious about decentralized communication systems.',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        senderName: widget.chatName,
        encryptionType: 'AES-256-GCM',
        mood: 'curious',
      ),
      Message(
        id: '4',
        text: 'Yeah, it\'s amazing how resilient they can be. I\'m focusing on privacy and encryption aspects right now.',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        senderName: 'You',
        encryptionType: 'ChaCha20-Poly1305',
        mood: 'focused',
      ),
      Message(
        id: '5',
        text: 'Privacy is critical these days. Have you implemented the quantum-resistant algorithms yet?',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        senderName: widget.chatName,
        encryptionType: 'XChaCha20-Poly1305',
        mood: 'curious',
      ),
      Message(
        id: '6',
        text: 'Not yet, but it\'s on my roadmap. First I need to ensure the basic mesh functionality works well.',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        senderName: 'You',
        encryptionType: 'XChaCha20-Poly1305',
        mood: 'calm',
      ),
    ];
    
    setState(() {
      _messages.addAll(sampleMessages);
    });
  }
  
  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final cryptoService = Provider.of<CryptoService>(context, listen: false);
    final meshService = Provider.of<MeshService>(context, listen: false);
    
    // Detect mood from message text
    final mood = _detectMood(text);
    
    // Create new message
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
      senderName: 'You',
      encryptionType: cryptoService.getEncryptionType(),
      mood: mood,
    );
    
    // Reset controller and update UI
    _messageController.clear();
    
    // Add haptic feedback based on mood
    switch (mood) {
      case 'excited':
        HapticFeedback.mediumImpact();
        break;
      case 'angry':
        HapticFeedback.heavyImpact();
        break;
      default:
        HapticFeedback.lightImpact();
    }
    
    setState(() {
      _messages.add(newMessage);
      _currentMood = mood;
    });
    
    // Scroll to bottom
    _scrollToBottom();
    
    // Here we would send the message via the mesh network
    // In the mock, we'll just simulate a reply after a delay
    _simulateReply(meshService);
  }
  
  void _simulateReply(MeshService meshService) {
    // Find a peer from the mesh service
    final peers = meshService.peers;
    
    if (peers.isNotEmpty) {
      // Get a random connected peer or use the first one
      final peer = peers.where((p) => p.isConnected).toList();
      final randomPeer = peer.isNotEmpty 
          ? peer[math.Random().nextInt(peer.length)]
          : peers.first;
      
      // Simulate sending a message to this peer
      meshService.sendMessage(
        _messages.last.text, 
        randomPeer.id,
        encryptionType: _messages.last.encryptionType,
      );
      
      // Listen for the reply
      StreamSubscription? subscription;
      subscription = meshService.onMessageReceived.listen((message) {
        if (message.senderId == randomPeer.id && message.recipientId == meshService.localPeer.id) {
          // Create a message object from the mesh message
          final replyMessage = Message(
            id: message.id,
            text: message.content,
            isMe: false,
            timestamp: message.timestamp,
            senderName: randomPeer.name,
            encryptionType: message.encryptionType,
            isEncrypted: message.isEncrypted,
            mood: _detectMood(message.content),
          );
          
          // Add to messages
          setState(() {
            _messages.add(replyMessage);
          });
          
          // Scroll to bottom
          _scrollToBottom();
          
          // Cancel subscription after receiving one message
          subscription?.cancel();
        }
      });
    } else {
      // If no peers, simulate a direct reply
      Timer(const Duration(seconds: 2), () {
        final replies = [
          'That\'s interesting! Tell me more.',
          'I see what you mean. What are your next steps?',
          'Have you considered using a different approach?',
          'That makes sense. I\'ve been thinking about this too.',
          'Cool! I\'m excited to see how this develops.',
        ];
        
        final replyText = replies[math.Random().nextInt(replies.length)];
        final replyMood = _detectMood(replyText);
        
        final replyMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: replyText,
          isMe: false,
          timestamp: DateTime.now(),
          senderName: widget.chatName,
          encryptionType: Provider.of<CryptoService>(context, listen: false).getEncryptionType(),
          mood: replyMood,
        );
        
        setState(() {
          _messages.add(replyMessage);
        });
        
        _scrollToBottom();
      });
    }
  }
  
  String _detectMood(String text) {
    text = text.toLowerCase();
    
    // Simple keyword-based mood detection
    if (text.contains('happy') || 
        text.contains('great') || 
        text.contains('awesome') ||
        text.contains('excellent') ||
        text.contains('wonderful')) {
      return 'happy';
    } else if (text.contains('angry') || 
               text.contains('upset') || 
               text.contains('mad') ||
               text.contains('terrible')) {
      return 'angry';
    } else if (text.contains('sad') || 
               text.contains('unhappy') || 
               text.contains('disappointed')) {
      return 'sad';
    } else if (text.contains('love') || 
               text.contains('heart') || 
               text.contains('care')) {
      return 'loving';
    } else if (text.contains('worried') || 
               text.contains('anxious') || 
               text.contains('concerned')) {
      return 'worried';
    } else if (text.contains('excited') || 
               text.contains('can\'t wait') || 
               text.contains('looking forward')) {
      return 'excited';
    } else if (text.contains('calm') || 
               text.contains('relaxed') || 
               text.contains('peaceful')) {
      return 'calm';
    } else if (text.contains('curious') || 
               text.contains('wondering') || 
               text.contains('interesting')) {
      return 'curious';
    } else if (text.contains('focused') || 
               text.contains('concentrating') || 
               text.contains('working on')) {
      return 'focused';
    }
    
    // Default mood
    return 'neutral';
  }
  
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy':
        return Colors.amber;
      case 'angry':
        return Colors.red;
      case 'sad':
        return Colors.blue;
      case 'loving':
        return Colors.pink;
      case 'worried':
        return Colors.orange;
      case 'excited':
        return Colors.purple;
      case 'calm':
        return Colors.teal;
      case 'curious':
        return Colors.cyan;
      case 'focused':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current mood color for background gradient
    final moodColor = _getMoodColor(_currentMood);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.chatName,
          style: const TextStyle(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video calls coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              HapticFeedback.selectionClick();
              _showChatOptions(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated mood background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF1a1a2e), 
                        moodColor, 
                        0.1 + math.sin(_animationController.value * math.pi) * 0.05
                      )!,
                      Color.lerp(
                        const Color(0xFF16213e), 
                        moodColor, 
                        0.1 + math.cos(_animationController.value * math.pi) * 0.05
                      )!,
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: ParticleBackgroundPainter(
                    animation: _animationController,
                    color: moodColor,
                    size: MediaQuery.of(context).size,
                  ),
                  child: Container(),
                ),
              );
            },
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Chat messages
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message);
                          },
                        ),
                ),
                
                // Input field
                _buildInputField(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Message message) {
    final moodColor = _getMoodColor(message.mood);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: moodColor.withOpacity(0.5),
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final bubbleSize = message.text.length;
                final floatOffset = math.sin(
                  _animationController.value * 2 * math.pi + 
                  bubbleSize * 0.01
                ) * 2.0;
                
                return Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      message.isMe 
                          ? moodColor.withOpacity(0.7) 
                          : Colors.black54,
                      message.isMe 
                          ? moodColor.withOpacity(0.3) 
                          : Colors.black38,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: moodColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: message.isMe 
                        ? moodColor.withOpacity(0.3) 
                        : Colors.white10,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.isEncrypted) ...[
                              Icon(
                                Icons.lock,
                                size: 10,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                message.encryptionType ?? 'Encrypted',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          if (message.isMe) ...[
            const SizedBox(width: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: moodColor.withOpacity(0.5),
                  child: const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
                if (message.mood != 'neutral')
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: moodColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                color: Colors.white70,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File attachments coming soon')),
                  );
                },
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                color: Colors.cyanAccent,
                onPressed: _handleSendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.white10,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.enhanced_encryption,
                  color: Colors.purpleAccent,
                ),
                title: const Text(
                  'Change Encryption',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showEncryptionOptions(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.visibility_off,
                  color: Colors.blue,
                ),
                title: const Text(
                  'Self-Destruct Messages',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Self-destruct messages coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.schedule,
                  color: Colors.amber,
                ),
                title: const Text(
                  'Time Capsule Message',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Time capsule messages coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.fingerprint,
                  color: Colors.green,
                ),
                title: const Text(
                  'Biometric Lock',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Biometric lock coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.refresh,
                  color: Colors.cyanAccent,
                ),
                title: const Text(
                  'Reset Encryption Keys',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Key rotation coming soon')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showEncryptionOptions(BuildContext context) {
    final cryptoService = Provider.of<CryptoService>(context, listen: false);
    Navigator.pop(context); // Close the first bottom sheet
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder( // Needed to update the UI state within the sheet
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: Colors.white10,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Encryption Algorithm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text(
                      'AES-256-GCM',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Standard, widely-used symmetric encryption',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    value: CryptoService.AES_256_GCM,
                    groupValue: cryptoService.getEncryptionType(),
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          cryptoService.setEncryptionType(value);
                        });
                        HapticFeedback.selectionClick();
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'ChaCha20-Poly1305',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Fast encryption on mobile devices',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    value: CryptoService.CHACHA20_POLY1305,
                    groupValue: cryptoService.getEncryptionType(),
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          cryptoService.setEncryptionType(value);
                        });
                        HapticFeedback.selectionClick();
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'XChaCha20-Poly1305',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Extended nonce for better security',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    value: CryptoService.XCHACHA20_POLY1305,
                    groupValue: cryptoService.getEncryptionType(),
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          cryptoService.setEncryptionType(value);
                        });
                        HapticFeedback.selectionClick();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Encryption set to ${cryptoService.getEncryptionType()}'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays > 0) {
      return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

class ParticleBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final Size size;
  
  ParticleBackgroundPainter({
    required this.animation,
    required this.color,
    required this.size,
  }) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = this.size.width;
    final height = this.size.height;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Draw floating particles
    final particleCount = 50;
    
    for (int i = 0; i < particleCount; i++) {
      final progress = (animation.value + i / particleCount) % 1.0;
      final size = 1.0 + math.sin(progress * math.pi) * 1.5;
      final opacity = 0.1 + math.sin(progress * math.pi) * 0.1;
      
      final xOffset = math.sin(progress * math.pi * 2 + i) * 100;
      final yOffset = math.cos(progress * math.pi * 2 + i * 0.5) * 100;
      
      final x = width / 2 + xOffset;
      final y = height / 2 + yOffset;
      
      paint.color = Color.lerp(
        Colors.white.withOpacity(opacity),
        color.withOpacity(opacity),
        0.5,
      )!;
      
      canvas.drawCircle(Offset(x, y), size, paint);
    }
    
    // Draw mood aura
    final gradient = RadialGradient(
      colors: [
        color.withOpacity(0.2),
        color.withOpacity(0.1),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    final auraPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(width / 2, height / 3),
          radius: width * 0.8,
        ),
      );
    
    canvas.drawCircle(
      Offset(width / 2, height / 3),
      width * 0.8,
      auraPaint,
    );
  }
  
  @override
  bool shouldRepaint(ParticleBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.color != color;
  }
} 