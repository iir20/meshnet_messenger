import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_mesh_messenger/providers/auth_provider.dart';
import 'package:secure_mesh_messenger/screens/home/home_screen.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({Key? key}) : super(key: key);

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  bool _isLoading = false;
  bool _isCheckingBiometrics = true;
  String _pattern = '';
  bool _showPatternInput = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isCheckingBiometrics = true;
    });

    // Small delay to ensure proper initialization
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (authProvider.isBiometricAvailable) {
      // Try biometric authentication immediately
      _authenticateWithBiometrics();
    } else {
      setState(() {
        _showPatternInput = true;
        _isCheckingBiometrics = false;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isCheckingBiometrics = false;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authenticated = await authProvider.authenticateWithBiometrics();

      if (authenticated) {
        _navigateToHome();
      } else {
        setState(() {
          _showPatternInput = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Show error and fall back to pattern
      setState(() {
        _showPatternInput = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric authentication failed: $e')),
      );
    }
  }

  Future<void> _authenticateWithPattern() async {
    if (_pattern.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pattern must be at least 4 digits')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authenticated = await authProvider.authenticateWithPattern(_pattern);

      if (authenticated) {
        _navigateToHome();
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect pattern')),
        );
        setState(() {
          _pattern = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _addDigit(String digit) {
    if (_pattern.length < 6) {
      setState(() {
        _pattern += digit;
      });

      // Auto-submit when pattern is complete
      if (_pattern.length == 6) {
        _authenticateWithPattern();
      }
    }
  }

  void _removeLastDigit() {
    if (_pattern.isNotEmpty) {
      setState(() {
        _pattern = _pattern.substring(0, _pattern.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Center(
            child: _isCheckingBiometrics
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Unlock Secure Mesh',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _showPatternInput
                            ? 'Enter your security pattern'
                            : 'Use biometric authentication to unlock',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),
                      if (!_showPatternInput && authProvider.isBiometricAvailable)
                        Column(
                          children: [
                            IconButton(
                              onPressed: _isLoading ? null : _authenticateWithBiometrics,
                              icon: const Icon(
                                Icons.fingerprint,
                                size: 80,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _showPatternInput = true;
                                      });
                                    },
                              child: const Text('Use Pattern Instead'),
                            ),
                          ],
                        ),
                      if (_showPatternInput)
                        Column(
                          children: [
                            // Pattern display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                6,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index < _pattern.length
                                        ? primaryColor
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Number pad
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildDigitButton('1'),
                                    _buildDigitButton('2'),
                                    _buildDigitButton('3'),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildDigitButton('4'),
                                    _buildDigitButton('5'),
                                    _buildDigitButton('6'),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildDigitButton('7'),
                                    _buildDigitButton('8'),
                                    _buildDigitButton('9'),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Empty space
                                    const SizedBox(width: 80),
                                    _buildDigitButton('0'),
                                    // Backspace
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: IconButton(
                                        onPressed: _removeLastDigit,
                                        icon: const Icon(
                                          Icons.backspace_outlined,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (authProvider.isBiometricAvailable)
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _showPatternInput = false;
                                        });
                                      },
                                child: const Text('Use Biometrics Instead'),
                              ),
                          ],
                        ),
                      if (_isLoading) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitButton(String digit) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _addDigit(digit),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 