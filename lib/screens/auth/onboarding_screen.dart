import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_mesh_messenger/providers/auth_provider.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';
import 'package:secure_mesh_messenger/screens/auth/setup_identity_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Welcome to Secure Mesh',
      description: 'A fully decentralized, secure, and private messaging system over a mesh network.',
      imagePath: 'assets/images/onboarding_1.png',
      color: primaryColor,
    ),
    const OnboardingPage(
      title: 'Decentralized',
      description: 'Your messages travel directly between devices with no central server, maintaining your privacy and independence.',
      imagePath: 'assets/images/onboarding_2.png',
      color: Color(0xFF4CAF50),
    ),
    const OnboardingPage(
      title: 'End-to-End Encrypted',
      description: 'All messages are fully encrypted using state-of-the-art cryptography. Only you and your recipient can read them.',
      imagePath: 'assets/images/onboarding_3.png',
      color: Color(0xFFF44336),
    ),
    const OnboardingPage(
      title: 'Offline Communication',
      description: 'Connect with people nearby even without internet, using Bluetooth and WiFi Direct technologies.',
      imagePath: 'assets/images/onboarding_4.png',
      color: Color(0xFF9C27B0),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SetupIdentityScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 10,
                        width: index == _currentPage ? 25 : 10,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? _pages[_currentPage].color
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
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
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final Color color;

  const OnboardingPage({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: MediaQuery.of(context).size.height * 0.4,
            errorBuilder: (context, error, stackTrace) => Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: MediaQuery.of(context).size.width * 0.8,
              color: color.withOpacity(0.2),
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 