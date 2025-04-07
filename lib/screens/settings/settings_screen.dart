import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_mesh_messenger/providers/auth_provider.dart';
import 'package:secure_mesh_messenger/providers/mesh_provider.dart';
import 'package:secure_mesh_messenger/providers/theme_provider.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:secure_mesh_messenger/screens/auth/biometric_auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      // Stop mesh networking
      final meshProvider = Provider.of<MeshProvider>(context, listen: false);
      await meshProvider.stopDiscovery();
      await meshProvider.stopAdvertising();
      
      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const BiometricAuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final meshProvider = Provider.of<MeshProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Account'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor,
              child: Text(
                authProvider.userName?.isNotEmpty == true
                    ? authProvider.userName![0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(authProvider.userName ?? 'Unknown'),
            subtitle: Text('ID: ${authProvider.userId ?? 'Not available'}'),
          ),
          const Divider(),
          
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_medium),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ),
          const Divider(),

          const _SectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Use fingerprint to unlock the app'),
            trailing: Switch(
              value: authProvider.isBiometricEnabled,
              onChanged: authProvider.isBiometricAvailable
                  ? (value) {
                      authProvider.setBiometricEnabled(value);
                    }
                  : null,
            ),
            enabled: authProvider.isBiometricAvailable,
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('End-to-End Encryption'),
            subtitle: const Text('Messages are encrypted by default'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
            enabled: false,
          ),
          const Divider(),

          const _SectionHeader('Mesh Network'),
          SwitchListTile(
            title: const Text('Auto-discover Peers'),
            subtitle: const Text('Automatically discover peers when app opens'),
            value: false, // This would be controlled by a setting
            onChanged: (value) {
              // TODO: Implement auto-discovery setting
            },
            secondary: const Icon(Icons.wifi_tethering),
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text('Bluetooth'),
            subtitle: Text(
              meshProvider.bluetoothEnabled ? 'Enabled' : 'Disabled',
            ),
            trailing: IconButton(
              icon: Icon(
                meshProvider.bluetoothEnabled
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: meshProvider.bluetoothEnabled ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                // Show dialog explaining how to enable Bluetooth
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Enable Bluetooth'),
                    content: const Text(
                      'Please enable Bluetooth in your device settings to discover nearby peers.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),

          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text(appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              // Show privacy policy
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Secure Mesh Messenger is designed with privacy as a core principle. '
                      'All communication is peer-to-peer with no central servers. '
                      'Messages are end-to-end encrypted and your data never leaves your device '
                      'except when directly communicating with your chosen contacts.\n\n'
                      'We do not collect, store, or transmit any user data to external servers. '
                      'Your identity and messages are stored only on your device.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
} 