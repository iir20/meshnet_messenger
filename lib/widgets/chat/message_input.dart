import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_mesh_messenger/models/user.dart';
import 'package:secure_mesh_messenger/providers/auth_provider.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final VoidCallback onAttachmentPressed;
  final VoidCallback onARPressed;
  final bool isARMode;
  final bool isEncrypting;
  final String encryptionStatus;
  final bool showSelfDestructOption;
  final Function(bool) onSelfDestructToggled;
  final bool selfDestructEnabled;
  final Function(int) onSelfDestructTimeChanged;
  final int selfDestructTime;
  
  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onAttachmentPressed,
    required this.onARPressed,
    this.isARMode = false,
    this.isEncrypting = false,
    this.encryptionStatus = 'Encrypted',
    this.showSelfDestructOption = false,
    required this.onSelfDestructToggled,
    this.selfDestructEnabled = false,
    required this.onSelfDestructTimeChanged,
    this.selfDestructTime = 30,
  }) : super(key: key);
  
  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _showEmojiPicker = false;
  bool _showSelfDestructMenu = false;
  
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final themeData = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showSelfDestructMenu) _buildSelfDestructMenu(),
          Row(
            children: [
              IconButton(
                icon: Icon(widget.isARMode ? Icons.keyboard : Icons.camera_enhance),
                onPressed: widget.onARPressed,
                tooltip: widget.isARMode ? 'Switch to Text' : 'AR Message',
                color: widget.isARMode ? themeData.colorScheme.primary : null,
              ),
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: widget.onAttachmentPressed,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeData.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          decoration: InputDecoration(
                            hintText: widget.isARMode 
                                ? 'AR caption...' 
                                : 'Message...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      if (enableSelfDestructMessages && !widget.isARMode)
                        IconButton(
                          icon: Icon(
                            Icons.timer_outlined,
                            color: widget.selfDestructEnabled 
                                ? themeData.colorScheme.primary 
                                : null,
                          ),
                          onPressed: () {
                            setState(() {
                              if (widget.selfDestructEnabled) {
                                widget.onSelfDestructToggled(false);
                              } else {
                                _showSelfDestructMenu = !_showSelfDestructMenu;
                              }
                            });
                          },
                          tooltip: 'Self-destruct message',
                        ),
                      if (widget.isEncrypting)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                themeData.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (widget.controller.text.trim().isNotEmpty) {
                    widget.onSend(widget.controller.text.trim());
                    widget.controller.clear();
                  }
                },
                color: themeData.colorScheme.primary,
              ),
            ],
          ),
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }
  
  Widget _buildSelfDestructMenu() {
    final themeData = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: themeData.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Self-destruct message',
                style: themeData.textTheme.titleSmall,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showSelfDestructMenu = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Message will be deleted after ${widget.selfDestructTime} seconds',
            style: themeData.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: widget.selfDestructTime.toDouble(),
                  min: 5,
                  max: 300,
                  divisions: 59,
                  label: '${widget.selfDestructTime} sec',
                  onChanged: (value) {
                    widget.onSelfDestructTimeChanged(value.round());
                  },
                ),
              ),
              Text(
                '${widget.selfDestructTime} sec',
                style: themeData.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showSelfDestructMenu = false;
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  widget.onSelfDestructToggled(true);
                  setState(() {
                    _showSelfDestructMenu = false;
                  });
                },
                child: const Text('Enable'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmojiPicker() {
    // Placeholder for emoji picker
    // In a real app, you would integrate a proper emoji picker package
    return Container(
      height: 250,
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surface,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: 64, // Just a placeholder count
        itemBuilder: (context, index) {
          // Simple emoji picker with just a few emojis as placeholders
          final emojis = ['😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆', '😉', '😊', 
                          '😋', '😎', '😍', '😘', '🥰', '😗', '😙', '😚', '🙂', '🤗',
                          '🤩', '🤔', '🤨', '😐', '😑', '😶', '🙄', '😏', '😣', '😥',
                          '😮', '🤐', '😯', '😪', '😫', '🥱', '😴', '😌', '😛', '😜',
                          '😝', '🤤', '😒', '😓', '😔', '😕', '🙃', '🤑', '😲', '☹️',
                          '🙁', '😖', '😞', '😟', '😤', '😢', '😭', '😦', '😧', '😨',
                          '😩', '🤯', '😬', '😰', '😱', '🥵', '🥶'];
          String emoji = index < emojis.length ? emojis[index] : '😀';
          
          return InkWell(
            onTap: () {
              widget.controller.text = widget.controller.text + emoji;
              widget.controller.selection = TextSelection.fromPosition(
                TextPosition(offset: widget.controller.text.length),
              );
            },
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }
} 