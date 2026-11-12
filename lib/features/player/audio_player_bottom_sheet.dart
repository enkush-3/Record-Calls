import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/recording_entity.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import 'player_state_notifier.dart';

class AudioPlayerBottomSheet extends ConsumerWidget {
  final RecordingEntity recording;
  final VoidCallback? onClose;

  const AudioPlayerBottomSheet({
    super.key,
    required this.recording,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context,
    RecordingEntity recording, {
    VoidCallback? onClose,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AudioPlayerBottomSheet(recording: recording, onClose: onClose),
    );
    onClose?.call();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final badgeColor = AppColors.getColorForSource(recording.appSource);

    final position = playerState.position;
    final duration = playerState.duration.inMilliseconds > 0
        ? playerState.duration
        : Duration(seconds: recording.durationSec);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppColors.getIconForSource(recording.appSource),
                      color: badgeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.callerName,
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${recording.appSource} ${context.tr('call_suffix')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: badgeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                ),
                child: Slider(
                  value: position.inMilliseconds
                      .clamp(0, duration.inMilliseconds)
                      .toDouble(),
                  max: duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (val) {
                    playerNotifier.seek(Duration(milliseconds: val.toInt()));
                  },
                  semanticFormatterCallback: (val) =>
                      _formatDuration(Duration(milliseconds: val.toInt())),
                ),
              ),

              // Time labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      _formatDuration(duration),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, size: 28),
                    onPressed: () => playerNotifier.skip(-10),
                    tooltip: context.tr('seek_back_10'),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filled(
                    iconSize: 36,
                    icon: Icon(
                      playerState.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    onPressed: () => playerNotifier.togglePlayPause(),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(64, 64),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, size: 28),
                    onPressed: () => playerNotifier.skip(10),
                    tooltip: context.tr('seek_forward_10'),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Playback speed chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1.0, 1.5, 2.0].map((speed) {
                  final isSelected = playerState.speed == speed;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text('${speed}x'),
                      selected: isSelected,
                      onSelected: (_) => playerNotifier.setSpeed(speed),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // File path info with copy button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.darkBackground
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recording.filePath,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('copy_path'),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: recording.filePath),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('path_copied')),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
