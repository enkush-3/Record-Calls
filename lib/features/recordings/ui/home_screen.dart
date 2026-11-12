import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../player/audio_player_bottom_sheet.dart';
import '../../player/player_state_notifier.dart';
import '../../player/video_player_bottom_sheet.dart';
import '../../settings/ui/settings_screen.dart';
import '../state/recording_filter.dart';
import '../state/live_recording_notifier.dart';
import '../state/recordings_notifier.dart';
import '../state/recordings_state.dart';
import 'widgets/filter_chip_bar.dart';
import 'widgets/live_recording_indicator.dart';
import 'widgets/recording_card.dart';
import 'widgets/structured_filter_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startMicAudioTest(LiveRecordingNotifier notifier) async {
    await notifier.startManualAudioRecording();
  }

  Future<void> _startMicVideoTest(LiveRecordingNotifier notifier) async {
    final started = await notifier.startManualVideoRecording();
    if (!started && mounted) _showCaptureCancelledMessage();
  }

  void _showCaptureCancelledMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('screen_capture_cancelled'))),
    );
  }

  void _openFilterSheet(
    BuildContext context,
    RecordingsState state,
    RecordingsNotifier notifier,
  ) async {
    final result = await StructuredFilterSheet.show(
      context,
      currentOptions: FilterSortOptions(
        filter: state.activeFilter,
        appSource: state.selectedAppSource,
        mediaType: state.selectedMediaType,
        favoritesOnly: state.favoritesOnly,
        sortBy: state.sortBy,
        sortAscending: state.sortAscending,
      ),
    );
    if (result != null) {
      notifier.applyFilterAndSort(
        appSource: result.appSource,
        mediaType: result.mediaType,
        favoritesOnly: result.favoritesOnly,
        sortBy: result.sortBy,
        sortAscending: result.sortAscending,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appLocaleProvider);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && theme.brightness == Brightness.dark);
    final recordingsState = ref.watch(recordingsProvider);
    final recordingsNotifier = ref.read(recordingsProvider.notifier);
    final liveState = ref.watch(liveRecordingProvider);
    final liveNotifier = ref.read(liveRecordingProvider.notifier);
    ref.listen<String?>(
      liveRecordingProvider.select((state) => state.warningKey),
      (previous, messageKey) {
        if (messageKey == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr(messageKey))));
        liveNotifier.clearWarning();
      },
    );

    final isCustomFilterActive =
        recordingsState.selectedAppSource != null ||
        recordingsState.selectedMediaType != null ||
        recordingsState.favoritesOnly ||
        recordingsState.sortBy != 'created_at' ||
        recordingsState.sortAscending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Call'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: isDark
                ? context.tr('theme_toggle_light')
                : context.tr('theme_toggle_dark'),
            onPressed: () {
              final next = isDark ? ThemeMode.light : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).setThemeMode(next);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.tr('settings'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('auto'),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Switch(
                      value: recordingsState.isAutoRecordEnabled,
                      onChanged: (_) => recordingsNotifier.toggleAutoRecord(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.tr('search_placeholder'),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                recordingsNotifier.setSearchQuery('');
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                    ),
                    onChanged: (val) {
                      recordingsNotifier.setSearchQuery(val);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: Badge(
                    isLabelVisible: isCustomFilterActive,
                    child: const Icon(Icons.tune_rounded, size: 20),
                  ),
                  tooltip: context.tr('filter_and_sort_tooltip'),
                  onPressed: () => _openFilterSheet(
                    context,
                    recordingsState,
                    recordingsNotifier,
                  ),
                ),
              ],
            ),
          ),

          // Live Recording Status / Manual Record Buttons
          LiveRecordingIndicator(
            isRecording: liveState.isRecording,
            callerNumber: liveState.callerNumber,
            appSource: liveState.appSource,
            amplitude: liveState.amplitude,
            elapsedSeconds: liveState.elapsedSeconds,
            mediaType: liveState.mediaType,
            onToggle: () => liveNotifier.toggleManualRecording(),
            onStartAudio: () => _startMicAudioTest(liveNotifier),
            onStartVideo: () => _startMicVideoTest(liveNotifier),
            onStop: () => liveNotifier.stopRecording(),
          ),

          // Primary Filter Chips
          FilterChipBar(
            activeFilter: recordingsState.activeFilter,
            onFilterSelected: (filter) => recordingsNotifier.setFilter(filter),
          ),
          const SizedBox(height: 4),

          // Recordings List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await recordingsNotifier.syncOfflineQueue();
                await recordingsNotifier.loadRecordings();
              },
              child: recordingsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : recordingsState.recordings.isEmpty
                  ? _buildEmptyState(theme, recordingsState.activeFilter)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 12, top: 4),
                      itemCount: recordingsState.recordings.length,
                      itemBuilder: (context, index) {
                        final recording = recordingsState.recordings[index];

                        return RecordingCard(
                          recording: recording,
                          onPlay: () {
                            if (recording.mediaType == 'video') {
                              ref.read(playerProvider.notifier).pause();
                              VideoPlayerBottomSheet.show(context, recording);
                            } else {
                              ref
                                  .read(playerProvider.notifier)
                                  .playRecording(recording);
                              AudioPlayerBottomSheet.show(context, recording);
                            }
                          },
                          onToggleFavorite: () =>
                              recordingsNotifier.toggleFavorite(recording),
                          onUpdateNotes: (notes) =>
                              recordingsNotifier.updateNotes(recording, notes),
                          onDelete: () =>
                              recordingsNotifier.deleteRecording(recording),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, RecordingFilter filter) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                filter == RecordingFilter.favorites
                    ? Icons.star_border_rounded
                    : Icons.graphic_eq_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              filter == RecordingFilter.favorites
                  ? context.tr('no_favorites')
                  : context.tr('no_recordings'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('no_recordings_sub'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
