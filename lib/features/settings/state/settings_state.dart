class SettingsState {
  final String storageDirectory;
  final List<Map<String, String>> availableDirectories;
  final int freeSpaceBytes;
  final int totalSpaceBytes;
  final int recordingFilesCount;
  final bool isWritable;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final String? errorMessage;

  // Audio Recording Source: 'both' (default), 'mic_only', 'remote_only'
  final String audioRecordingSource;

  const SettingsState({
    required this.storageDirectory,
    this.availableDirectories = const [],
    this.freeSpaceBytes = 0,
    this.totalSpaceBytes = 0,
    this.recordingFilesCount = 0,
    this.isWritable = true,
    this.isLoading = false,
    this.isSaving = false,
    this.message,
    this.errorMessage,
    this.audioRecordingSource = 'both',
  });

  factory SettingsState.initial() {
    return const SettingsState(
      storageDirectory: '',
      availableDirectories: [],
      freeSpaceBytes: 0,
      totalSpaceBytes: 0,
      recordingFilesCount: 0,
      isWritable: true,
      isLoading: true,
      audioRecordingSource: 'both',
    );
  }

  SettingsState copyWith({
    String? storageDirectory,
    List<Map<String, String>>? availableDirectories,
    int? freeSpaceBytes,
    int? totalSpaceBytes,
    int? recordingFilesCount,
    bool? isWritable,
    bool? isLoading,
    bool? isSaving,
    String? message,
    String? errorMessage,
    String? audioRecordingSource,
  }) {
    return SettingsState(
      storageDirectory: storageDirectory ?? this.storageDirectory,
      availableDirectories: availableDirectories ?? this.availableDirectories,
      freeSpaceBytes: freeSpaceBytes ?? this.freeSpaceBytes,
      totalSpaceBytes: totalSpaceBytes ?? this.totalSpaceBytes,
      recordingFilesCount: recordingFilesCount ?? this.recordingFilesCount,
      isWritable: isWritable ?? this.isWritable,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      message: message,
      errorMessage: errorMessage,
      audioRecordingSource: audioRecordingSource ?? this.audioRecordingSource,
    );
  }
}
