import 'package:flutter/material.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

class AttachmentSelector extends StatelessWidget {
  final VoidCallback onImageSelected;
  final VoidCallback onFileSelected;
  final VoidCallback onARSelected;
  final VoidCallback onLocationSelected;
  final VoidCallback onContactSelected;
  
  const AttachmentSelector({
    Key? key,
    required this.onImageSelected,
    required this.onFileSelected,
    required this.onARSelected,
    required this.onLocationSelected,
    required this.onContactSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentButton(
                context,
                icon: Icons.photo,
                label: 'Photo',
                color: Colors.purple,
                onTap: onImageSelected,
              ),
              _buildAttachmentButton(
                context,
                icon: Icons.insert_drive_file,
                label: 'File',
                color: Colors.blue,
                onTap: onFileSelected,
              ),
              if (enableARFeatures)
                _buildAttachmentButton(
                  context,
                  icon: Icons.view_in_ar,
                  label: 'AR',
                  color: Colors.orange,
                  onTap: onARSelected,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentButton(
                context,
                icon: Icons.location_on,
                label: 'Location',
                color: Colors.green,
                onTap: onLocationSelected,
              ),
              _buildAttachmentButton(
                context,
                icon: Icons.person,
                label: 'Contact',
                color: Colors.red,
                onTap: onContactSelected,
              ),
              const SizedBox(width: 64), // Placeholder for third item
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 