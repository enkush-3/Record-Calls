import '../../../core/database/recording_entity.dart';
import 'recording_filter.dart';

class RecordingsState {
  final List<RecordingEntity> recordings;
  final bool isLoading;
  final String searchQuery;
  final RecordingFilter activeFilter;
  final bool isAutoRecordEnabled;
  final String? error;

  // Enhanced Filter & Sort
  final String? selectedAppSource; // null for All, or specific app source
  final String? selectedMediaType; // null for All, or 'audio', 'video'
  final bool favoritesOnly;
  final String
  sortBy; // 'created_at', 'file_size', 'duration_sec', 'caller_name'
  final bool sortAscending;

  const RecordingsState({
    required this.recordings,
    this.isLoading = false,
    this.searchQuery = '',
    this.activeFilter = RecordingFilter.all,
    this.isAutoRecordEnabled = true,
    this.error,
    this.selectedAppSource,
    this.selectedMediaType,
    this.favoritesOnly = false,
    this.sortBy = 'created_at',
    this.sortAscending = false,
  });

  factory RecordingsState.initial() {
    return const RecordingsState(
      recordings: [],
      isLoading: true,
      searchQuery: '',
      activeFilter: RecordingFilter.all,
      isAutoRecordEnabled: true,
      selectedAppSource: null,
      selectedMediaType: null,
      favoritesOnly: false,
      sortBy: 'created_at',
      sortAscending: false,
    );
  }

  RecordingsState copyWith({
    List<RecordingEntity>? recordings,
    bool? isLoading,
    String? searchQuery,
    RecordingFilter? activeFilter,
    bool? isAutoRecordEnabled,
    String? error,
    String? Function()? selectedAppSource,
    String? Function()? selectedMediaType,
    bool? favoritesOnly,
    String? sortBy,
    bool? sortAscending,
  }) {
    return RecordingsState(
      recordings: recordings ?? this.recordings,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      isAutoRecordEnabled: isAutoRecordEnabled ?? this.isAutoRecordEnabled,
      error: error,
      selectedAppSource: selectedAppSource != null
          ? selectedAppSource()
          : this.selectedAppSource,
      selectedMediaType: selectedMediaType != null
          ? selectedMediaType()
          : this.selectedMediaType,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
