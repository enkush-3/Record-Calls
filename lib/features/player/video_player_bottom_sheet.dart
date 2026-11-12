import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../core/database/recording_entity.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

class VideoPlayerBottomSheet extends StatefulWidget {
  final RecordingEntity recording;

  const VideoPlayerBottomSheet({super.key, required this.recording});

  static Future<void> show(BuildContext context, RecordingEntity recording) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VideoPlayerBottomSheet(recording: recording),
    );
  }

  @override
  State<VideoPlayerBottomSheet> createState() => _VideoPlayerBottomSheetState();
}

class _VideoPlayerBottomSheetState extends State<VideoPlayerBottomSheet> {
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
          _errorMessage = context.tr(
            'file_not_found',
            params: {'path': widget.recording.filePath},
          );
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
              _errorMessage =
                  controller.value.errorDescription ??
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
          _errorMessage = context.tr(
            'video_play_error',
            params: {'error': e.toString()},
          );
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final position = _controller?.value.position ?? Duration.zero;
    final duration =
        _controller?.value.duration ??
        Duration(seconds: widget.recording.durationSec);
    final isPlaying = _controller?.value.isPlaying ?? false;
    final bool canControl = _isInitialized && !_hasError && _controller != null;

    final rawAspect = (_controller != null && _controller!.value.isInitialized)
        ? _controller!.value.aspectRatio
        : (16 / 9);
    final aspect = rawAspect > 0 ? rawAspect : (16 / 9);
    final isPortrait = aspect < 1.0;

    final maxPlayerHeight = isPortrait
        ? (screenSize.height * 0.48).clamp(200.0, 420.0)
        : (screenSize.height * 0.38).clamp(160.0, 300.0);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.92 - keyboardInset,
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + keyboardInset),
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
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.videoBadge.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: AppColors.videoBadge,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recording.callerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              '${widget.recording.appSource} ${context.tr('video_label')}',
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
                      onPressed: () =>
                          setState(() => _isCoverFit = !_isCoverFit),
                      visualDensity: VisualDensity.compact,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Video Display Box
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
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
                                  size: 36,
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
                      : (!_isInitialized
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Center(
                                child: AspectRatio(
                                  aspectRatio: aspect,
                                  child: FittedBox(
                                    fit: _isCoverFit
                                        ? BoxFit.cover
                                        : BoxFit.contain,
                                    child: SizedBox(
                                      width: _controller!.value.size.width,
                                      height: _controller!.value.size.height,
                                      child: VideoPlayer(_controller!),
                                    ),
                                  ),
                                ),
                              )),
                ),
              ),

              const SizedBox(height: 12),

              // Progress slider & time labels
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor: theme.colorScheme.primary.withValues(
                    alpha: 0.2,
                  ),
                  thumbColor: theme.colorScheme.primary,
                ),
                child: Slider(
                  value: duration.inMilliseconds > 0
                      ? position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble()
                      : 0.0,
                  max: duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: canControl
                      ? (val) {
                          _controller?.seekTo(
                            Duration(milliseconds: val.toInt()),
                          );
                        }
                      : null,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Control buttons: Seek -10s, Play/Pause, Seek +10s
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.replay_10_rounded),
                    iconSize: 22,
                    tooltip: context.tr('video_seek_backward'),
                    onPressed: canControl
                        ? () {
                            final target =
                                position - const Duration(seconds: 10);
                            _controller?.seekTo(
                              target < Duration.zero ? Duration.zero : target,
                            );
                          }
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      iconSize: 34,
                      onPressed: canControl
                          ? () {
                              if (isPlaying) {
                                _controller?.pause();
                              } else {
                                if (position >= duration) {
                                  _controller?.seekTo(Duration.zero);
                                }
                                _controller?.play();
                              }
                              setState(() {});
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.forward_10_rounded),
                    iconSize: 22,
                    tooltip: context.tr('video_seek_forward'),
                    onPressed: canControl
                        ? () {
                            final target =
                                position + const Duration(seconds: 10);
                            _controller?.seekTo(
                              target > duration ? duration : target,
                            );
                          }
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Bottom Path Bar & Actions
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.recording.filePath,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: context.tr('copy_path'),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.recording.filePath),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('path_copied')),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 16),
                      tooltip: context.tr('share'),
                      onPressed: () {
                        Share.shareXFiles([
                          XFile(widget.recording.filePath),
                        ], text: 'Record Call: ${widget.recording.callerName}');
                      },
                      visualDensity: VisualDensity.compact,
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
