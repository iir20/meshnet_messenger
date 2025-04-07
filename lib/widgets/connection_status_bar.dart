import 'package:flutter/material.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

class ConnectionStatusBar extends StatelessWidget {
  final bool isBluetoothEnabled;
  final bool isLocationEnabled;
  final bool isDiscovering;
  final bool isAdvertising;

  const ConnectionStatusBar({
    Key? key,
    required this.isBluetoothEnabled,
    required this.isLocationEnabled,
    required this.isDiscovering,
    required this.isAdvertising,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> statusItems = [];

    // Check if any issues
    final bool hasIssues = !isBluetoothEnabled || !isLocationEnabled;

    if (hasIssues) {
      // Add warning indicators
      if (!isBluetoothEnabled) {
        statusItems.add(StatusIndicator(
          color: Colors.red,
          icon: Icons.bluetooth_disabled,
          text: 'Bluetooth disabled',
          onTap: () => _showBluetoothDialog(context),
        ));
      }

      if (!isLocationEnabled) {
        statusItems.add(StatusIndicator(
          color: Colors.orange,
          icon: Icons.location_off,
          text: 'Location off',
          onTap: () => _showLocationDialog(context),
        ));
      }
    } else {
      // Add status indicators
      if (isDiscovering) {
        statusItems.add(const StatusIndicator(
          color: Colors.blue,
          icon: Icons.search,
          text: 'Discovering',
          showPulse: true,
        ));
      }

      if (isAdvertising) {
        statusItems.add(const StatusIndicator(
          color: Colors.green,
          icon: Icons.wifi_tethering,
          text: 'Advertising',
          showPulse: true,
        ));
      }

      // If nothing active, show normal status
      if (statusItems.isEmpty) {
        statusItems.add(const StatusIndicator(
          color: Colors.grey,
          icon: Icons.wifi_tethering,
          text: 'Idle',
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: hasIssues 
            ? Colors.red.withOpacity(0.1)
            : theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: 8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statusItems,
        ),
      ),
    );
  }

  void _showBluetoothDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Bluetooth'),
        content: const Text(
          'Bluetooth is required to discover and connect with nearby peers. '
          'Please enable Bluetooth in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Location'),
        content: const Text(
          'Location services are required for Bluetooth scanning. '
          'Please enable location services in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class StatusIndicator extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String text;
  final bool showPulse;
  final VoidCallback? onTap;

  const StatusIndicator({
    Key? key,
    required this.color,
    required this.icon,
    required this.text,
    this.showPulse = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.showPulse) {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat(reverse: true);
      _animation = Tween<double>(begin: 0.7, end: 1.0).animate(_animationController);
    }
  }

  @override
  void dispose() {
    if (widget.showPulse) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.showPulse) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: _buildIndicator(theme),
          );
        },
      );
    } else {
      return _buildIndicator(theme);
    }
  }

  Widget _buildIndicator(ThemeData theme) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: widget.color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.text,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 