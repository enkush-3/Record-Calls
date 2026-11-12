import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';

class LiveRecordingIndicator extends StatelessWidget {
  final bool isRecording;
  final String callerNumber;
  final String appSource;
  final double amplitude;
  final int elapsedSeconds;
  final String mediaType;
  final VoidCallback onToggle;
  final VoidCallback? onStartAudio;
  final VoidCallback? onStartVideo;
  final VoidCallback? onStop;

  const LiveRecordingIndicator({
    super.key,
    required this.isRecording,
    required this.callerNumber,
    required this.appSource,
    required this.amplitude,
    required this.elapsedSeconds,
    required this.onToggle,
    this.mediaType = 'audio',
    this.onStartAudio,
    this.onStartVideo,
    this.onStop,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!isRecording) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: (MediaQuery.sizeOf(context).width - 42) / 2,
              child: FilledButton.tonalIcon(
                onPressed: onStartAudio ?? onToggle,
                icon: const Icon(Icons.mic_rounded),
                label: Text(context.tr('test_audio_record')),
              ),
            ),
            SizedBox(
              width: (MediaQuery.sizeOf(context).width - 42) / 2,
              child: OutlinedButton.icon(
                onPressed: onStartVideo ?? onToggle,
                icon: const Icon(Icons.videocam_rounded),
                label: Text(context.tr('test_video_record')),
              ),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final isVideo = mediaType == 'video';
    final accentColor = isVideo
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isVideo
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    isVideo
                        ? context.tr(
                            'recording_live_video',
                            params: {
                              'source': appSource,
                              'caller': callerNumber,
                            },
                          )
                        : context.tr(
                            'recording_live_audio',
                            params: {
                              'source': appSource,
                              'caller': callerNumber,
                            },
                          ),
                    style: TextStyle(
                      color: isVideo
                          ? theme.colorScheme.onTertiaryContainer
                          : theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                _formatTime(elapsedSeconds),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: onStop ?? onToggle,
                icon: const Icon(Icons.stop, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
          if (!isVideo) ...[
            const SizedBox(height: 10),
            // Live Waveform visualizer
            SizedBox(
              height: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(24, (index) {
                  final offset = (index - 12).abs();
                  final heightFactor = (amplitude * (1.0 - (offset / 15.0)))
                      .clamp(0.1, 1.0);
                  return Container(
                    width: 4,
                    height: 24 * heightFactor,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
