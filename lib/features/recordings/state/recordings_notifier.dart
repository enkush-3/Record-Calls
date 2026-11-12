import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/bridge/native_bridge.dart';
import '../../../core/bridge/recording_event.dart';
import '../../../core/database/recording_entity.dart';
import '../../../core/database/recordings_repository.dart';
import 'recording_filter.dart';
import 'recordings_state.dart';

class RecordingsNotifier extends StateNotifier<RecordingsState> {
  final RecordingsRepository _repository;
  final NativeBridge _bridge;
  StreamSubscription<RecordingEvent>? _streamSubscription;

  RecordingsNotifier(this._repository, this._bridge)
    : super(RecordingsState.initial()) {
    _init();
  }

  void _init() {
    _streamSubscription = _bridge.recordingStream.listen((event) async {
      if (event is RecordingCompletedEvent) {
        // Auto-refresh recordings list when a background recording finishes
        await syncPendingRecordings();
        await loadRecordings();
      }
    });

    _syncAndLoad();
  }

  Future<void> _syncAndLoad() async {
    // Reconcile recordings captured while the UI was detached.
    await syncPendingRecordings();
    if (!mounted) return;
    // 2. Load auto record setting
    final autoRecord = await _bridge.isAutoRecordEnabled();
    if (!mounted) return;
    state = state.copyWith(isAutoRecordEnabled: autoRecord);
    // 3. Load recordings from SQLite
    await loadRecordings();
  }

  Future<void> syncPendingRecordings() async {
    try {
      final pending = await _bridge.fetchPendingRecordings();
      if (pending.isNotEmpty) {
        await _repository.syncPendingRecordings(pending);
      }
    } catch (_) {}
  }

  Future<void> syncOfflineQueue() => syncPendingRecordings();

  Future<void> loadRecordings() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Determine effective filters:
      final String? appSource =
          state.selectedAppSource ?? state.activeFilter.appSourceValue;
      final String? mediaType =
          state.selectedMediaType ?? state.activeFilter.mediaType;
      final bool favoritesOnly =
          state.favoritesOnly ||
          state.activeFilter == RecordingFilter.favorites;

      final list = await _repository.queryRecordings(
        searchQuery: state.searchQuery,
        appSource: appSource,
        mediaType: mediaType,
        favoritesOnly: favoritesOnly,
        sortBy: state.sortBy,
        sortAscending: state.sortAscending,
      );

      if (!mounted) return;
      state = state.copyWith(recordings: list, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(RecordingFilter filter) {
    if (state.activeFilter == filter &&
        state.selectedAppSource == null &&
        state.selectedMediaType == null &&
        !state.favoritesOnly) {
      return;
    }

    state = state.copyWith(
      activeFilter: filter,
      selectedAppSource: () => filter.appSourceValue,
      selectedMediaType: () => filter.mediaType,
      favoritesOnly: filter == RecordingFilter.favorites,
    );
    loadRecordings();
  }

  void applyFilterAndSort({
    String? appSource,
    String? mediaType,
    bool favoritesOnly = false,
    String? sortBy,
    bool? sortAscending,
  }) {
    RecordingFilter matchingFilter = RecordingFilter.all;
    if (appSource != null &&
        appSource.isNotEmpty &&
        mediaType == null &&
        !favoritesOnly) {
      for (final f in RecordingFilter.values) {
        if (f.appSourceValue?.toLowerCase() == appSource.toLowerCase()) {
          matchingFilter = f;
          break;
        }
      }
    } else if (mediaType == 'audio' && appSource == null && !favoritesOnly) {
      matchingFilter = RecordingFilter.audio;
    } else if (mediaType == 'video' && appSource == null && !favoritesOnly) {
      matchingFilter = RecordingFilter.video;
    } else if (favoritesOnly && appSource == null && mediaType == null) {
      matchingFilter = RecordingFilter.favorites;
    }

    state = state.copyWith(
      activeFilter: matchingFilter,
      selectedAppSource: () => appSource,
      selectedMediaType: () => mediaType,
      favoritesOnly: favoritesOnly,
      sortBy: sortBy ?? state.sortBy,
      sortAscending: sortAscending ?? state.sortAscending,
    );
    loadRecordings();
  }

  void resetFilters() {
    state = state.copyWith(
      activeFilter: RecordingFilter.all,
      selectedAppSource: () => null,
      selectedMediaType: () => null,
      favoritesOnly: false,
      sortBy: 'created_at',
      sortAscending: false,
    );
    loadRecordings();
  }

  void setSort(String sortBy, bool ascending) {
    if (state.sortBy == sortBy && state.sortAscending == ascending) return;
    state = state.copyWith(sortBy: sortBy, sortAscending: ascending);
    loadRecordings();
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    loadRecordings();
  }

  Future<void> toggleFavorite(RecordingEntity entity) async {
    if (entity.id == null) return;
    final newFavorite = !entity.isFavorite;
    await _repository.toggleFavorite(entity.id!, newFavorite);
    await loadRecordings();
  }

  Future<void> updateNotes(RecordingEntity entity, String? notes) async {
    if (entity.id == null) return;
    await _repository.updateNotes(entity.id!, notes);
    await loadRecordings();
  }

  Future<void> deleteRecording(RecordingEntity entity) async {
    await _repository.deleteRecording(entity);
    await loadRecordings();
  }

  Future<void> toggleAutoRecord() async {
    final next = !state.isAutoRecordEnabled;
    await _bridge.setAutoRecordEnabled(next);
    state = state.copyWith(isAutoRecordEnabled: next);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
