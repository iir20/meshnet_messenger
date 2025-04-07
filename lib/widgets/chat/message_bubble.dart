import 'dart:io';
import 'package:flutter/material.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:secure_mesh_messenger/utils/date_formatter.dart';
import 'package:secure_mesh_messenger/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showTimestamp;
  
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showTimestamp = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeString = DateFormatter.formatMessageTime(message.timestamp);
    final dateString = showTimestamp 
        ? DateFormatter.formatMessageDate(message.timestamp) 
        : null;
    
    // Self-destruct timer display
    final isSelfDestructing = message.isSelfDestruct;
    
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Date header if needed
        if (showTimestamp && dateString != null)
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
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Status indicator for outgoing messages
              if (isMe && message.status != MessageStatus.read)
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
                  padding: _getBubblePadding(),
                  decoration: BoxDecoration(
                    color: _getBubbleColor(context),
                    borderRadius: _getBubbleBorderRadius(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content based on type
                      _buildMessageContent(context),
                      
                      // Self-destruct indicator
                      if (isSelfDestructing)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer, 
                                size: 12,
                                color: isMe 
                                    ? Colors.white.withOpacity(0.7) 
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Self-destructing',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe 
                                      ? Colors.white.withOpacity(0.7) 
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Time and read status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe 
                                  ? Colors.white.withOpacity(0.7) 
                                  : Colors.black54,
                            ),
                          ),
                          if (isMe && message.status == MessageStatus.read)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Icon(
                                Icons.done_all,
                                size: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                        ],
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
    switch (message.status) {
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
  
  EdgeInsets _getBubblePadding() {
    switch (message.type) {
      case MessageType.image:
      case MessageType.video:
        return const EdgeInsets.all(4.0);
      default:
        return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
    }
  }
  
  Color _getBubbleColor(BuildContext context) {
    if (isMe) {
      return sentMessageBubbleColor;
    } else {
      return receivedMessageBubbleColor;
    }
  }
  
  BorderRadius _getBubbleBorderRadius() {
    const radius = Radius.circular(16.0);
    if (isMe) {
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
  
  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(context);
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.video:
        return _buildVideoMessage(context);
      case MessageType.audio:
        return _buildAudioMessage(context);
      case MessageType.file:
        return _buildFileMessage(context);
      case MessageType.location:
        return _buildLocationMessage(context);
      default:
        return Text(
          'Unsupported message type',
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
          ),
        );
    }
  }
  
  Widget _buildTextMessage(BuildContext context) {
    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black,
      ),
    );
  }
  
  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // Open image viewer
            _showImageViewer(context, message.content);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.file(
              File(message.content),
              fit: BoxFit.cover,
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ),
        if (message.containsHiddenData)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: GestureDetector(
              onTap: () {
                // Show steganography dialog
                _showHiddenMessageDialog(context);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_off, 
                    size: 12,
                    color: isMe 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hidden message',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.black54,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildVideoMessage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Open video player
        _openFile(message.content);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  width: 200,
                  height: 150,
                  color: Colors.black,
                  child: Image.asset(
                    'assets/images/video_placeholder.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
          const SizedBox(height: 4),
          Text(
            'Video',
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAudioMessage(BuildContext context) {
    final duration = message.metadata?['duration'] as int? ?? 0;
    final minutes = (duration / 60).floor();
    final seconds = (duration % 60).floor();
    final durationText = '$minutes:${seconds.toString().padLeft(2, '0')}';
    
    return GestureDetector(
      onTap: () {
        // Play audio
        _openFile(message.content);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        width: 200,
        decoration: BoxDecoration(
          color: isMe 
              ? Colors.blueAccent.withOpacity(0.2) 
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isMe ? Colors.white : primaryColor,
              child: Icon(
                Icons.play_arrow,
                color: isMe ? primaryColor : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    durationText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFileMessage(BuildContext context) {
    final fileName = message.metadata?['fileName'] as String? ?? 'File';
    final fileSize = message.metadata?['fileSize'] as int? ?? 0;
    final fileSizeStr = _formatFileSize(fileSize);
    
    return GestureDetector(
      onTap: () {
        // Open file
        _openFile(message.content);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe 
              ? Colors.blueAccent.withOpacity(0.2) 
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe ? Colors.white : primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileIcon(fileName),
                color: isMe ? primaryColor : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    fileSizeStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationMessage(BuildContext context) {
    final latitude = message.metadata?['latitude'] as double? ?? 0.0;
    final longitude = message.metadata?['longitude'] as double? ?? 0.0;
    
    return GestureDetector(
      onTap: () {
        // Open map
        _openMap(latitude, longitude);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.asset(
              'assets/images/map_placeholder.png',
              width: 200,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: isMe ? Colors.white : primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showImageViewer(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Share image
                },
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // Save image
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showHiddenMessageDialog(BuildContext context) {
    final hiddenMessage = message.metadata?['hiddenMessage'] as String? ?? 'No hidden message found';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hidden Message'),
        content: Text(hiddenMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: hiddenMessage));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
  
  void _openFile(String filePath) async {
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle error
      debugPrint('Could not open file: $filePath');
    }
  }
  
  void _openMap(double latitude, double longitude) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Handle error
      debugPrint('Could not open map for location: $latitude, $longitude');
    }
  }
  
  IconData _getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive;
      case '.mp3':
      case '.wav':
      case '.ogg':
        return Icons.audio_file;
      case '.mp4':
      case '.avi':
      case '.mov':
        return Icons.video_file;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
} 