import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/time_capsule_service.dart';
import '../widgets/glass_card.dart';

class TimeCapsuleScreen extends StatefulWidget {
  const TimeCapsuleScreen({Key? key}) : super(key: key);

  @override
  _TimeCapsuleScreenState createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen> with TickerProviderStateMixin {
  late AnimationController _clockController;
  late AnimationController _pulseController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  
  DateTime _selectedUnlockTime = DateTime.now().add(const Duration(days: 1));
  bool _showCreateForm = false;
  
  @override
  void initState() {
    super.initState();
    _clockController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _clockController.dispose();
    _pulseController.dispose();
    _messageController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = 'user123'; // TODO: Get from auth service
    final timeCapsuleService = Provider.of<TimeCapsuleService>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Spacetime background
          CustomPaint(
            painter: SpacetimePainter(
              animation: _clockController,
            ),
            size: MediaQuery.of(context).size,
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                
                // Time capsule list or create form
                Expanded(
                  child: _showCreateForm
                      ? _buildCreateForm(context, userId)
                      : _buildMessageList(timeCapsuleService),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }
  
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _clockController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _clockController.value * 2 * pi,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.7),
                        Colors.purple.withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          const Text(
            "TIME CAPSULE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white60),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageList(TimeCapsuleService service) {
    final pendingMessages = service.pendingMessages;
    final unlockedMessages = service.unlockedMessages;
    
    if (pendingMessages.isEmpty && unlockedMessages.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingMessages.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              "PENDING MESSAGES",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          ...pendingMessages.map((msg) => _buildPendingMessageCard(msg, service)),
          const SizedBox(height: 24),
        ],
        
        if (unlockedMessages.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              "UNLOCKED MESSAGES",
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          ...unlockedMessages.map((msg) => _buildUnlockedMessageCard(msg, service)),
        ],
      ],
    );
  }
  
