import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/steganography_service.dart';
import '../widgets/glass_card.dart';

class SteganographyScreen extends StatefulWidget {
  const SteganographyScreen({Key? key}) : super(key: key);

  @override
  _SteganographyScreenState createState() => _SteganographyScreenState();
}

class _SteganographyScreenState extends State<SteganographyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  String? _selectedImagePath;
  String? _extractedMessage;
  bool _isLoading = false;
  bool _showPassword = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCreateTab(),
                  _buildDecodeTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.hide_image,
            color: Colors.greenAccent.withOpacity(0.8),
            size: 32,
          ),
          const SizedBox(width: 12),
          const Text(
            'STEGANOGRAPHY',
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
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.greenAccent.withOpacity(0.2),
          border: Border.all(
            color: Colors.greenAccent,
            width: 1.5,
          ),
        ),
        labelColor: Colors.greenAccent,
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        tabs: const [
          Tab(text: 'CREATE'),
          Tab(text: 'DECODE'),
          Tab(text: 'HISTORY'),
        ],
      ),
    );
  }
  
  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image selector
          GlassCard(
            blur: 10,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT CARRIER IMAGE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _selectedImage == null
                    ? InkWell(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.3),
                              width: 1,
                              style: BorderStyle.dashed,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.greenAccent.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'TAP TO SELECT AN IMAGE',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('CHANGE'),
                                onPressed: _pickImage,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Secret message input
          GlassCard(
            blur: 10,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SECRET MESSAGE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your secret message here...',
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
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Password input
          GlassCard(
            blur: 10,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PASSWORD PROTECTION',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: 'Enter password to encrypt message',
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
                          color: Colors.greenAccent,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Hide message button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _selectedImage == null || _messageController.text.isEmpty || _passwordController.text.isEmpty
                ? null
                : _hideMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Colors.greenAccent,
                    width: 1.5,
                  ),
                ),
                disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                disabledForegroundColor: Colors.grey,
              ),
              child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'HIDE MESSAGE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDecodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image selector
          GlassCard(
            blur: 10,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT IMAGE TO DECODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _selectedImage == null
                    ? InkWell(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.3),
                              width: 1,
                              style: BorderStyle.dashed,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.greenAccent.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'TAP TO SELECT AN IMAGE',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('CHANGE'),
                                onPressed: _pickImage,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Password input
          GlassCard(
            blur: 10,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PASSWORD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: 'Enter password to decrypt message',
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
                          color: Colors.greenAccent,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Extract message button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _selectedImage == null || _passwordController.text.isEmpty
                ? null
                : _extractMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Colors.greenAccent,
                    width: 1.5,
                  ),
                ),
                disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                disabledForegroundColor: Colors.grey,
              ),
              child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'EXTRACT MESSAGE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
            ),
          ),
          
          if (_extractedMessage != null) ...[
            const SizedBox(height: 24),
            
            // Extracted message display
            GlassCard(
              blur: 10,
              opacity: 0.1,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_open,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'EXTRACTED MESSAGE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            color: Colors.greenAccent,
                          ),
                          onPressed: () {
                            // TODO: Copy message to clipboard
                          },
                          tooltip: 'Copy to clipboard',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _extractedMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildHistoryTab() {
    return Consumer<SteganographyService>(
      builder: (context, stegoService, child) {
        final messages = stegoService.messages;
        
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'NO STEGANOGRAPHIC MESSAGES YET',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                blur: 10,
                opacity: 0.1,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedImagePath = message.imagePath;
                      _selectedImage = File(message.imagePath!);
                      _tabController.animateTo(1); // Switch to decode tab
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Thumbnail
                        if (message.imagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(message.imagePath!),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          
                        const SizedBox(width: 16),
                        
                        // Message info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    message.isEncrypted ? Icons.lock : Icons.lock_open,
                                    color: message.isEncrypted ? Colors.red : Colors.greenAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    message.isEncrypted ? 'ENCRYPTED' : 'DECRYPTED',
                                    style: TextStyle(
                                      color: message.isEncrypted ? Colors.red : Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${_formatDate(message.createdAt)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              if (message.senderId != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Sender: ${message.senderId}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (message.recipientId != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Recipient: ${message.recipientId}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Actions
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteMessage(message.id),
                              tooltip: 'Delete',
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.visibility,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImagePath = message.imagePath;
                                  _selectedImage = File(message.imagePath!);
                                  _tabController.animateTo(1); // Switch to decode tab
                                });
                              },
                              tooltip: 'View',
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Pick an image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      
      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
          _selectedImagePath = pickedImage.path;
          _extractedMessage = null;
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }
  
  // Hide a message in the selected image
  Future<void> _hideMessage() async {
    if (_selectedImage == null || _messageController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stegoService = Provider.of<SteganographyService>(context, listen: false);
      final outputPath = await stegoService.hideMessage(
        originalImage: _selectedImage!,
        message: _messageController.text,
        password: _passwordController.text,
        senderId: 'Me',
      );
      
      setState(() {
        _selectedImage = File(outputPath);
        _selectedImagePath = outputPath;
        _messageController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message hidden successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog('Error hiding message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Extract a message from the selected image
  Future<void> _extractMessage() async {
    if (_selectedImage == null || _passwordController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _extractedMessage = null;
    });
    
    try {
      final stegoService = Provider.of<SteganographyService>(context, listen: false);
      final message = await stegoService.extractMessage(
        imagePath: _selectedImage!.path,
        password: _passwordController.text,
      );
      
      setState(() {
        _extractedMessage = message;
      });
    } catch (e) {
      _showErrorDialog('Error extracting message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Delete a message from history
  void _deleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'Delete Message',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this message?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final stegoService = Provider.of<SteganographyService>(context, listen: false);
                stegoService.deleteMessage(messageId);
                Navigator.of(context).pop();
              },
              child: const Text(
                'DELETE',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Show info dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.greenAccent.withOpacity(0.5),
              width: 1,
            ),
          ),
          title: const Text(
            'STEGANOGRAPHY',
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
                'Steganography is the practice of hiding secret messages within ordinary files.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '• Hide text messages in images',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Password-protect your hidden messages',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Images look normal to the naked eye',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• Uses LSB (Least Significant Bit) technique',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '• View history of your steganographic messages',
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
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Show error dialog
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 8),
              const Text(
                'ERROR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          content: Text(
            error,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Format date helper
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 