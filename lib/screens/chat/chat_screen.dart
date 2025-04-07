import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:secure_mesh_messenger/models/chat.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/models/peer.dart';
import 'package:secure_mesh_messenger/providers/auth_provider.dart';
import 'package:secure_mesh_messenger/providers/message_provider.dart';
import 'package:secure_mesh_messenger/providers/mesh_provider.dart';
import 'package:secure_mesh_messenger/providers/theme_provider.dart';
import 'package:secure_mesh_messenger/services/ar_service.dart';
import 'package:secure_mesh_messenger/services/emergency_service.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:secure_mesh_messenger/widgets/chat/ar_message_bubble.dart';
import 'package:secure_mesh_messenger/widgets/chat/message_bubble.dart';
import 'package:secure_mesh_messenger/widgets/chat/attachment_selector.dart';
import 'package:secure_mesh_messenger/widgets/chat/emotion_theme_indicator.dart';
import 'package:secure_mesh_messenger/widgets/common/encrypted_indicator.dart';
import 'package:secure_mesh_messenger/widgets/common/connection_indicator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();
  final ImagePicker _imagePicker = ImagePicker();
  
  Chat? _chat;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isAttachmentSelectorVisible = false;
  bool _isRecording = false;
  bool _isTyping = false;
  String _currentEmotion = '';
  bool _isSelfDestructModeEnabled = false;
  int _selfDestructTime = 30; // seconds
  bool _isFaceMaskEnabled = false;
  String _currentFaceMask = 'none';
  Timer? _typingTimer;
  
  // AR message creation
  bool _isARMode = false;
  CameraController? _cameraController;
  bool _isARRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load messages
    _loadChat();
    _loadMessages();
    
    // Mark messages as read when opening the chat
    Future.delayed(const Duration(milliseconds: 500), () {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      messageProvider.markChatAsRead(widget.chatId);
    });
    
    // Initialize AR camera if needed
    if (enableARFeatures) {
      _initializeARCamera();
    }
    
    // Listen for emotion detection
    if (enableEmotionAnalysis) {
      final arService = Provider.of<ARService>(context, listen: false);
      arService.onEmotionDetected.listen((emotion) {
        if (mounted && emotion.isNotEmpty && _currentEmotion != emotion) {
          setState(() {
            _currentEmotion = emotion;
          });
          
          // Update theme based on emotion
          final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
          themeProvider.setEmotionTheme(emotion);
        }
      });
    }
  }
  
  Future<void> _initializeARCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize AR camera: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for AR camera
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeARCamera();
    }
  }
  
  Future<void> _loadChat() async {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final chat = await messageProvider.getChat(widget.chatId);
    if (mounted) {
      setState(() {
        _chat = chat;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadMessages() async {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final messages = await messageProvider.getMessages(widget.chatId);
    if (mounted) {
      setState(() {
        _messages = messages;
      });
      
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Check for SOS trigger emojis
    final emergencyService = Provider.of<EmergencyService>(context, listen: false);
    if (emergencyService.isSOSTriggerEmoji(text)) {
      _showSOSConfirmationDialog(text);
      return;
    }
    
    // Clear the text field
    _messageController.clear();
    
    // Get providers
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final localUserId = authProvider.user!.id;
    
    // Create message
    final message = Message.outgoing(
      id: _uuid.v4(),
      chatId: widget.chatId,
      senderId: localUserId,
      content: text,
      type: MessageType.text,
      ttl: _isSelfDestructModeEnabled ? _selfDestructTime : null,
      isSelfDestruct: _isSelfDestructModeEnabled,
    );
    
    // Save and send message
    await messageProvider.sendMessage(message);
    
    // Vibrate
    Vibration.hasVibrator().then((hasVibrator) {
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 20);
      }
    });
    
    // Reload messages
    _loadMessages();
  }
  
  void _showSOSConfirmationDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('SOS Alert'),
        content: const Text(
          'Are you sure you want to send an SOS alert? This will notify your emergency contacts with your location.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _activateSOS('emoji');
              
              // Send message as normal
    _messageController.clear();
              final messageProvider = Provider.of<MessageProvider>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final localUserId = authProvider.user!.id;
              
              final normalMessage = Message.outgoing(
                id: _uuid.v4(),
                chatId: widget.chatId,
                senderId: localUserId,
                content: message,
                type: MessageType.text,
              );
              
              messageProvider.sendMessage(normalMessage);
              _loadMessages();
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _activateSOS(String trigger) async {
    final emergencyService = Provider.of<EmergencyService>(context, listen: false);
    await emergencyService.activateSOS(trigger);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS alert activated. Emergency contacts notified.'),
        backgroundColor: dangerColor,
        duration: Duration(seconds: 5),
      ),
    );
  }
  
  Future<void> _sendImageMessage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (pickedFile == null) return;
      
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      
      // Generate preview thumbnail
      final tempDir = await getTemporaryDirectory();
      final fileName = '${_uuid.v4()}.jpg';
      final savedFile = File('${tempDir.path}/$fileName');
      await savedFile.writeAsBytes(bytes);
      
      // Get providers
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final localUserId = authProvider.user!.id;
      
      // Ask if user wants to embed hidden data in the image
      bool containsHiddenData = false;
      String? hiddenMessage;
      
      if (enableSteganography) {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => _buildSteganographyDialog(),
        );
        
        if (result != null) {
          containsHiddenData = result['containsHiddenData'];
          hiddenMessage = result['message'];
        }
      }
      
      // Create message
      final message = Message.outgoing(
        id: _uuid.v4(),
        chatId: widget.chatId,
        senderId: localUserId,
        content: savedFile.path,
        type: MessageType.image,
        ttl: _isSelfDestructModeEnabled ? _selfDestructTime : null,
        isSelfDestruct: _isSelfDestructModeEnabled,
        containsHiddenData: containsHiddenData,
        metadata: hiddenMessage != null ? {'hiddenMessage': hiddenMessage} : null,
      );
      
      // Save and send message
      await messageProvider.sendMessage(message);
      
      // Reload messages
      _loadMessages();
    } catch (e) {
      debugPrint('Failed to send image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send image: $e'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }
  
  Future<void> _sendFileMessage() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      
      if (result == null || result.files.isEmpty) return;
      
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      
      // Get providers
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final localUserId = authProvider.user!.id;
      
      // Create message
      final message = Message.outgoing(
        id: _uuid.v4(),
        chatId: widget.chatId,
        senderId: localUserId,
        content: file.path,
        type: MessageType.file,
        ttl: _isSelfDestructModeEnabled ? _selfDestructTime : null,
        isSelfDestruct: _isSelfDestructModeEnabled,
        metadata: {'fileName': fileName, 'fileSize': await file.length()},
      );
      
      // Save and send message
      await messageProvider.sendMessage(message);
      
      // Reload messages
      _loadMessages();
    } catch (e) {
      debugPrint('Failed to send file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send file: $e'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }
  
  Future<void> _sendARMessage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not available for AR messages'),
          backgroundColor: dangerColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isARMode = true;
    });
    
    // Show AR recording UI
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildARRecordingDialog(),
    );
    
    if (result != true) {
      setState(() {
        _isARMode = false;
    });
      return;
    }
    
    try {
      // Get providers
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final arService = Provider.of<ARService>(context, listen: false);
      final localUserId = authProvider.user!.id;
      
      // Get recipient ID
      final recipientId = _chat!.participantIds.first; // For 1:1 chats
      
      // Create AR message
      final tempDir = await getTemporaryDirectory();
      final videoPath = '${tempDir.path}/ar_recording_${_uuid.v4()}.mp4';
      final videoFile = File(videoPath);

      // Process AR message with face masking if enabled
      final encryptedARPath = await arService.createARMessage(
        videoData: await videoFile.readAsBytes(),
        recipientId: recipientId,
        applyFaceMask: _isFaceMaskEnabled,
        maskType: _currentFaceMask,
      );
      
      // Create message
      final message = Message.outgoing(
        id: _uuid.v4(),
        chatId: widget.chatId,
        senderId: localUserId,
        content: encryptedARPath,
        type: MessageType.ar,
        ttl: _isSelfDestructModeEnabled ? _selfDestructTime : null,
        isSelfDestruct: _isSelfDestructModeEnabled,
      );
      
      // Save and send message
      await messageProvider.sendMessage(message);
      
      // Delete temporary files
      await videoFile.delete();
      
      // Reload messages
      _loadMessages();
    } catch (e) {
      debugPrint('Failed to send AR message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send AR message: $e'),
          backgroundColor: dangerColor,
        ),
      );
    } finally {
      setState(() {
        _isARMode = false;
      });
    }
  }
  
  void _toggleAttachmentSelector() {
    setState(() {
      _isAttachmentSelectorVisible = !_isAttachmentSelectorVisible;
    });
  }
  
  void _toggleSelfDestructMode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Self-Destruct Timer'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Messages will be destroyed after $_selfDestructTime seconds'),
                Slider(
                  value: _selfDestructTime.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$_selfDestructTime seconds',
                  onChanged: (value) {
                    setStateDialog(() {
                      _selfDestructTime = value.toInt();
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Enable self-destruct'),
                  value: _isSelfDestructModeEnabled,
                  onChanged: (value) {
                    setStateDialog(() {
                      _isSelfDestructModeEnabled = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  void _toggleFaceMasking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Face Masking'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            final arService = Provider.of<ARService>(context, listen: false);
            final masks = arService.getAvailableMasks();
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Enable face mask'),
                  value: _isFaceMaskEnabled,
                  onChanged: (value) {
                    setStateDialog(() {
                      _isFaceMaskEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Select mask:'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _currentFaceMask,
                  isExpanded: true,
                  items: masks.map((mask) {
                    return DropdownMenuItem<String>(
                      value: mask,
                      child: Text(mask.capitalize()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        _currentFaceMask = value;
                      });
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
              
              // Set mask in AR service
              final arService = Provider.of<ARService>(context, listen: false);
              arService.setFaceMask(_currentFaceMask);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSteganographyDialog() {
    bool embedHiddenData = false;
    final messageController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Hidden Message'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Embed hidden message in image'),
            value: embedHiddenData,
            onChanged: (value) {
              setState(() {
                embedHiddenData = value;
              });
            },
          ),
          if (embedHiddenData)
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Hidden message',
                hintText: 'Type secret message to embed',
              ),
              maxLines: 3,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'containsHiddenData': embedHiddenData,
              'message': embedHiddenData ? messageController.text : null,
            });
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
  
  Widget _buildARRecordingDialog() {
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('AR Message'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_cameraController != null && _cameraController!.value.isInitialized)
                  SizedBox(
                    height: 300,
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  )
                else
                  const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _isARRecording
                      ? 'Recording... Tap to stop'
                      : 'Tap to start recording AR message',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(_isFaceMaskEnabled ? Icons.face_retouching_natural : Icons.face),
                      onPressed: () {
                        setStateDialog(() {
                          _isFaceMaskEnabled = !_isFaceMaskEnabled;
                        });
                      },
                      tooltip: 'Toggle face mask',
                    ),
                    IconButton(
                      icon: const Icon(Icons.touch_app),
                      color: _isARRecording ? Colors.red : Colors.blue,
                      iconSize: 48,
                      onPressed: () async {
                        if (_isARRecording) {
                          // Stop recording
                          setStateDialog(() {
                            _isARRecording = false;
                          });
                          
                          try {
                            await _cameraController!.stopVideoRecording();
                            Navigator.of(context).pop(true); // Return true to send the message
                          } catch (e) {
                            debugPrint('Failed to stop recording: $e');
                          }
                        } else {
                          // Start recording
                          try {
                            final tempDir = await getTemporaryDirectory();
                            final videoPath = '${tempDir.path}/ar_recording_${_uuid.v4()}.mp4';
                            
                            await _cameraController!.startVideoRecording();
                            setStateDialog(() {
                              _isARRecording = true;
                            });
                            
                            // Auto-stop after 30 seconds
                            Future.delayed(const Duration(seconds: 30), () {
                              if (_isARRecording) {
                                setStateDialog(() {
                                  _isARRecording = false;
                                });
                                _cameraController!.stopVideoRecording().then((_) {
                                  Navigator.of(context).pop(true);
                                });
                              }
                            });
                          } catch (e) {
                            debugPrint('Failed to start recording: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to start recording: $e'),
                                backgroundColor: dangerColor,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios),
                      onPressed: () async {
                        if (_cameraController == null || !_cameraController!.value.isInitialized) {
                          return;
                        }
                        
                        try {
                          final cameras = await availableCameras();
                          final currentCamera = _cameraController!.description;
                          final newCamera = cameras.firstWhere(
                            (camera) => camera.lensDirection != currentCamera.lensDirection,
                            orElse: () => currentCamera,
                          );
                          
                          if (newCamera != currentCamera) {
                            await _cameraController!.dispose();
                            _cameraController = CameraController(
                              newCamera,
                              ResolutionPreset.medium,
                              enableAudio: true,
                            );
                            await _cameraController!.initialize();
                            setStateDialog(() {});
                          }
                        } catch (e) {
                          debugPrint('Failed to flip camera: $e');
                        }
                      },
                      tooltip: 'Flip camera',
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_isARRecording) {
                  _cameraController!.stopVideoRecording();
                }
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_chat == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat not found'),
        ),
        body: const Center(
          child: Text('The chat you are looking for does not exist.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _chat!.avatarPath != null
                  ? FileImage(File(_chat!.avatarPath!))
                  : null,
              child: _chat!.avatarPath == null
                  ? Text(_chat!.name[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chat!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                  ),
                  ),
                    Row(
                      children: [
                      const ConnectionIndicator(),
                      const SizedBox(width: 4),
                      const EncryptedIndicator(),
                      if (_currentEmotion.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        EmotionThemeIndicator(emotion: _currentEmotion),
                      ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (enableARFeatures)
            IconButton(
              icon: const Icon(Icons.view_in_ar),
              onPressed: _sendARMessage,
              tooltip: 'Send AR message',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'search':
                  // Implement search
                  break;
                case 'call':
                  // Implement call
                  break;
                case 'video':
                  // Implement video call
                  break;
                case 'security':
                  // Show security info
                  break;
                case 'delete':
                  // Delete chat
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Search'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'call',
                child: Row(
                  children: [
                    Icon(Icons.call),
                    SizedBox(width: 8),
                    Text('Voice call'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'video',
                child: Row(
                  children: [
                    Icon(Icons.videocam),
                    SizedBox(width: 8),
                    Text('Video call'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'security',
                child: Row(
                  children: [
                    Icon(Icons.security),
                    SizedBox(width: 8),
                    Text('Security info'),
                  ],
                ),
                    ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: dangerColor),
                    SizedBox(width: 8),
                    Text('Delete chat', style: TextStyle(color: dangerColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      // Hide attachment selector
                      if (_isAttachmentSelectorVisible) {
                        setState(() {
                          _isAttachmentSelectorVisible = false;
                        });
                      }
                    },
                    child: ListView.builder(
                    controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      itemCount: _messages.length,
                    itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.isOutgoing;
                        
                        // Check if timestamp should be shown (every 5 messages or after gap)
                        bool showTimestamp = index == 0;
                        if (index > 0) {
                          final prevMessage = _messages[index - 1];
                          final diff = message.timestamp.difference(prevMessage.timestamp);
                          showTimestamp = diff.inMinutes > 30 || (index % 5 == 0);
                        }
                        
                        // AR messages need special handling
                        if (message.type == MessageType.ar) {
                          return ARMessageBubble(
                            message: message,
                            isMe: isMe,
                            showTimestamp: showTimestamp,
                          );
                        }
                        
                        // Regular messages
                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                          showTimestamp: showTimestamp,
                      );
                    },
                  ),
          ),
          ),
          
          // Attachment selector
          if (_isAttachmentSelectorVisible)
            AttachmentSelector(
              onImageSelected: _sendImageMessage,
              onFileSelected: _sendFileMessage,
              onARSelected: _sendARMessage,
              onLocationSelected: () {
                // Implement location sharing
              },
              onContactSelected: () {
                // Implement contact sharing
              },
            ),
          
          // Message input
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                IconButton(
                  icon: Icon(_isAttachmentSelectorVisible
                      ? Icons.close
                      : Icons.add_circle_outline),
                  onPressed: _toggleAttachmentSelector,
                  tooltip: 'Attachments',
                ),
                if (enableSelfDestructingMessages)
                  IconButton(
                    icon: Icon(
                      Icons.timer,
                      color: _isSelfDestructModeEnabled
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    onPressed: _toggleSelfDestructMode,
                    tooltip: 'Self-destruct timer',
                  ),
                if (enableFaceMasking)
                  IconButton(
                    icon: Icon(
                      Icons.face,
                      color: _isFaceMaskEnabled
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: _toggleFaceMasking,
                    tooltip: 'Face masking',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                      hintText: _isRecording
                          ? 'Recording audio...'
                          : 'Type a message',
                        border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                      onChanged: (text) {
                      // Handle typing indicator
                      if (!_isTyping && text.isNotEmpty) {
                        setState(() {
                          _isTyping = true;
                        });
                        
                        // Send typing indicator
                        // ...
                        
                        // Set a timer to reset typing indicator after 2 seconds of inactivity
                        _typingTimer?.cancel();
                        _typingTimer = Timer(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              _isTyping = false;
                            });
                            
                            // Send typing stopped indicator
                            // ...
                          }
                        });
                      }
                    },
                    ),
                  ),
                  IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  tooltip: 'Send message',
                  ),
                ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}