import 'dart:io';
import 'package:flutter/material.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/services/ar_service.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:secure_mesh_messenger/utils/date_formatter.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class ARMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showTimestamp;
  
  const ARMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showTimestamp = false,
  }) : super(key: key);
  
  @override
  _ARMessageBubbleState createState() => _ARMessageBubbleState();
}

class _ARMessageBubbleState extends State<ARMessageBubble> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  String? _decryptedFilePath;
  bool _isLoading = false;
  bool _errorLoading = false;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    // Delete decrypted file when we're done
    _deleteDecryptedFile();
    super.dispose();
  }
  
  Future<void> _deleteDecryptedFile() async {
    if (_decryptedFilePath != null) {
      try {
        final file = File(_decryptedFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete decrypted AR file: $e');
      }
    }
  }
  
  Future<void> _loadARMessage() async {
    if (_isLoading || _decryptedFilePath != null) return;
    
    setState(() {
      _isLoading = true;
      _errorLoading = false;
    });
    
    try {
      final arService = Provider.of<ARService>(context, listen: false);
      await arService.displayARMessage(widget.message.content);
      
      // Listen for the decrypted file path
      arService.onARMessageReceived.listen((filePath) {
        _decryptedFilePath = filePath;
        _initializeVideoPlayer();
      });
    } catch (e) {
      debugPrint('Failed to load AR message: $e');
      setState(() {
        _errorLoading = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _initializeVideoPlayer() async {
    if (_decryptedFilePath == null) return;
    
    _videoController = VideoPlayerController.file(File(_decryptedFilePath!));
    
    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize video player: $e');
      setState(() {
        _errorLoading = true;
      });
    }
  }
  
  void _togglePlayPause() {
    if (_videoController == null) return;
    
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeString = DateFormatter.formatMessageTime(widget.message.timestamp);
    final dateString = widget.showTimestamp 
        ? DateFormatter.formatMessageDate(widget.message.timestamp) 
        : null;
    
    // Self-destruct timer display
    final isSelfDestructing = widget.message.isSelfDestruct;
    
    return Column(
      crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Date header if needed
        if (widget.showTimestamp && dateString != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  dateString,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          
        // Message content
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Status indicator for outgoing messages
              if (widget.isMe && widget.message.status != MessageStatus.read)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: _buildStatusIndicator(context),
                ),
                
              // Message bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: _getBubbleColor(context),
                    borderRadius: _getBubbleBorderRadius(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AR content preview
                      _buildARContent(),
                      
                      // Self-destruct indicator
                      if (isSelfDestructing)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 8.0, right: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer, 
                                size: 12,
                                color: widget.isMe 
                                    ? Colors.white.withOpacity(0.7) 
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Self-destructing',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: widget.isMe 
                                      ? Colors.white.withOpacity(0.7) 
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Time and read status
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 8.0, right: 8.0, bottom: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.view_in_ar,
                              size: 12,
                              color: widget.isMe 
                                  ? Colors.white.withOpacity(0.7) 
                                  : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AR Message',
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.isMe 
                                    ? Colors.white.withOpacity(0.7) 
                                    : Colors.black54,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeString,
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.isMe 
                                    ? Colors.white.withOpacity(0.7) 
                                    : Colors.black54,
                              ),
                            ),
                            if (widget.isMe && widget.message.status == MessageStatus.read)
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Icon(
                                  Icons.done_all,
                                  size: 12,
                                  color: widget.isMe 
                                      ? Colors.white.withOpacity(0.7) 
                                      : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusIndicator(BuildContext context) {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time, size: 12, color: Colors.grey);
      case MessageStatus.sent:
        return const Icon(Icons.done, size: 12, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.grey);
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 12, color: Theme.of(context).colorScheme.error);
      default:
        return const SizedBox.shrink();
    }
  }
  
  Color _getBubbleColor(BuildContext context) {
    if (widget.isMe) {
      return sentMessageBubbleColor;
    } else {
      return receivedMessageBubbleColor;
    }
  }
  
  BorderRadius _getBubbleBorderRadius() {
    const radius = Radius.circular(16.0);
    if (widget.isMe) {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: Radius.circular(4.0),
      );
    } else {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: Radius.circular(4.0),
        bottomRight: radius,
      );
    }
  }
  
  Widget _buildARContent() {
    if (_isLoading) {
      return SizedBox(
        width: 250,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Loading AR content',
                style: TextStyle(
                  color: widget.isMe ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_errorLoading) {
      return SizedBox(
        width: 250,
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: widget.isMe ? Colors.white : Colors.red,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load AR content',
                style: TextStyle(
                  color: widget.isMe ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadARMessage,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_videoController != null && _videoController!.value.isInitialized) {
      return GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: SizedBox(
                width: 250,
                height: 200,
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
            if (!_isPlaying)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
          ],
        ),
      );
    }
    
    // Initial state - tap to load
    return GestureDetector(
      onTap: _loadARMessage,
      child: Container(
        width: 250,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12.0),
          image: const DecorationImage(
            image: AssetImage('assets/images/ar_placeholder.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // AR visual indicator
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12.0),
                    bottomLeft: Radius.circular(12.0),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.view_in_ar,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Play button
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
            
            // Tap to view text
            Positioned(
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Tap to view AR message',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showARFullScreen() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'AR Message',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: () {
              _togglePlayPause();
            },
            child: Icon(
              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
        ),
      ),
    );
  }
} 