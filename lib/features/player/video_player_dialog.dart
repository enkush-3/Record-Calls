import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../core/database/recording_entity.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import 'video_player_bottom_sheet.dart';

class VideoPlayerDialog extends StatefulWidget {
  final RecordingEntity recording;

  const VideoPlayerDialog({
    super.key,
    required this.recording,
  });

  static Future<void> show(
    BuildContext context,
    RecordingEntity recording,
  ) async {
    await VideoPlayerBottomSheet.show(context, recording);
  }

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isCoverFit = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final file = File(widget.recording.filePath);
    if (!await file.exists()) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = context.tr('file_not_found', params: {'path': widget.recording.filePath});
        });
      }
      return;
    }

    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.addListener(() {
        if (mounted) {
          if (controller.value.hasError && !_hasError) {
            setState(() {
              _hasError = true;
              _errorMessage = controller.value.errorDescription ??
                  context.tr('video_play_error', params: {'error': ''});
            });
          } else {
            setState(() {});
          }
        }
      });
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
        controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = context.tr('video_play_error', params: {'error': e.toString()});
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final badgeColor = AppColors.getColorForSource(widget.recording.appSource);
    final screenSize = MediaQuery.of(context).size;

    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ??
        Duration(seconds: widget.recording.durationSec);
    final isPlaying = _controller?.value.isPlaying ?? false;
    final bool canControl = _isInitialized && !_hasError && _controller != null;

    // Responsive aspect ratio calculation
    final rawAspect = (_controller != null && _controller!.value.isInitialized)
        ? _controller!.value.aspectRatio
        : (16 / 9);
    final aspect = rawAspect > 0 ? rawAspect : (16 / 9);
    final isPortrait = aspect < 1.0;

    // Clamped height depending on portrait vs landscape
    final maxPlayerHeight = isPortrait
        ? (screenSize.height * 0.58).clamp(240.0, 520.0)
        : (screenSize.height * 0.42).clamp(180.0, 340.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isPortrait ? 420 : 640),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151F32) : const Color(0xFFF1F5F9),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.videoBadge.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: AppColors.videoBadge,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.recording.callerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                '${widget.recording.appSource} ${context.tr("video_label")}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: badgeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.videoBadge,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isPortrait ? 'MP4 (Portrait)' : 'MP4',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isInitialized)
                      IconButton(
                        icon: Icon(
                          _isCoverFit
                              ? Icons.fit_screen_rounded
                              : Icons.crop_free_rounded,
                          size: 20,
                        ),
                        tooltip: _isCoverFit
                            ? context.tr('video_fit_contain')
                            : context.tr('video_fit_cover'),
                        onPressed: () => setState(() => _isCoverFit = !_isCoverFit),
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // Responsive Video Player Area
              Container(
                color: Colors.black,
                height: maxPlayerHeight,
                width: double.infinity,
                child: _hasError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.amber,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : !_isInitialized
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : ClipRect(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                FittedBox(
                                  fit: _isCoverFit ? BoxFit.cover : BoxFit.contain,
                                  child: SizedBox(
                                    width: _controller!.value.size.width > 0
                                        ? _controller!.value.size.width
                                        : 1280,
                                    height: _controller!.value.size.height > 0
                                        ? _controller!.value.size.height
                                        : 720,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                                // Center tap to play/pause
                                GestureDetector(
                                  onTap: () {
                                    if (isPlaying) {
                                      _controller?.pause();
                                    } else {
                                      _controller?.play();
                                    }
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: Center(
                                      child: AnimatedOpacity(
                                        opacity: isPlaying ? 0.0 : 0.85,
                                        duration: const Duration(milliseconds: 200),
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 44,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),

              // Progress bar & time
              if (_isInitialized) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: position.inMilliseconds
                          .clamp(0, duration.inMilliseconds)
                          .toDouble(),
                      max: duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0,
                      onChanged: (val) {
                        _controller?.seekTo(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, size: 26),
                      onPressed: canControl
                          ? () {
                              final current =
                                  _controller?.value.position ?? Duration.zero;
                              _controller?.seekTo(
                                  current - const Duration(seconds: 10));
                            }
                          : null,
                      tooltip: context.tr('video_seek_backward'),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      iconSize: 32,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      onPressed: canControl
                          ? () {
                              if (isPlaying) {
                                _controller?.pause();
                              } else {
                                _controller?.play();
                              }
                            }
                          : null,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, size: 26),
                      onPressed: canControl
                          ? () {
                              final current =
                                  _controller?.value.position ?? Duration.zero;
                              _controller?.seekTo(
                                  current + const Duration(seconds: 10));
                            }
                          : null,
                      tooltip: context.tr('video_seek_forward'),
                    ),
                  ],
                ),
              ),

              // File Path Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.recording.filePath,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.recording.filePath));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('path_copied')),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        visualDensity: VisualDensity.compact,
                        tooltip: context.tr('copy_path'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 14),
                        onPressed: () {
                          Share.shareXFiles([XFile(widget.recording.filePath)],
                              text: 'Record Call (Video): ${widget.recording.callerName}');
                        },
                        visualDensity: VisualDensity.compact,
                        tooltip: context.tr('share'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
