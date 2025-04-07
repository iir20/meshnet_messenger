import 'package:intl/intl.dart';

class DateFormatter {
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateFormat = DateFormat('dd MMM');
  static final _fullDateFormat = DateFormat('dd MMM yyyy');
  
  /// Formats a timestamp for display in chat list
  static String formatChatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final timestampDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (timestampDate == today) {
      return _timeFormat.format(timestamp);
    } else if (timestampDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEEE').format(timestamp); // Day name
    } else if (timestamp.year == now.year) {
      return _dateFormat.format(timestamp);
    } else {
      return _fullDateFormat.format(timestamp);
    }
  }
  
  /// Formats a timestamp for display in message bubbles
  static String formatMessageTimestamp(DateTime timestamp) {
    return _timeFormat.format(timestamp);
  }
  
  /// Returns a formatted date string for message group headers
  static String formatMessageDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final timestampDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (timestampDate == today) {
      return 'Today';
    } else if (timestampDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEEE').format(timestamp); // Day name
    } else if (timestamp.year == now.year) {
      return DateFormat('EEEE, dd MMMM').format(timestamp);
    } else {
      return DateFormat('EEEE, dd MMMM yyyy').format(timestamp);
    }
  }
  
  /// Formats a timestamp for display in message details
  static String formatDetailedTimestamp(DateTime timestamp) {
    return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
  }
  
  /// Returns a countdown string for self-destructing messages
  static String formatSelfDestructCountdown(int secondsRemaining) {
    if (secondsRemaining < 60) {
      return '$secondsRemaining s';
    } else {
      final minutes = secondsRemaining ~/ 60;
      final seconds = secondsRemaining % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
  
  /// Returns a string representing the time remaining until the message expires
  static String formatMessageExpiry(DateTime expiryTime) {
    final now = DateTime.now();
    final difference = expiryTime.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    
    if (days > 0) {
      return 'Expires in $days day${days > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'Expires in $hours hour${hours > 1 ? 's' : ''}';
    } else if (minutes > 0) {
      return 'Expires in $minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      return 'Expires in <1 minute';
    }
  }
} 