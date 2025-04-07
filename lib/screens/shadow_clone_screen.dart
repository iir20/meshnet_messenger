import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/shadow_clone_service.dart';

class ShadowCloneScreen extends StatefulWidget {
  const ShadowCloneScreen({Key? key}) : super(key: key);

  @override
  _ShadowCloneScreenState createState() => _ShadowCloneScreenState();
}

class _ShadowCloneScreenState extends State<ShadowCloneScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  
  // Mock chat messages for training
  final List<Map<String, dynamic>> _mockMessages = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    
    // Generate mock messages for training
    _generateMockMessages();
  }
  
  void _generateMockMessages() {
    final users = ['Alex', 'Morgan', 'Taylor', 'Sam'];
    final responses = [
      'Hey, how are you doing?',
      'Did you check out the new features?',
      'Let\'s meet up later to discuss the mesh network.',
      'I\'ve been working on the encryption modules all day! 🔒',
      'Do you think we should implement quantum-resistant encryption yet?',
      'The UI looks amazing, great job on the holographic elements.',
      'Send me the details when you get a chance.',
      'I\'m going offline for a while, the mesh network should forward my messages.',
      'Have you tested the AR story projection feature?',
      'Just deployed the new version, let me know what you think!',
    ];
    
    final yourResponses = [
      'I\'m good, thanks for asking!',
      'Yes, the new features look awesome. I particularly like the time capsule messaging.',
      'Sure, let\'s meet at the usual spot around 7pm?',
      'Security is super important, nice work on the encryption! 👍',
      'I think we should wait until we have more users before implementing quantum encryption.',
      'Thanks! I spent a lot of time on those holographic effects.',
      'Will do, I\'ll send you everything this evening.',
      'The mesh routing should work perfectly, we\'ve been testing it extensively.',
      'The AR projections are working well on newer devices, still some glitches on older ones.',
      'Just checked it out, impressive work! A few minor UI tweaks might be needed.',
    ];
    
    final random = math.Random();
    final now = DateTime.now();
    
    for (int i = 0; i < 50; i++) {
      final isMe = i % 2 == 0;
      final user = isMe ? 'You' : users[random.nextInt(users.length)];
      final text = isMe 
          ? yourResponses[random.nextInt(yourResponses.length)] 
          : responses[random.nextInt(responses.length)];
      
      _mockMessages.add({
        'id': 'msg_$i',
        'text': text,
        'isMe': isMe,
        'timestamp': now.subtract(Duration(minutes: (50 - i) * 10)),
        'senderName': user,
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shadowCloneService = Provider.of<ShadowCloneService>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Shadow Clone',
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
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCloneStatusCard(shadowCloneService),
                    const SizedBox(height: 16),
                    if (shadowCloneService.isLearning)
                      _buildLearningProgressCard(shadowCloneService)
                    else
                      _buildPersonalitySettingsCard(shadowCloneService),
                    const SizedBox(height: 16),
                    _buildTrainingCard(shadowCloneService),
                    const SizedBox(height: 16),
                    _buildTestCloneCard(shadowCloneService),
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
            painter: ShadowCloneBackgroundPainter(
              animation: _animationController,
            ),
            child: Container(),
          ),
        );
      },
    );
  }
  
  Widget _buildCloneStatusCard(ShadowCloneService service) {
    return _buildCard(
      title: 'Shadow Clone Status',
      icon: Icons.person_outline,
      iconColor: Colors.cyan,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: service.isActive ? Colors.green : Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    service.hasInitialModel
                        ? 'Trained on ${service.analyzedMessageCount} messages'
                        : 'Not yet trained',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (service.lastTrainingDate != null)
                    Text(
                      'Last trained: ${_formatDate(service.lastTrainingDate!)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyan.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: service.isActive 
                              ? Colors.cyan.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          border: Border.all(
                            color: service.isActive
                                ? Colors.cyan.withOpacity(0.8)
                                : Colors.grey.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: service.isActive ? Colors.cyan : Colors.grey,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: service.isActive
                      ? Colors.red.withOpacity(0.2)
                      : Colors.cyan.withOpacity(0.2),
                  foregroundColor: service.isActive ? Colors.red : Colors.cyan,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: service.isActive
                          ? Colors.red.withOpacity(0.5)
                          : Colors.cyan.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
                onPressed: () {
                  if (!service.hasInitialModel && !service.isActive) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Train your shadow clone before activating it'),
                        backgroundColor: Colors.amber,
                      ),
                    );
                    return;
                  }
                  
                  service.toggleActive();
                  HapticFeedback.mediumImpact();
                },
                icon: Icon(
                  service.isActive ? Icons.power_settings_new : Icons.person_add,
                  size: 18,
                ),
                label: Text(service.isActive ? 'Deactivate' : 'Activate'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: service.autoReplyEnabled
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  foregroundColor: service.autoReplyEnabled ? Colors.amber : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: service.autoReplyEnabled
                          ? Colors.amber.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
                onPressed: () {
                  if (!service.hasInitialModel) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Train your shadow clone before enabling auto-reply'),
                        backgroundColor: Colors.amber,
                      ),
                    );
                    return;
                  }
                  
                  service.toggleAutoReply();
                  HapticFeedback.selectionClick();
                },
                icon: Icon(
                  service.autoReplyEnabled ? Icons.comment : Icons.comment_outlined,
                  size: 18,
                ),
                label: Text(service.autoReplyEnabled ? 'Auto-Reply ON' : 'Auto-Reply OFF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLearningProgressCard(ShadowCloneService service) {
    return _buildCard(
      title: 'Learning Progress',
      icon: Icons.psychology,
      iconColor: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training your shadow clone...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: service.learningProgress / 100,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${service.learningProgress}% complete',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your shadow clone is analyzing message patterns, word usage, and communication style to learn how to respond like you when you\'re offline.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.memory,
                    color: Colors.purple.withOpacity(0.8),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Training neural network',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please wait until the training completes',
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
    );
  }
  
  Widget _buildPersonalitySettingsCard(ShadowCloneService service) {
    return _buildCard(
      title: 'Personality Settings',
      icon: Icons.settings,
      iconColor: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize how your shadow clone behaves',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Response Delay',
            icon: Icons.timer,
            value: service.responseDelay / 10,
            min: "Faster (0.5s)",
            max: "Slower (10s)",
            onChanged: (value) {
              service.setResponseDelay(value * 10);
            },
          ),
          _buildSliderSetting(
            label: 'Reply Probability',
            icon: Icons.reply,
            value: service.replyProbability,
            min: "Selective",
            max: "Responsive",
            onChanged: (value) {
              service.setReplyProbability(value);
            },
          ),
          _buildSliderSetting(
            label: 'Verbosity',
            icon: Icons.textsms,
            value: service.verbosityLevel,
            min: "Terse",
            max: "Verbose",
            onChanged: (value) {
              service.setVerbosityLevel(value);
            },
          ),
          _buildSliderSetting(
            label: 'Formality',
            icon: Icons.business,
            value: service.formalityLevel,
            min: "Casual",
            max: "Formal",
            onChanged: (value) {
              service.setFormalityLevel(value);
            },
          ),
          _buildSliderSetting(
            label: 'Emotional Expression',
            icon: Icons.emoji_emotions,
            value: service.emotionalLevel,
            min: "Neutral",
            max: "Expressive",
            onChanged: (value) {
              service.setEmotionalLevel(value);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSliderSetting({
    required String label,
    required IconData icon,
    required double value,
    required String min,
    required String max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.orange.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              min,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.orange,
                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.orange.withOpacity(0.3),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: value,
                  onChanged: (newValue) {
                    HapticFeedback.selectionClick();
                    onChanged(newValue);
                  },
                ),
              ),
            ),
            Text(
              max,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildTrainingCard(ShadowCloneService service) {
    return _buildCard(
      title: 'Train Your Shadow Clone',
      icon: Icons.school,
      iconColor: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Train your AI clone on your message history',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Training will analyze your past messages to learn your communication style.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'All data remains on-device for maximum privacy. At least 100 messages are recommended for good results.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
                onPressed: service.isLearning
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        await service.startLearning(_mockMessages);
                      },
                icon: const Icon(Icons.smart_toy, size: 18),
                label: const Text('Start Training'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.red.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
                onPressed: service.isLearning || !service.hasInitialModel
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        final result = await _showResetConfirmation(context);
                        if (result == true) {
                          await service.clearModel();
                        }
                      },
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Reset Clone'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestCloneCard(ShadowCloneService service) {
    final TextEditingController messageController = TextEditingController();
    final ValueNotifier<String> responseNotifier = ValueNotifier<String>('');
    
    return _buildCard(
      title: 'Test Your Shadow Clone',
      icon: Icons.psychology_alt,
      iconColor: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send a test message to see how your clone would respond',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white10,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message to test...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple),
                  onPressed: () async {
                    if (messageController.text.trim().isEmpty) return;
                    
                    HapticFeedback.mediumImpact();
                    
                    // Generate response from shadow clone
                    final response = await service.generateResponse(messageController.text);
                    responseNotifier.value = response;
                    
                    // Clear input
                    messageController.clear();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.smart_toy,
                        color: Colors.purple.withOpacity(0.8),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Shadow Clone Response',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<String>(
                  valueListenable: responseNotifier,
                  builder: (context, response, child) {
                    return response.isEmpty
                        ? Text(
                            service.hasInitialModel
                                ? 'Send a message to see your clone\'s response'
                                : 'Train your clone first to enable responses',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Text(
                            response,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          );
                  },
                ),
              ],
            ),
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
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  Future<bool?> _showResetConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.red.withOpacity(0.5),
              width: 1,
            ),
          ),
          title: const Text(
            'Reset Shadow Clone?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This will erase all learned patterns and personality settings. You will need to retrain your shadow clone. This action cannot be undone.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                foregroundColor: Colors.white,
              ),
              child: const Text('RESET'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }
}

class ShadowCloneBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  
  ShadowCloneBackgroundPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw digital/neural network background
    final gridSize = 40.0;
    final nodeRadius = 1.5;
    
    // Calculate grid dimensions
    final horizontalNodes = (size.width / gridSize).ceil() + 1;
    final verticalNodes = (size.height / gridSize).ceil() + 1;
    
    // Draw nodes
    for (int x = 0; x < horizontalNodes; x++) {
      for (int y = 0; y < verticalNodes; y++) {
        final xPos = x * gridSize;
        final yPos = y * gridSize;
        
        // Create wave-like movement
        final offset = math.sin((x + y) / 5 + animation.value * math.pi * 2) * 10;
        
        final nodePaint = Paint()
          ..color = Color.fromRGBO(
            100, 
            200, 
            255, 
            0.1 + 0.1 * math.sin(animation.value * math.pi * 2 + (x + y) / 5),
          )
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(xPos, yPos + offset),
          nodeRadius,
          nodePaint,
        );
        
        // Draw connections to adjacent nodes
        if (x < horizontalNodes - 1) {
          final nextOffset = math.sin((x + 1 + y) / 5 + animation.value * math.pi * 2) * 10;
          
          final linePaint = Paint()
            ..color = Color.fromRGBO(
              100,
              200,
              255,
              0.05 + 0.05 * math.sin(animation.value * math.pi * 2 + (x + y) / 3),
            )
            ..strokeWidth = 0.5;
          
          canvas.drawLine(
            Offset(xPos, yPos + offset),
            Offset(xPos + gridSize, yPos + nextOffset),
            linePaint,
          );
        }
        
        if (y < verticalNodes - 1) {
          final nextOffset = math.sin((x + y + 1) / 5 + animation.value * math.pi * 2) * 10;
          
          final linePaint = Paint()
            ..color = Color.fromRGBO(
              100,
              200,
              255,
              0.05 + 0.05 * math.sin(animation.value * math.pi * 2 + (x + y) / 3),
            )
            ..strokeWidth = 0.5;
          
          canvas.drawLine(
            Offset(xPos, yPos + offset),
            Offset(xPos, yPos + gridSize + nextOffset),
            linePaint,
          );
        }
      }
    }
    
    // Draw brain-like curves
    paint
      ..color = Colors.purple.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final startX = size.width * 0.2 + i * size.width * 0.15;
      final startY = size.height * 0.3;
      
      path.moveTo(startX, startY);
      
      for (double t = 0; t < 1.0; t += 0.05) {
        final x = startX + math.sin(t * math.pi * 3 + animation.value * math.pi * 2) * 50;
        final y = startY + t * size.height * 0.5;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
    
    // Draw data flow particles
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;
    
    final particleCount = 30;
    for (int i = 0; i < particleCount; i++) {
      final progress = (animation.value + i / particleCount) % 1.0;
      final particleSize = 1.0 + (i % 3);
      
      // Calculate bezier curve path position
      final t = progress;
      final bezierX = size.width * 0.2 + (size.width * 0.6) * t;
      final bezierY = size.height * 0.2 + 
        math.sin(t * math.pi * 2) * 100 + 
        t * size.height * 0.5;
      
      final alpha = math.sin(progress * math.pi);
      
      particlePaint.color = Colors.cyan.withOpacity(alpha * 0.5);
      canvas.drawCircle(Offset(bezierX, bezierY), particleSize, particlePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant ShadowCloneBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
} 