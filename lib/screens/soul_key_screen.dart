import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../services/soul_key_service.dart';
import '../widgets/glass_card.dart';

class SoulKeyScreen extends StatefulWidget {
  const SoulKeyScreen({Key? key}) : super(key: key);

  @override
  _SoulKeyScreenState createState() => _SoulKeyScreenState();
}

class _SoulKeyScreenState extends State<SoulKeyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  bool _showCreateForm = false;
  
  final _receiverController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _messageController = TextEditingController();
  
  final Map<String, TextEditingController> _answerControllers = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _receiverController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soulKeyService = Provider.of<SoulKeyService>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Neural network background animation
          CustomPaint(
            painter: NeuralNetworkPainter(
              animation: _animationController,
            ),
            size: MediaQuery.of(context).size,
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                
                // Show either the message creation form or the messages list
                if (_showCreateForm)
                  _buildCreateForm(context, soulKeyService)
                else
                  Expanded(
                    child: Column(
                      children: [
                        // Tab bar
                        Container(
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: Colors.purple.withOpacity(0.3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white.withOpacity(0.5),
                            tabs: const [
                              Tab(text: 'LOCKED'),
                              Tab(text: 'UNLOCKED'),
                            ],
                          ),
                        ),
                        
                        // Tab content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Locked messages tab
                              _buildLockedMessagesTab(soulKeyService),
                              
                              // Unlocked messages tab
                              _buildUnlockedMessagesTab(soulKeyService),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _showCreateForm ? null : _buildFAB(),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.vpn_key_rounded,
            color: Colors.purple.withOpacity(0.8),
            size: 32,
          ),
          const SizedBox(width: 12),
          const Text(
            'SOUL KEY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white.withOpacity(0.7),
            ),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLockedMessagesTab(SoulKeyService service) {
    final lockedMessages = service.lockedMessages;
    
    if (lockedMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              color: Colors.white.withOpacity(0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'NO LOCKED MESSAGES',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lockedMessages.length,
      itemBuilder: (context, index) {
        final message = lockedMessages[index];
        return _buildLockedMessageCard(message, service);
      },
    );
  }
  
  Widget _buildUnlockedMessagesTab(SoulKeyService service) {
    final unlockedMessages = service.unlockedMessages;
    
    if (unlockedMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_open_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'NO UNLOCKED MESSAGES',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unlockedMessages.length,
      itemBuilder: (context, index) {
        final message = unlockedMessages[index];
        return _buildUnlockedMessageCard(message, service);
      },
    );
  }
  
  Widget _buildLockedMessageCard(SoulKeyMessage message, SoulKeyService service) {
    // Ensure we have a controller for this message
    if (!_answerControllers.containsKey(message.id)) {
      _answerControllers[message.id] = TextEditingController();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        blur: 10,
        opacity: 0.1,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: message.color.withOpacity(0.3),
                    child: Icon(
                      Icons.lock,
                      size: 20,
                      color: message.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${message.sender}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Created: ${_formatDate(message.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      service.deleteMessage(message.id);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Memory question
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: message.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: message.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEMORY QUESTION:',
                      style: TextStyle(
                        color: message.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Attempts remaining
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: message.remainingAttempts <= 2 
                        ? Colors.red 
                        : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${message.remainingAttempts} attempts remaining',
                    style: TextStyle(
                      color: message.remainingAttempts <= 2 
                          ? Colors.red 
                          : Colors.amber,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Answer input and unlock button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _answerControllers[message.id],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your answer...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: message.color,
                          ),
                        ),
                      ),
                      onSubmitted: (answer) async {
                        _tryUnlockMessage(message, service, answer);
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  ElevatedButton(
                    onPressed: () async {
                      final answer = _answerControllers[message.id]?.text ?? '';
                      _tryUnlockMessage(message, service, answer);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: message.color.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: message.color.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('UNLOCK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUnlockedMessageCard(SoulKeyMessage message, SoulKeyService service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        blur: 10,
        opacity: 0.1,
        borderRadius: BorderRadius.circular(16),
        borderColor: message.color.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: message.color.withOpacity(0.3),
                    child: Icon(
                      Icons.lock_open,
                      size: 20,
                      color: message.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${message.sender}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Created: ${_formatDate(message.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      service.deleteMessage(message.id);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Message content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: message.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: message.color.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: message.color.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNLOCKED MESSAGE:',
                      style: TextStyle(
                        color: message.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (message.mediaPath.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(message.mediaPath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Memory question and answer
              Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unlocked with memory: "${message.question}"',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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
  
  Widget _buildCreateForm(BuildContext context, SoulKeyService service) {
    // List of colors to choose from
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];
    
    // Default color
    Color selectedColor = colors[0];
    
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          blur: 10,
          opacity: 0.1,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.create,
                      color: Colors.purple.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'CREATE SOUL KEY MESSAGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: () {
                        setState(() {
                          _showCreateForm = false;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Recipient
                TextField(
                  controller: _receiverController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Recipient',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.white60),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Message content
                TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Memory question
                TextField(
                  controller: _questionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Memory Question',
                    hintText: 'e.g., "What did we eat in Tokyo?"',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.help_outline, color: Colors.white60),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Memory answer
                TextField(
                  controller: _answerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Memory Answer',
                    hintText: 'Case insensitive answer',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.check, color: Colors.white60),
                  ),
                  obscureText: true,
                ),
                
                const SizedBox(height: 24),
                
                // Color selector
                Row(
                  children: [
                    Icon(
                      Icons.color_lens,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'COLOR:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ...colors.map((color) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color 
                                    ? Colors.white 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_receiverController.text.isEmpty ||
                          _messageController.text.isEmpty ||
                          _questionController.text.isEmpty ||
                          _answerController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      await service.createMessage(
                        receiver: _receiverController.text,
                        content: _messageController.text,
                        question: _questionController.text,
                        answer: _answerController.text,
                        color: selectedColor,
                      );
                      
                      // Reset form and hide it
                      _receiverController.clear();
                      _messageController.clear();
                      _questionController.clear();
                      _answerController.clear();
                      
                      setState(() {
                        _showCreateForm = false;
                      });
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Soul Key message created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: Colors.purple,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Text(
                      'CREATE SOUL KEY MESSAGE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _showCreateForm = true;
        });
      },
      backgroundColor: Colors.purple,
      child: const Icon(Icons.add),
    );
  }
  
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.purple.withOpacity(0.5),
              width: 1,
            ),
          ),
          title: const Text(
            'SOUL KEY MESSAGES',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Soul Key Messages are locked with a personal memory that only you and the recipient would know, plus biometric verification.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '• Create a message with a memory question',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Receiver must answer the question correctly',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Biometric verification is required to unlock',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Limited number of unlock attempts',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Perfect for special, meaningful messages',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Future<void> _tryUnlockMessage(SoulKeyMessage message, SoulKeyService service, String answer) async {
    final success = await service.tryUnlockMessage(
      messageId: message.id,
      answer: answer,
      context: context,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message unlocked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear the text field
      _answerControllers[message.id]?.clear();
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.remainingAttempts > 0 
                ? 'Incorrect answer. ${message.remainingAttempts} attempts remaining.'
                : 'Message is now permanently locked.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class NeuralNetworkPainter extends CustomPainter {
  final Animation<double> animation;
  final int nodeCount = 40;
  final double connectionDistance = 150.0;
  
  NeuralNetworkPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final width = size.width;
    final height = size.height;
    
    // Background gradient
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E0033),
          Color(0xFF000023),
          Color(0xFF000010),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    // Generate random nodes
    List<Offset> nodes = List.generate(nodeCount, (index) {
      return Offset(
        random.nextDouble() * width,
        random.nextDouble() * height,
      );
    });
    
    // Make some nodes move
    for (int i = 0; i < nodes.length; i++) {
      if (i % 3 == 0) {  // Only move every third node
        final phase = i / nodeCount * 2 * math.pi;
        final dx = math.sin(animation.value * 2 * math.pi + phase) * 20;
        final dy = math.cos(animation.value * 2 * math.pi + phase) * 20;
        nodes[i] = Offset(
          (nodes[i].dx + dx).clamp(0, width),
          (nodes[i].dy + dy).clamp(0, height),
        );
      }
    }
    
    // Draw connections between nodes
    final linePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final distance = (nodes[i] - nodes[j]).distance;
        
        if (distance < connectionDistance) {
          // Gradually fade connections based on distance
          final opacity = (1 - distance / connectionDistance) * 0.3;
          final distanceColor = Color.lerp(
            Colors.purple.withOpacity(opacity),
            Colors.blue.withOpacity(opacity),
            distance / connectionDistance,
          )!;
          
          // Data pulse effect
          final pulsePosition = (animation.value + (i * j) % 10 / 10) % 1.0;
          final pulsePath = Path()
            ..moveTo(nodes[i].dx, nodes[i].dy)
            ..lineTo(
              nodes[i].dx + (nodes[j].dx - nodes[i].dx) * pulsePosition,
              nodes[i].dy + (nodes[j].dy - nodes[i].dy) * pulsePosition,
            );
          
          // Draw connection line
          linePaint.color = distanceColor;
          canvas.drawLine(nodes[i], nodes[j], linePaint);
          
          // Draw pulse
          final pulsePaint = Paint()
            ..color = Colors.white.withOpacity(0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
          
          if (random.nextInt(10) == 0) {  // Only show pulses on some connections
            canvas.drawPath(pulsePath, pulsePaint);
          }
        }
      }
    }
    
    // Draw nodes
    final nodePaint = Paint()
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < nodes.length; i++) {
      // Give each node a different size and color
      final nodeSize = 2.0 + random.nextDouble() * 3.0;
      final pulseScale = 1.0 + math.sin(animation.value * 2 * math.pi + i) * 0.3;
      final hue = (220 + random.nextDouble() * 60) % 360;  // Blue to purple hues
      
      // Draw glow
      final glowPaint = Paint()
        ..color = HSVColor.fromAHSV(0.3, hue, 0.8, 0.8).toColor()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(nodes[i], nodeSize * pulseScale * 1.5, glowPaint);
      
      // Draw node
      nodePaint.color = HSVColor.fromAHSV(0.9, hue, 0.8, 0.9).toColor();
      canvas.drawCircle(nodes[i], nodeSize * pulseScale, nodePaint);
    }
  }
  
  @override
  bool shouldRepaint(NeuralNetworkPainter oldDelegate) => true;
} 