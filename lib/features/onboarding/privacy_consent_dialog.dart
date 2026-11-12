import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

class PrivacyConsentDialog extends StatelessWidget {
  const PrivacyConsentDialog({super.key});

  static const String prefKey = 'has_accepted_privacy_v2';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKey) ?? false;
  }

  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);
  }

  static Future<bool> showConsentIfNeeded(BuildContext context) async {
    final accepted = await hasAccepted();
    if (accepted || !context.mounted) return true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PrivacyConsentBottomSheet(),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return const PrivacyConsentBottomSheet();
  }
}

class PrivacyConsentBottomSheet extends StatelessWidget {
  const PrivacyConsentBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('privacy_title'),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('privacy_intro'),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildPoint(
                context: context,
                icon: Icons.lock_outline_rounded,
                title: context.tr('privacy_local_title'),
                desc: context.tr('privacy_local_desc'),
              ),
              const SizedBox(height: 10),
              _buildPoint(
                context: context,
                icon: Icons.mic_none_rounded,
                title: context.tr('privacy_mic_title'),
                desc: context.tr('privacy_mic_desc'),
              ),
              const SizedBox(height: 10),
              _buildPoint(
                context: context,
                icon: Icons.screen_share_outlined,
                title: context.tr('privacy_screen_audio_title'),
                desc: context.tr('privacy_screen_audio_desc'),
              ),
              const SizedBox(height: 10),
              _buildPoint(
                context: context,
                icon: Icons.gavel_outlined,
                title: context.tr('privacy_legal_title'),
                desc: context.tr('privacy_legal_desc'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await PrivacyConsentDialog.markAccepted();
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    context.tr('privacy_accept'),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoint({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
