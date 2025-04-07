import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showStatus;
  final Animation<double>? animation;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showStatus = false,
    this.animation,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _statusController;
  late Animation<double> _statusAnimation;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _statusAnimation = CurvedAnimation(
      parent: _statusController,
      curve: Curves.easeInOut,
    );
    
    if (widget.message.status == MessageStatus.read) {
      _statusController.forward();
    }
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.status != oldWidget.message.status && 
        widget.message.status == MessageStatus.read) {
      _statusController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isTapped = true;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isTapped = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Set bubble properties based on who sent the message
    final bubbleColor = widget.isMe 
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    
    final textColor = widget.isMe 
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    
    final bubbleAlignment = widget.isMe 
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    
    final bubbleBorderRadius = widget.isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          );

    Widget bubble = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: bubbleAlignment,
        children: [
          ScaleTransition(
            scale: _isTapped 
                ? Tween(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _statusController,
                      curve: Curves.easeOut,
                    ),
                  )
                : const AlwaysStoppedAnimation(1.0),
            child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: bubbleBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isTapped ? 0.1 : 0.05),
                  blurRadius: _isTapped ? 8 : 5,
                  offset: Offset(0, _isTapped ? 3 : 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: GestureDetector(
              onTap: _handleTap,
              child: _buildMessageContent(context, textColor),
            ),
          ),
          if (widget.showStatus) ...[
            const SizedBox(height: 4),
            FadeTransition(
              opacity: _statusAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(_statusAnimation),
                child: _buildMessageStatus(context),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.animation != null) {
      return FadeTransition(
        opacity: widget.animation!,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(widget.isMe ? 0.5 : -0.5, 0),
            end: Offset.zero,
          ).animate(widget.animation!),
          child: bubble,
        ),
      );
    }
    return bubble;
  }

  Widget _buildMessageContent(BuildContext context, Color? textColor) {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.network(
                widget.message.content,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 50,
                  ),
                ),
              ),
            ),
            if (widget.message.metadata != null && widget.message.metadata!['caption'] != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.message.metadata!['caption'] as String,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.message.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      case MessageType.location:
        return Column(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Location shared',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ],
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildMessageStatus(BuildContext context) {
    // Don't show status for received messages
    if (!widget.isMe) {
      return const SizedBox.shrink();
    }

    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();
    final statusColor = _getStatusColor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.message.isEncrypted)
          ScaleTransition(
            scale: _statusAnimation,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.lock,
                size: 12,
                color: Colors.green,
              ),
            ),
          ),
        Text(
          '${_formatTime(widget.message.timestamp)} · $statusText',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        ScaleTransition(
          scale: _statusAnimation,
          child: RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _statusController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Icon(
              statusIcon,
              size: 12,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
      default:
        return '';
    }
  }

  IconData _getStatusIcon() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }

  Color _getStatusColor() {
    switch (widget.message.status) {
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
} 