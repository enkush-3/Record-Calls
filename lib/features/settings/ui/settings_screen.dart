import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/setup_wizard_screen.dart';

part 'settings_storage_sheets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).loadSettings();
    });
  }

  String _formatDiskSpace(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double num = bytes.toDouble();
    while (num >= 1024 && i < suffixes.length - 1) {
      num /= 1024;
      i++;
    }
    return '${num.toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _showSnackBarMessage() {
    final settings = ref.read(settingsProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (settings.message != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(settings.message!),
          backgroundColor: Colors.green.shade700,
        ),
      );
      ref.read(settingsProvider.notifier).clearMessage();
    } else if (settings.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(settings.errorMessage!),
          backgroundColor: Colors.red.shade700,
        ),
      );
      ref.read(settingsProvider.notifier).clearMessage();
    }
  }

  Widget _buildSectionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildSettingsSection({
    required BuildContext context,
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, ?subtitle],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appLocaleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final recordingsState = ref.watch(recordingsProvider);
    final recordingsNotifier = ref.read(recordingsProvider.notifier);
    final bridge = ref.read(nativeBridgeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width > 760 ? 760 : double.infinity,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              // 1. THEME & APPEARANCE ACCORDION
              _buildSettingsSection(
                context: context,
                leading: _buildSectionIcon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  theme.colorScheme.primary,
                ),
                title: Text(
                  context.tr('theme_section_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  context.tr('theme_app_title'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                children: [
                  Text(
                    context.tr('theme_app_desc'),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(context.tr('theme_system')),
                          icon: const Icon(
                            Icons.brightness_auto_rounded,
                            size: 18,
                          ),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(context.tr('theme_light')),
                          icon: const Icon(Icons.light_mode_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(context.tr('theme_dark')),
                          icon: const Icon(Icons.dark_mode_rounded, size: 18),
                        ),
                      ],
                      selected: {currentThemeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        themeNotifier.setThemeMode(newSelection.first);
                      },
                    ),
                  ),
                ],
              ),

              // 2. STORAGE DIRECTORY ACCORDION
              _buildSettingsSection(
                context: context,
                leading: _buildSectionIcon(
                  Icons.folder_rounded,
                  Colors.amber.shade700,
                ),
                title: Text(
                  context.tr('storage_section_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  context.tr('active_folder_desc'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.folder_open_rounded,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('active_folder_title'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('active_folder_desc'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Directory path box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: settings.isLoading
                              ? Text(
                                  context.tr('reading'),
                                  style: const TextStyle(fontSize: 12),
                                )
                              : SelectableText(
                                  settings.storageDirectory.isEmpty
                                      ? context.tr('unknown')
                                      : settings.storageDirectory,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: context.tr('copy_path'),
                          onPressed: settings.storageDirectory.isEmpty
                              ? null
                              : () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: settings.storageDirectory,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.tr('path_copied')),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Metrics chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (settings.isWritable ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                (settings.isWritable
                                        ? Colors.green
                                        : Colors.red)
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              settings.isWritable
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              size: 13,
                              color: settings.isWritable
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              settings.isWritable
                                  ? context.tr('writable_badge')
                                  : context.tr('readonly_badge'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: settings.isWritable
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (settings.freeSpaceBytes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pie_chart_outline_rounded,
                                size: 13,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatDiskSpace(settings.freeSpaceBytes)} ${context.tr('free_space_suffix')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.audiotrack_rounded,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${settings.recordingFilesCount} ${context.tr('files_suffix')}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.folder_open_rounded, size: 18),
                          label: Text(context.tr('change_location_btn')),
                          onPressed: settings.isSaving
                              ? null
                              : _showChangeDirectorySheet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: Text(context.tr('default_path_btn')),
                        onPressed: settings.isSaving
                            ? null
                            : () async {
                                await ref
                                    .read(settingsProvider.notifier)
                                    .resetToDefaultDirectory();
                                if (mounted) _showSnackBarMessage();
                              },
                      ),
                    ],
                  ),
                ],
              ),

              // Call recording engine and audio source
              _buildSettingsSection(
                context: context,
                leading: _buildSectionIcon(
                  Icons.settings_voice_rounded,
                  Colors.teal,
                ),
                title: Text(
                  context.tr('recording_engine_section_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  recordingsState.isAutoRecordEnabled
                      ? context.tr('auto_record_call_title')
                      : context.tr('manual'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: recordingsState.isAutoRecordEnabled
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.autorenew_rounded,
                        color: recordingsState.isAutoRecordEnabled
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    title: Text(
                      context.tr('auto_record_call_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      context.tr('auto_record_call_desc'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: recordingsState.isAutoRecordEnabled,
                    onChanged: (_) => recordingsNotifier.toggleAutoRecord(),
                  ),
                  const Divider(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('audio_channel_title'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('audio_source_desc'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment<String>(
                              value: 'both',
                              label: Text(
                                context.tr('audio_source_both'),
                                style: const TextStyle(fontSize: 12),
                              ),
                              icon: const Icon(
                                Icons.headset_mic_rounded,
                                size: 16,
                              ),
                            ),
                            ButtonSegment<String>(
                              value: 'mic_only',
                              label: Text(
                                context.tr('audio_source_mic'),
                                style: const TextStyle(fontSize: 12),
                              ),
                              icon: const Icon(Icons.mic_rounded, size: 16),
                            ),
                            ButtonSegment<String>(
                              value: 'remote_only',
                              label: Text(
                                context.tr('audio_source_call'),
                                style: const TextStyle(fontSize: 12),
                              ),
                              icon: const Icon(
                                Icons.phone_in_talk_rounded,
                                size: 16,
                              ),
                            ),
                          ],
                          selected: {
                            [
                                  'both',
                                  'mic_only',
                                  'remote_only',
                                ].contains(settings.audioRecordingSource)
                                ? settings.audioRecordingSource
                                : 'both',
                          },
                          onSelectionChanged: (Set<String> newSelection) {
                            ref
                                .read(settingsProvider.notifier)
                                .setAudioRecordingSource(newSelection.first);
                            if (mounted) _showSnackBarMessage();
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.audioRecordingSource == 'mic_only'
                            ? context.tr('audio_channel_mic_sub')
                            : (settings.audioRecordingSource == 'remote_only'
                                  ? context.tr('audio_channel_remote_sub')
                                  : context.tr('audio_channel_both_sub')),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 5. LANGUAGE SETTINGS ACCORDION
              _buildSettingsSection(
                context: context,
                leading: _buildSectionIcon(
                  Icons.language_rounded,
                  Colors.indigo,
                ),
                title: Text(
                  context.tr('language_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  ref.watch(appLocaleProvider).languageCode == 'en'
                      ? context.tr('lang_en')
                      : context.tr('lang_mn'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                children: [
                  Text(
                    context.tr('language_desc'),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'mn',
                          label: Text('🇲🇳 ${context.tr("lang_mn")}'),
                        ),
                        ButtonSegment<String>(
                          value: 'en',
                          label: Text('🇺🇸 ${context.tr("lang_en")}'),
                        ),
                      ],
                      selected: {ref.watch(appLocaleProvider).languageCode},
                      onSelectionChanged: (Set<String> newSelection) {
                        ref
                            .read(appLocaleProvider.notifier)
                            .setLocale(Locale(newSelection.first));
                      },
                    ),
                  ),
                ],
              ),

              // 6. PERMISSIONS & SETUP WIZARD ACCORDION
              _buildSettingsSection(
                context: context,
                leading: _buildSectionIcon(
                  Icons.verified_user_rounded,
                  Colors.blue,
                ),
                title: Text(
                  context.tr('permissions_section_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  context.tr('setup_wizard_desc'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      context.tr('setup_wizard_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      context.tr('setup_wizard_desc'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => SetupWizardScreen(bridge: bridge),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // 7. ABOUT APP ACCORDION
              _buildSettingsSection(
                context: context,
                leading: _buildSectionIcon(
                  Icons.info_outline_rounded,
                  Colors.deepOrange,
                ),
                title: Text(
                  context.tr('about_section_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  context.tr('tagline'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.16,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('app_name'),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('app_version_label'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phonelink_lock_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                context.tr('detail_local_only'),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.tr('about_supported_services'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
