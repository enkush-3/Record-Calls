import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF3158C9);
  static const Color primaryDark = Color(0xFF2445A8);
  static const Color primaryLight = Color(0xFF5B7CE2);
  static const Color accent = Color(0xFF11A894);

  // Dark & Light Surface Constants
  static const Color darkBackground = Color(0xFF0D1424);
  static const Color darkSurface = Color(0xFF141E31);
  static const Color darkCard = Color(0xFF18243A);
  static const Color darkInput = Color(0xFF101A2D);
  static const Color darkBorder = Color(0xFF2B3850);

  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInput = Color(0xFFF7F8FC);
  static const Color lightBorder = Color(0xFFE3E8F1);

  // App Source Badge Colors
  static const Color cellular = Color(0xFF10B981); // Emerald Green
  static const Color viber = Color(0xFF8B5CF6); // Viber Purple
  static const Color telegram = Color(0xFF0EA5E9); // Telegram Cyan
  static const Color whatsApp = Color(0xFF22C55E); // WhatsApp Green
  static const Color messenger = Color(0xFF0084FF); // Messenger Blue
  static const Color weChat = Color(0xFF07C160); // WeChat Green
  static const Color instagram = Color(0xFFE1306C);
  static const Color discord = Color(0xFF5865F2);
  static const Color signal = Color(0xFF3A76F0);
  static const Color line = Color(0xFF06C755);
  static const Color skype = Color(0xFF00AFF0);
  static const Color manual = Color(0xFFF59E0B); // Amber

  // Media Type Colors
  static const Color videoBadge = Color(0xFF8B5CF6);
  static const Color audioBadge = Color(0xFF2563EB);

  static Color getColorForSource(String source) {
    switch (source.toLowerCase()) {
      case 'viber':
        return viber;
      case 'telegram':
        return telegram;
      case 'whatsapp':
        return whatsApp;
      case 'messenger':
        return messenger;
      case 'wechat':
        return weChat;
      case 'instagram':
        return instagram;
      case 'discord':
        return discord;
      case 'signal':
        return signal;
      case 'line':
        return line;
      case 'skype':
        return skype;
      case 'manual':
        return manual;
      case 'cellular':
      default:
        return cellular;
    }
  }

  static IconData getIconForSource(String source) {
    switch (source.toLowerCase()) {
      case 'viber':
      case 'telegram':
      case 'whatsapp':
      case 'messenger':
      case 'wechat':
      case 'instagram':
      case 'discord':
      case 'signal':
      case 'line':
      case 'skype':
        return Icons.chat_bubble_outline_rounded;
      case 'manual':
        return Icons.mic_rounded;
      case 'cellular':
      default:
        return Icons.phone_rounded;
    }
  }

  static IconData getIconForMediaType(String mediaType) {
    if (mediaType.toLowerCase() == 'video') {
      return Icons.videocam_rounded;
    }
    return Icons.mic_rounded;
  }
}
