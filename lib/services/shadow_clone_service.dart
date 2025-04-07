import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// AI Shadow Clone service - creates AI replicas that chat like the user when offline
/// This simulates on-device AI learning from past conversations
class ShadowCloneService with ChangeNotifier {
  // Shadow clone status
  bool _isActive = false;
  bool _isLearning = false;
  bool _autoReplyEnabled = false;
  double _learningProgress = 0;
  int _analyzedMessageCount = 0;
  DateTime? _lastTrainingDate;

  // Personality settings
  double _responseDelay = 2.0; // in seconds
  double _replyProbability = 0.7; // 0.0 to 1.0
  double _verbosityLevel = 0.5; // 0.0 to 1.0
  double _formalityLevel = 0.5; // 0.0 to 1.0
  double _emotionalLevel = 0.6; // 0.0 to 1.0

  // Mock message responses for demo
  final List<String> _mockResponses = [
    "I'm doing great, thanks for asking! How are you?",
    "Just finished working on the mesh network connections. Everything seems stable now.",
    "Have you seen the new holographic UI? It looks amazing!",
    "I'll be offline for a few hours, but the shadow clone should handle any urgent messages.",
    "The encryption is working perfectly. All messages are fully secured now.",
    "Let's meet up later to discuss the project timeline.",
    "I think we should prioritize the quantum encryption feature next.",
    "Thanks for sending that! I'll review it and get back to you.",
    "The time capsule messages are working great, just tested it.",
    "I'm excited about the AR message projection feature we're adding!",
  ];

  // Getters
  bool get isActive => _isActive;
  bool get isLearning => _isLearning;
  bool get autoReplyEnabled => _autoReplyEnabled;
  double get learningProgress => _learningProgress;
  int get analyzedMessageCount => _analyzedMessageCount;
  DateTime? get lastTrainingDate => _lastTrainingDate;
  bool get hasInitialModel => _analyzedMessageCount > 0;
  
  // Personality settings getters
  double get responseDelay => _responseDelay;
  double get replyProbability => _replyProbability;
  double get verbosityLevel => _verbosityLevel;
  double get formalityLevel => _formalityLevel;
  double get emotionalLevel => _emotionalLevel;

  // Toggle shadow clone active state
  void toggleActive() {
    _isActive = !_isActive;
    notifyListeners();
  }
  
  // Toggle auto-reply feature
  void toggleAutoReply() {
    _autoReplyEnabled = !_autoReplyEnabled;
    notifyListeners();
  }
  
  // Personality setting setters
  void setResponseDelay(double value) {
    _responseDelay = value.clamp(0.5, 10.0);
    notifyListeners();
  }
  
  void setReplyProbability(double value) {
    _replyProbability = value.clamp(0.0, 1.0);
    notifyListeners();
  }
  
  void setVerbosityLevel(double value) {
    _verbosityLevel = value.clamp(0.0, 1.0);
    notifyListeners();
  }
  
  void setFormalityLevel(double value) {
    _formalityLevel = value.clamp(0.0, 1.0);
    notifyListeners();
  }
  
  void setEmotionalLevel(double value) {
    _emotionalLevel = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  // Start learning from messages
  Future<void> startLearning(List<Map<String, dynamic>> messages) async {
    if (_isLearning) return;
    
    _isLearning = true;
    _learningProgress = 0;
    notifyListeners();
    
    // Filter for user's messages only
    final userMessages = messages.where((msg) => msg['isMe'] == true).toList();
    final totalMessages = userMessages.length;
    
    if (totalMessages == 0) {
      _isLearning = false;
      notifyListeners();
      return;
    }
    
    // Simulate learning process with delays
    int processedCount = 0;
    
    // Process messages in batches to simulate learning
    for (int i = 0; i < totalMessages; i++) {
      // Simulate processing delay
      await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(150)));
      
      // Update progress
      processedCount++;
      _learningProgress = (processedCount / totalMessages) * 100;
      
      // Update UI every few messages
      if (i % 3 == 0 || i == totalMessages - 1) {
        notifyListeners();
      }
    }
    
    // Learning complete
    _analyzedMessageCount = totalMessages;
    _lastTrainingDate = DateTime.now();
    _isLearning = false;
    _isActive = true;  // Activate after training
    
    notifyListeners();
  }

  // Generate a response based on learned patterns
  Future<String> generateResponse(String incomingMessage) async {
    if (!hasInitialModel) {
      return "I need to be trained before I can respond. Please train the shadow clone first.";
    }
    
    // Simulate response delay
    await Future.delayed(Duration(milliseconds: (_responseDelay * 500).round()));
    
    // For demo purposes, just select a random response
    final random = Random();
    String response = _mockResponses[random.nextInt(_mockResponses.length)];
    
    return response;
  }

  // Clear the learned model
  Future<void> clearModel() async {
    _analyzedMessageCount = 0;
    _lastTrainingDate = null;
    _isActive = false;
    _autoReplyEnabled = false;
    
    notifyListeners();
  }
} 