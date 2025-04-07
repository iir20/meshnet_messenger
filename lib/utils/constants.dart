import 'package:flutter/material.dart';

// App Theming Constants
const Color primaryColor = Color(0xFF6C63FF);
const Color secondaryColor = Color(0xFF3A41E8);
const Color accentColor = Color(0xFFFFA53E);
const Color dangerColor = Color(0xFFFF6B6B);
const Color successColor = Color(0xFF4CAF50);
const Color warningColor = Color(0xFFFFCA28);
const Color infoColor = Color(0xFF2196F3);

const Color lightBackgroundColor = Color(0xFFF5F6FA);
const Color darkBackgroundColor = Color(0xFF121212);

const Color sentMessageBubbleColor = Color(0xFF6C63FF);
const Color receivedMessageBubbleColor = Color(0xFFEEEEEE);

const double borderRadius = 12.0;
const double iconSize = 24.0;
const double spacing = 16.0;

// Messenger Constants
const int maxMessageLength = 5000;
const int messageRetryLimit = 3;
const int messageRetryDelay = 5000; // in milliseconds
const int messageCacheLimit = 500; // per chat

// Security Constants
const int defaultEncryptionVersion = 2; // 1 = AES, 2 = PQ
const int defaultKeyRotationPeriod = 7; // in days
const int biometricLockTimeout = 300; // in seconds
const List<String> sensitiveMessageTypes = ['sos', 'private', 'confidential'];

// Network Constants
const int meshConnectionTimeout = 30000; // in milliseconds
const int offlineMessageTTL = 72; // in hours
const int maxPeersPerChat = 100;
const int maxConcurrentTransfers = 5;
const int transferChunkSize = 65536; // in bytes

// Bootstrap Nodes
const List<String> bootstrapNodes = [
  '/dns4/bootstrap1.securemesh.io/tcp/4001/p2p/QmBootstrapPeer1',
  '/dns4/bootstrap2.securemesh.io/tcp/4001/p2p/QmBootstrapPeer2',
  '/ip4/172.31.0.10/tcp/4001/p2p/QmBootstrapPeer3',
];

// Feature Flags
const bool enablePostQuantumCrypto = true;
const bool enableP2PDiscovery = true;
const bool enableOfflineMessaging = true;
const bool enableMDNS = true;
const bool enableARFeatures = true;
const bool enableEmotionAnalysis = true;
const bool enableSteganography = true;
const bool enableSelfDestructingMessages = true;
const bool enableAnonymousMessaging = true;
const bool enableSOSMode = true;
const bool enableFaceMasking = true;
const bool enableGeoLockedMessages = true;
const bool enableBackgroundSync = true;

// AR Constants
const int arMessageMaxDuration = 30; // in seconds
const int arMessageMaxSize = 20 * 1024 * 1024; // 20 MB
const List<String> supportedARFilters = [
  'none',
  'blur',
  'pixelate',
  'cartoon',
  'anonymous',
];

// Story Constants
const int storyDuration = 86400; // 24 hours in seconds
const int maxStoryItems = 20;
const int maxStoryAttachmentSize = 10 * 1024 * 1024; // 10 MB

// Geo-fence Constants
const double defaultGeoFenceRadius = 100.0; // in meters

// Routes
const String routeLogin = '/login';
const String routeHome = '/home';
const String routeChat = '/chat';
const String routeProfile = '/profile';
const String routeSettings = '/settings';
const String routeStories = '/stories';
const String routeCreateStory = '/create_story';
const String routeARCreator = '/ar_creator';
const String routeContacts = '/contacts';
const String routeOnboarding = '/onboarding';
const String routeEmergencySetup = '/emergency_setup';

// Hive Box Names
const String boxSettings = 'settings';
const String boxMessages = 'messages';
const String boxChats = 'chats';
const String boxPeers = 'peers';
const String boxUser = 'user';
const String boxKeys = 'keys';
const String boxStories = 'stories';
const String boxEmergencyContacts = 'emergency_contacts';
const String boxOfflineCache = 'offline_cache';

// Default User Settings
const Map<String, dynamic> defaultSettings = {
  'theme': 'system', // system, light, dark
  'notifications': true,
  'messagePreview': true,
  'soundEffects': true,
  'vibration': true,
  'encryption': true,
  'postQuantumEncryption': true,
  'autoDeleteMessages': false,
  'autoDeletePeriod': 604800, // 7 days in seconds
  'biometricAuth': false,
  'networkSaving': false,
  'emotionThemeEnabled': true,
  'arEffectsEnabled': true,
  'anonymousMode': false,
  'defaultFaceMask': 'none',
  'audioQuality': 'medium', // low, medium, high
  'videoQuality': 'medium', // low, medium, high
};

// Emoji SOS Triggers
const List<String> sosTriggerEmojis = ['🆘', '🚨', '🔴', '🚑', '🚒'];

// App information
const String appName = 'Secure Mesh Messenger';
const String appVersion = '1.0.0';
const String appDescription = 'A fully decentralized, secure, and private messaging system over a mesh network.';

// Mesh network configuration
const int defaultMeshPort = 7001;
const int discoveryScanPeriod = 10000; // milliseconds
const String serviceId = 'com.securemesh.messenger';

// Encryption
const int keySize = 256;
const String defaultEncryptionAlgorithm = 'AES-GCM';

// Storage
const String chatsBoxName = 'chats';
const String messagesBoxName = 'messages';
const String settingsBoxName = 'settings';

// Timeouts
const Duration connectionTimeout = Duration(seconds: 30);
const Duration messageTimeout = Duration(seconds: 10);

// UI
const double defaultPadding = 16.0;
const double smallPadding = 8.0;
const double largePadding = 24.0;
const double buttonHeight = 56.0; 