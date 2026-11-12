import 'package:flutter/material.dart';
import '../../../core/i18n/app_localizations.dart';

enum RecordingFilter {
  all('Бүгд', null),
  cellular('Утас', 'Cellular'),
  viber('Viber', 'Viber'),
  telegram('Telegram', 'Telegram'),
  whatsApp('WhatsApp', 'WhatsApp'),
  messenger('Messenger', 'Messenger'),
  weChat('WeChat', 'WeChat'),
  instagram('Instagram', 'Instagram'),
  discord('Discord', 'Discord'),
  signal('Signal', 'Signal'),
  line('LINE', 'LINE'),
  skype('Skype', 'Skype'),
  audio('Аудио', null, mediaType: 'audio'),
  video('Видео', null, mediaType: 'video'),
  favorites('Одтой', null);

  final String label;
  final String? appSourceValue;
  final String? mediaType;

  const RecordingFilter(this.label, this.appSourceValue, {this.mediaType});
}

extension RecordingFilterLocalizer on RecordingFilter {
  String getLocalizedLabel(BuildContext context) {
    switch (this) {
      case RecordingFilter.all:
        return context.tr('filter_all');
      case RecordingFilter.cellular:
        return context.tr('cellular');
      case RecordingFilter.viber:
        return 'Viber';
      case RecordingFilter.telegram:
        return 'Telegram';
      case RecordingFilter.whatsApp:
        return 'WhatsApp';
      case RecordingFilter.messenger:
        return 'Messenger';
      case RecordingFilter.weChat:
        return 'WeChat';
      case RecordingFilter.instagram:
        return 'Instagram';
      case RecordingFilter.discord:
        return 'Discord';
      case RecordingFilter.signal:
        return 'Signal';
      case RecordingFilter.line:
        return 'LINE';
      case RecordingFilter.skype:
        return 'Skype';
      case RecordingFilter.audio:
        return context.tr('filter_audio');
      case RecordingFilter.video:
        return context.tr('filter_video');
      case RecordingFilter.favorites:
        return context.tr('filter_favorites');
    }
  }
}
