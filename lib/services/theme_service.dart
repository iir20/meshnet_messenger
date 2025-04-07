import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _moodKey = 'current_mood';
  
  ThemeMode _themeMode = ThemeMode.dark;
  String _currentMood = 'neutral';
  bool _isHolographicEnabled = true;
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  String get currentMood => _currentMood;
  bool get isHolographicEnabled => _isHolographicEnabled;
  
  // Mood-based color schemes
  final Map<String, ColorScheme> _moodColorSchemes = {
    'neutral': const ColorScheme.dark(
      primary: Color(0xFF00E5FF),
      secondary: Color(0xFF00FFE5),
      surface: Color(0xFF1A1A1A),
      background: Color(0xFF000000),
      error: Color(0xFFFF1744),
    ),
    'happy': const ColorScheme.dark(
      primary: Color(0xFFFFD700),
      secondary: Color(0xFFFFA000),
      surface: Color(0xFF1A1A1A),
      background: Color(0xFF000000),
      error: Color(0xFFFF1744),
    ),
    'sad': const ColorScheme.dark(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF64B5F6),
      surface: Color(0xFF1A1A1A),
      background: Color(0xFF000000),
      error: Color(0xFFFF1744),
    ),
    'angry': const ColorScheme.dark(
      primary: Color(0xFFFF1744),
      secondary: Color(0xFFFF5252),
      surface: Color(0xFF1A1A1A),
      background: Color(0xFF000000),
      error: Color(0xFFFF1744),
    ),
  };
  
  // Glassmorphism styles
  BoxDecoration get glassmorphismDecoration => BoxDecoration(
    color: Colors.black.withOpacity(0.2),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        spreadRadius: 2,
      ),
    ],
  );
  
  // Holographic effect
  BoxDecoration get holographicDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(0.05),
        Colors.white.withOpacity(0.1),
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1,
    ),
  );
  
  // Initialize theme
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    final savedMood = prefs.getString(_moodKey);
    
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.dark,
      );
    }
    
    if (savedMood != null) {
      _currentMood = savedMood;
    }
    
    notifyListeners();
  }
  
  // Toggle theme mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.toString());
    notifyListeners();
  }
  
  // Update mood
  Future<void> updateMood(String mood) async {
    if (_moodColorSchemes.containsKey(mood)) {
      _currentMood = mood;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_moodKey, mood);
      notifyListeners();
    }
  }
  
  // Toggle holographic effects
  Future<void> toggleHolographic() async {
    _isHolographicEnabled = !_isHolographicEnabled;
    notifyListeners();
  }
  
  // Get current color scheme based on mood
  ColorScheme get currentColorScheme => _moodColorSchemes[_currentMood] ?? _moodColorSchemes['neutral']!;
  
  // Create theme data
  ThemeData get themeData => ThemeData(
    colorScheme: currentColorScheme,
    brightness: _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: currentColorScheme.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: currentColorScheme.primary,
      foregroundColor: currentColorScheme.onPrimary,
    ),
  );
  
  // Create dark theme data
  ThemeData get darkThemeData => ThemeData(
    colorScheme: currentColorScheme,
    brightness: Brightness.dark,
    useMaterial3: true,
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: currentColorScheme.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: currentColorScheme.primary,
      foregroundColor: currentColorScheme.onPrimary,
    ),
  );
} 