  Widget _buildPendingMessageCard(TimeCapsuleMessage message, TimeCapsuleService service) {
    final timeLeft = message.timeRemaining;
    final String timeLeftText;
    
    if (timeLeft.inDays > 0) {
      timeLeftText = '${timeLeft.inDays} days left';
    } else if (timeLeft.inHours > 0) {
      timeLeftText = '${timeLeft.inHours} hours left';
    } else if (timeLeft.inMinutes > 0) {
      timeLeftText = '${timeLeft.inMinutes} minutes left';
    } else {
      timeLeftText = 'Unlocking soon';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        blur: 10,
        opacity: 0.15,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: message.color.withOpacity(0.3),
                    child: Icon(
                      Icons.lock_clock,
                      color: message.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "To: ${message.receiver}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "From: ${message.sender}",
                        style: const TextStyle(
                          color: Colors.white70,
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
              Text(
                "Message locked until ${message.unlockTime.toLocal().toString().substring(0, 16)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 1 - (timeLeft.inSeconds / message.unlockTime.difference(message.createdAt).inSeconds),
                  valueColor: AlwaysStoppedAnimation<Color>(message.color),
                  backgroundColor: Colors.white12,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeLeftText,
                    style: TextStyle(
                      color: message.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: message.canUnlock
                        ? () async {
                            final unlocked = await service.tryUnlockMessage(message.id);
                            if (unlocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Message unlocked!')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to unlock message')),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      primary: message.color.withOpacity(0.3),
                      onPrimary: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("UNLOCK"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUnlockedMessageCard(TimeCapsuleMessage message, TimeCapsuleService service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        blur: 10,
        opacity: 0.2,
        borderRadius: BorderRadius.circular(16),
        borderColor: message.color.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: message.color.withOpacity(0.4),
                    child: Icon(
                      Icons.lock_open,
                      color: message.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.sender,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Unlocked on ${DateTime.now().toLocal().toString().substring(0, 16)}",
                        style: const TextStyle(
                          color: Colors.white70,
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: message.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: message.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              if (message.mediaPath != null) ...[
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(message.mediaPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                "Created on ${message.createdAt.toLocal().toString().substring(0, 16)}",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withOpacity(0.7),
                  Colors.purple.withOpacity(0.1),
                ],
              ),
            ),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Icon(
                  Icons.hourglass_empty,
                  color: Colors.white.withOpacity(_pulseController.value),
                  size: 60,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "NO TIME CAPSULES",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 250,
            child: Text(
              "Create your first time capsule by tapping the + button",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCreateForm(BuildContext context, String userId) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];
    
    // Default to blue
    Color selectedColor = colors[0];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        blur: 10,
        opacity: 0.15,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timeline, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    "CREATE TIME CAPSULE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
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
              const SizedBox(height: 20),
              TextField(
                controller: _receiverController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Recipient",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.person, color: Colors.white60),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: "Message",
                  labelStyle: const TextStyle(color: Colors.white70),
                  alignLabelWithHint: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.color_lens, color: Colors.white60),
                  const SizedBox(width: 8),
                  const Text(
                    "Color:",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  ...colors.map((color) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        height: 24,
                        width: 24,
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
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.white60),
                  const SizedBox(width: 8),
                  const Text(
                    "Unlock Time:",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedUnlockTime,
                          firstDate: now.add(const Duration(minutes: 5)),
                          lastDate: now.add(const Duration(days: 365 * 10)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.blue,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF121212),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF121212),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedUnlockTime),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Colors.blue,
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF121212),
                                    onSurface: Colors.white,
                                  ),
                                  dialogBackgroundColor: const Color(0xFF121212),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            setState(() {
                              _selectedUnlockTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                      child: Text(
                        _selectedUnlockTime.toString().substring(0, 16),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_messageController.text.isEmpty || 
                        _receiverController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    
                    final service = Provider.of<TimeCapsuleService>(context, listen: false);
                    service.createMessage(
                      receiver: _receiverController.text,
                      content: _messageController.text,
                      color: selectedColor,
                      unlockTime: _selectedUnlockTime,
                    );
                    
                    // Reset form
                    _messageController.clear();
                    _receiverController.clear();
                    setState(() {
                      _showCreateForm = false;
                      _selectedUnlockTime = DateTime.now().add(const Duration(days: 1));
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Time Capsule created!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "SEAL TIME CAPSULE",
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
    );
  }
  
  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5 * _pulseController.value),
                blurRadius: 12,
                spreadRadius: 4 * _pulseController.value,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showCreateForm = true;
              });
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, size: 30),
          ),
        );
      }
    );
  }
  
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.withOpacity(0.5), width: 1),
        ),
        title: const Text(
          "TIME CAPSULE INFO",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Time Capsule allows you to send messages that are locked until a specific time in the future.",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "• Messages are encrypted and tamper-proof",
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              "• Set any unlock date up to 10 years in the future",
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              "• Recipients will be notified when a message unlocks",
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              "• Perfect for future surprises, predictions, or reminders",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("CLOSE", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

class SpacetimePainter extends CustomPainter {
  final Animation<double> animation;
  final int starCount = 100;
  final Random random = Random(42);

  SpacetimePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw space background
    Paint backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF000428),
          const Color(0xFF000F2B),
          const Color(0xFF001F64),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw stars
    for (int i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2.0 + 0.5;
      final brightness = random.nextDouble() * 0.5 + 0.5;
      
      final starOpacity = (0.5 + 0.5 * sin(animation.value * 2 * pi + i)) * brightness;
      
      paint.color = Colors.white.withOpacity(starOpacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw time waves
    for (int i = 0; i < 3; i++) {
      final wavePhase = i * pi / 3;
      final wavePeriod = (i + 1) * 3.0;
      final waveAmplitude = 20.0 - i * 5.0;
      final waveOpacity = 0.1 - i * 0.02;
      
      paint.color = Colors.blue.withOpacity(waveOpacity);
      
      final path = Path();
      path.moveTo(0, size.height / 2);
      
      for (double x = 0; x < size.width; x += 5) {
        final sinValue = sin(x / 30 + animation.value * 2 * pi * wavePeriod + wavePhase);
        final y = size.height / 2 + sinValue * waveAmplitude;
        path.lineTo(x, y);
      }
      
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      
      canvas.drawPath(path, paint);
    }
    
    // Draw time particles
    final particleCount = 8;
    final particleRadius = 4.0;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = 2 * pi * i / particleCount + animation.value * 2 * pi;
      final orbitRadius = 80.0;
      
      final x = size.width / 2 + cos(angle) * orbitRadius;
      final y = size.height / 2 + sin(angle) * orbitRadius;
      
      paint.color = Colors.blue.withOpacity(0.8);
      canvas.drawCircle(Offset(x, y), particleRadius, paint);
      
      // Trail
      for (int j = 1; j <= 5; j++) {
        final trailAngle = angle - j * 0.1;
        final trailX = size.width / 2 + cos(trailAngle) * orbitRadius;
        final trailY = size.height / 2 + sin(trailAngle) * orbitRadius;
        
        paint.color = Colors.blue.withOpacity(0.15 - j * 0.02);
        canvas.drawCircle(Offset(trailX, trailY), particleRadius - j * 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SpacetimePainter oldDelegate) => true;
} 