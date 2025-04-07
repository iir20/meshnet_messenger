# MeshNet Messenger

A futuristic, decentralized, peer-to-peer encrypted messaging platform with cutting-edge UI/UX features.

## Features

### Core Features
- **Decentralized Messaging**: Peer-to-peer communication using LibP2P
- **End-to-End Encryption**: Multiple encryption algorithms (AES-256-GCM, ChaCha20-Poly1305, XChaCha20-Poly1305)
- **Offline-First Architecture**: Mesh networking for connectivity without internet
- **AI Shadow Clone**: AI-powered responder that mimics your messaging style

### UI/UX Features
- **Orbital Chat List**: 3D galaxy-style contacts visualization
- **Conversation UI**: Mood-based animated backgrounds and floating chat bubbles
- **HoloRings Story System**: Encrypted stories with gesture unlocking
- **Mood-Aware UI**: Auto-detects emotion from messages and adjusts UI
- **Haptic Feedback**: Customized haptics based on message type
- **Holographic Avatars**: Floating avatars with animated expressions
- **Glassmorphism**: Blur effects with holographic glowing edges

## Installation

### Android

#### Method 1: Using APK
1. Download the latest APK from the releases section
2. Enable "Install from Unknown Sources" in your device settings
3. Open the APK file to install
4. Grant all required permissions during first launch

#### Method 2: Build from Source
1. Ensure Flutter (2.10+) is installed on your system
2. Clone this repository
3. Navigate to the app directory
4. Run the build script:
   ```
   build_android.bat
   ```
5. The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`
6. Transfer to your device and install

### iOS

#### Method 1: Using TestFlight (requires Apple Developer account)
1. Contact us to be added to the TestFlight beta program
2. Accept the TestFlight invitation
3. Install from TestFlight

#### Method 2: Build from Source
1. Ensure Flutter (2.10+) and Xcode (13+) are installed on your Mac
2. Clone this repository
3. Navigate to the app directory
4. Run:
   ```
   flutter build ios --release
   ```
5. Open the generated Xcode project
6. Connect your device and deploy using your Apple Developer account

## Usage Guide

### First-Time Setup
1. Launch the app
2. Create your profile
3. Generate your encryption keys
4. Enable required permissions (location, Bluetooth, etc.)

### Connecting with Friends
1. Both users need to be on the same local network or within Bluetooth range
2. Navigate to the "Nodes" tab
3. Tap the radar icon to scan for nearby peers
4. Tap on a contact's orbital node to initiate chat

### Using Shadow Clone
1. Navigate to the "Shadow" tab
2. Activate the Shadow Clone feature
3. Train the AI by allowing it to analyze your previous messages
4. Customize personality settings to match your communication style
5. Toggle "Auto Reply" to allow the clone to respond on your behalf when offline

### Sharing Encrypted Stories
1. Navigate to the "Rings" tab
2. Tap the + icon to create a new story
3. Select media and add text
4. Choose encryption level and unlock requirements
5. Set expiry time
6. Publish to your network

## Security Features

- Multiple encryption algorithms (AES-256-GCM, ChaCha20-Poly1305, XChaCha20-Poly1305)
- Self-destructing messages
- Biometric message locking
- No central servers storing your data
- Local-only AI processing (no cloud uploading)
- Steganographic capabilities

## Troubleshooting

### Connection Issues
- Ensure Bluetooth and Location services are enabled
- Check that both devices are on the same local network or within Bluetooth range
- Verify that app has all required permissions

### Performance Tips
- For smoother animations on older devices, disable advanced visual effects in Settings
- Clear the message cache periodically to free up storage
- Disable auto-media download on limited data connections

## Developer Documentation

For detailed technical documentation and contribution guidelines, see [DEVELOPER.md](DEVELOPER.md).

## License

MeshNet Messenger is licensed under the MIT License - see the LICENSE file for details.

## Contact

For support or inquiries, contact us at:
- Email: support@meshnetmessenger.com
- Website: https://meshnetmessenger.com 