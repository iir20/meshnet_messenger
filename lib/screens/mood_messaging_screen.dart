import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../services/mood_messaging_service.dart';
import '../widgets/glass_card.dart';

class MoodMessagingScreen extends StatefulWidget {
  const MoodMessagingScreen({Key? key}) : super(key: key);

  @override
  _MoodMessagingScreenState createState() => _MoodMessagingScreenState();
}

class _MoodMessagingScreenState extends State<MoodMessagingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _messageController = TextEditingController();
  String _previewText = "Your message will adapt to the receiver's mood...";
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
    final moodService = Provider.of<MoodMessagingService>(context);
    final currentMood = moodService.currentMood;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated mood background
          CustomPaint(
            painter: MoodBackgroundPainter(
              animation: _animationController,
              mood: currentMood,
            ),
            size: MediaQuery.of(context).size,
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                
                // Mood selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildMoodSelector(moodService),
                ),
                
                // Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildSettingsPanel(moodService),
                ),
                
                // Message preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildMessagePreview(moodService),
                ),
                
                // Message input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildMessageInput(moodService),
                ),
                
                // Example messages
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildExampleMessages(moodService),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.mood,
            color: Colors.purple.withOpacity(0.8),
            size: 32,
          ),
          const SizedBox(width: 12),
          const Text(
            'MOOD-SHIFT MESSAGING',
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
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMoodSelector(MoodMessagingService moodService) {
    return GlassCard(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.purple.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                const Text(
                  'CURRENT MOOD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: moodService.availableMoods.map((mood) {
                  final isSelected = mood.id == moodService.currentMood.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => moodService.setMood(mood.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected ? mood.gradient : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? mood.color : Colors.white.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: mood.color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: mood.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: mood.color.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mood.name.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsPanel(MoodMessagingService moodService) {
    return GlassCard(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.purple.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                const Text(
                  'MOOD SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text(
                'Adapt messages to mood',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Changes text style based on detected mood',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              value: moodService.adaptMessagesToMood,
              onChanged: (value) => moodService.toggleMessageAdaptation(),
              activeColor: Colors.purple,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text(
                'Adapt UI to mood',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Changes message bubbles and animations',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              value: moodService.adaptUIToMood,
              onChanged: (value) => moodService.toggleUIAdaptation(),
              activeColor: Colors.purple,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text(
                'Camera mood detection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Uses front camera to detect your mood',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              value: moodService.useCameraForMoodDetection,
              onChanged: (value) => moodService.toggleCameraMoodDetection(),
              activeColor: Colors.purple,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessagePreview(MoodMessagingService moodService) {
    final currentMood = moodService.currentMood;
    final bubbleStyle = moodService.getMessageBubbleStyle();
    
    return GlassCard(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Colors.purple.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                const Text(
                  'MESSAGE PREVIEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: bubbleStyle.gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: currentMood.color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                moodService.applyMoodToMessage(_previewText),
                style: bubbleStyle.fontStyle.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Current mood: ${currentMood.name}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageInput(MoodMessagingService moodService) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type a message to preview...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.purple,
                ),
              ),
            ),
            onChanged: (text) {
              setState(() {
                _previewText = text.isEmpty 
                    ? "Your message will adapt to the receiver's mood..." 
                    : text;
                
                // Detect mood from text for demo purposes
                if (text.isNotEmpty) {
                  final detectedMood = moodService.detectMoodFromText(text);
                  moodService.setMood(detectedMood);
                }
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            // In a real app, this would send the message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mood-Shifting message sent!'),
                backgroundColor: Colors.purple,
              ),
            );
            setState(() {
              _messageController.clear();
              _previewText = "Your message will adapt to the receiver's mood...";
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.withOpacity(0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Colors.purple,
                width: 1.5,
              ),
            ),
          ),
          child: const Icon(Icons.send),
        ),
      ],
    );
  }
  
  Widget _buildExampleMessages(MoodMessagingService moodService) {
    final exampleMessages = [
      "I'm so excited about this new project!",
      "Just relaxing with a good book and a cup of tea.",
      "Need to focus on getting this task done.",
      "I have a great creative idea for the design!",
      "Just thinking about what to do this weekend.",
      "Feeling pretty good about how things are going.",
    ];
    
    return GlassCard(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.purple.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                const Text(
                  'EXAMPLE MESSAGES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  'Try clicking!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: exampleMessages.length,
                itemBuilder: (context, index) {
                  final message = exampleMessages[index];
                  final detectedMood = moodService.detectMoodFromText(message);
                  final bubbleStyle = moodService.getMessageBubbleStyle(
                    overrideMoodId: detectedMood,
                  );
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _messageController.text = message;
                        _previewText = message;
                        moodService.setMood(detectedMood);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: bubbleStyle.gradient.scale(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: moodService._getMoodById(detectedMood).color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moodService.applyMoodToMessage(
                              message,
                              overrideMoodId: detectedMood,
                            ),
                            style: bubbleStyle.fontStyle.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: moodService._getMoodById(detectedMood).color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                moodService._getMoodById(detectedMood).name,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
            'MOOD-SHIFT MESSAGING',
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
                'Mood-Shift adapts your messages based on the emotional state of you and your recipient.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '• Messages adapt their style to the mood',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Visual elements change with emotions',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Text formatting shifts for emotional context',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Can use camera to detect your mood',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Creates emotional resonance in conversations',
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
}

class MoodBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final MoodState mood;
  
  MoodBackgroundPainter({required this.animation, required this.mood}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Background gradient based on mood
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(Colors.black.withOpacity(0.7), mood.color.withOpacity(0.3)),
          Color.alphaBlend(Colors.black.withOpacity(0.9), mood.color.withOpacity(0.1)),
          Colors.black,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    // Draw particles/mood elements
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42);
    final particleCount = 100;
    
    for (int i = 0; i < particleCount; i++) {
      // Give each particle a different position, size, and opacity
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      
      // Animate position with time
      final offset = 20.0 * mood.animationIntensity;
      final dx = math.sin(animation.value * 2 * math.pi + i) * offset;
      final dy = math.cos(animation.value * 2 * math.pi + i * 0.7) * offset;
      
      final particleSize = 1.0 + random.nextDouble() * 3.0 * mood.animationIntensity;
      final opacity = 0.1 + random.nextDouble() * 0.3;
      
      // Create mood-specific particle pattern
      // More intense for excited/happy, more sparse for calm/focused
      if (i % (4 - mood.animationIntensity.round().clamp(0, 3)) == 0) {
        particlePaint.color = mood.color.withOpacity(opacity);
        canvas.drawCircle(Offset(x + dx, y + dy), particleSize, particlePaint);
      }
    }
    
    // Draw mood-specific pattern elements
    final patternPaint = Paint()
      ..color = mood.color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Different patterns based on mood
    switch (mood.id) {
      case 'excited':
        // Radiating circles
        for (int i = 0; i < 5; i++) {
          final radius = 100.0 + i * 50.0 + animation.value * 100.0;
          canvas.drawCircle(
            Offset(width / 2, height / 3),
            radius % 300.0,
            patternPaint,
          );
        }
        break;
      
      case 'creative':
        // Swirls
        for (int i = 0; i < 5; i++) {
          final path = Path();
          final startAngle = animation.value * 2 * math.pi;
          final sweepAngle = math.pi + i * 0.2;
          path.addArc(
            Rect.fromCenter(
              center: Offset(width / 2, height / 3),
              width: 200.0 + i * 50.0,
              height: 200.0 + i * 30.0,
            ),
            startAngle,
            sweepAngle,
          );
          canvas.drawPath(path, patternPaint);
        }
        break;
      
      case 'calm':
        // Gentle horizontal lines
        for (int i = 0; i < 10; i++) {
          final y = height / 4 + i * 30.0 + math.sin(animation.value * 2 * math.pi) * 5.0;
          canvas.drawLine(
            Offset(width * 0.2, y),
            Offset(width * 0.8, y),
            patternPaint,
          );
        }
        break;
      
      case 'focused':
        // Concentric squares
        for (int i = 0; i < 5; i++) {
          final size = 100.0 + i * 40.0 + animation.value * 20.0;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(width / 2, height / 3),
              width: size,
              height: size,
            ),
            patternPaint,
          );
        }
        break;
      
      case 'happy':
        // Bubbly circles
        for (int i = 0; i < 20; i++) {
          final x = width * 0.2 + random.nextDouble() * width * 0.6;
          final y = height * 0.1 + random.nextDouble() * height * 0.5;
          final size = 10.0 + random.nextDouble() * 30.0;
          final offset = math.sin(animation.value * 2 * math.pi + i) * 20.0;
          
          canvas.drawCircle(
            Offset(x, y + offset),
            size,
            patternPaint,
          );
        }
        break;
      
      case 'reflective':
        // Ripples
        for (int i = 0; i < 5; i++) {
          final progress = (animation.value + i * 0.2) % 1.0;
          final radius = progress * 200.0;
          patternPaint.color = mood.color.withOpacity(0.2 * (1.0 - progress));
          
          canvas.drawCircle(
            Offset(width / 2, height / 3),
            radius,
            patternPaint,
          );
        }
        break;
      
      default: // neutral
        // Grid
        for (int i = 0; i < 10; i++) {
          final x = width * 0.1 + i * width * 0.08;
          final y = height * 0.1 + i * height * 0.05;
          
          canvas.drawLine(
            Offset(x, height * 0.1),
            Offset(x, height * 0.6),
            patternPaint,
          );
          
          canvas.drawLine(
            Offset(width * 0.1, y),
            Offset(width * 0.9, y),
            patternPaint,
          );
        }
        break;
    }
  }
  
  @override
  bool shouldRepaint(MoodBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.mood.id != mood.id;
  }
} 