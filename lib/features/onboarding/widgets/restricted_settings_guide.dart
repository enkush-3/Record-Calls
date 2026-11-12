import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';

class RestrictedSettingsGuide extends StatelessWidget {
  final VoidCallback onOpenAppInfo;

  const RestrictedSettingsGuide({super.key, required this.onOpenAppInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF2A1F0C) : Colors.amber.shade50;
    final borderColor = isDark
        ? Colors.amber.shade700.withValues(alpha: 0.5)
        : Colors.amber.shade300;
    final headerColor = isDark ? Colors.amber.shade300 : Colors.amber.shade900;
    final textColor = isDark ? Colors.grey.shade300 : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: headerColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('restricted_settings_header'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('restricted_settings_desc'),
            style: TextStyle(fontSize: 12, color: textColor, height: 1.3),
          ),
          const SizedBox(height: 6),
          _stepRow('1', context.tr('restricted_settings_s1'), textColor),
          _stepRow('2', context.tr('restricted_settings_s2'), textColor),
          _stepRow('3', context.tr('restricted_settings_s3'), textColor),
          _stepRow('4', context.tr('restricted_settings_s4'), textColor),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onOpenAppInfo,
            icon: const Icon(Icons.settings_outlined, size: 16),
            label: Text(
              context.tr('open_app_info_btn'),
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: headerColor,
              side: BorderSide(color: headerColor),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(String num, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$num. ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: textColor)),
          ),
        ],
      ),
    );
  }
}
