import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'package:secure_mesh_messenger/models/message.dart';
import 'package:secure_mesh_messenger/utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<String?> _selectNotificationSubject = BehaviorSubject<String?>();
  bool _isInitialized = false;
  
  // Getters
  Stream<String?> get selectNotificationStream => _selectNotificationSubject.stream;
  bool get isInitialized => _isInitialized;
  
  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    
    // Initialization settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Initialize plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
    
    _isInitialized = true;
  }
  
  // Handle local notification received
  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    if (payload != null) {
      _selectNotificationSubject.add(payload);
    }
  }
  
  // Handle notification tap
  void _onSelectNotification(NotificationResponse response) {
    if (response.payload != null) {
      _selectNotificationSubject.add(response.payload);
    }
  }
  
  // Request permission for notifications
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();
      return result ?? false;
    }
    return false;
  }
  
  // Show a message notification
  Future<void> showMessageNotification({
    required String chatId,
    required String chatName,
    required Message message,
    String? imageUrl,
  }) async {
    if (!_isInitialized) await initialize();
    
    // Create notification details
    final androidNotificationDetails = AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: imageUrl != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imageUrl),
              hideExpandedLargeIcon: true,
            )
          : null,
      category: AndroidNotificationCategory.message,
    );
    
    final iOSNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: imageUrl != null
          ? [DarwinNotificationAttachment(imageUrl)]
          : null,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );
    
    // Create notification title and body
    String title = chatName;
    String body = _getMessagePreview(message);
    
    // Create payload with chat ID and message ID
    final payload = jsonEncode({
      'type': 'message',
      'chatId': chatId,
      'messageId': message.id,
    });
    
    // Show notification
    await _notificationsPlugin.show(
      int.parse(chatId.hashCode.toString().substring(0, 8)),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  // Show a emergency notification
  Future<void> showEmergencyNotification({
    required String userId,
    required String userName,
    required String location,
  }) async {
    if (!_isInitialized) await initialize();
    
    // Create notification details with high priority
    final androidNotificationDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Notifications for emergency alerts',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      sound: const RawResourceAndroidNotificationSound('emergency_sound'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
    );
    
    final iOSNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'emergency_sound.aiff',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );
    
    // Create notification title and body
    String title = 'SOS EMERGENCY ALERT';
    String body = '$userName needs urgent help! Location: $location';
    
    // Create payload with user ID
    final payload = jsonEncode({
      'type': 'emergency',
      'userId': userId,
    });
    
    // Show notification
    await _notificationsPlugin.show(
      911,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
  
  // Cancel all notifications for a chat
  Future<void> cancelChatNotifications(String chatId) async {
    final id = int.parse(chatId.hashCode.toString().substring(0, 8));
    await _notificationsPlugin.cancel(id);
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
  
  // Dispose of resources
  void dispose() {
    _selectNotificationSubject.close();
  }
  
  // Helper method to get message preview
  String _getMessagePreview(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content.length > 100
            ? '${message.content.substring(0, 97)}...'
            : message.content;
      case MessageType.image:
        return 'Sent a photo';
      case MessageType.video:
        return 'Sent a video';
      case MessageType.audio:
        return 'Sent an audio message';
      case MessageType.file:
        return 'Sent a file: ${message.fileName ?? 'Document'}';
      case MessageType.location:
        return 'Shared a location';
      case MessageType.contact:
        return 'Shared a contact: ${message.contactName ?? 'Contact'}';
      case MessageType.ar:
        return 'Sent an AR message';
      default:
        return 'New message';
    }
  }
} 