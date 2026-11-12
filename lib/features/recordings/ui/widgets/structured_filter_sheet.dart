import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/recording_filter.dart';

class FilterSortOptions {
  final RecordingFilter filter;
  final String? appSource;
  final String? mediaType;
  final bool favoritesOnly;
  final String sortBy;
  final bool sortAscending;

  const FilterSortOptions({
    this.filter = RecordingFilter.all,
    this.appSource,
    this.mediaType,
    this.favoritesOnly = false,
    this.sortBy = 'created_at',
    this.sortAscending = false,
  });

  bool get isCustomFilter =>
      appSource != null ||
      mediaType != null ||
      favoritesOnly ||
      sortBy != 'created_at' ||
      sortAscending;
}

class StructuredFilterSheet extends StatefulWidget {
  final FilterSortOptions currentOptions;

  const StructuredFilterSheet({super.key, required this.currentOptions});

  static Future<FilterSortOptions?> show(
    BuildContext context, {
    required FilterSortOptions currentOptions,
  }) {
    return showModalBottomSheet<FilterSortOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StructuredFilterSheet(currentOptions: currentOptions),
    );
  }

  @override
  State<StructuredFilterSheet> createState() => _StructuredFilterSheetState();
}

class _StructuredFilterSheetState extends State<StructuredFilterSheet> {
  late String? _appSource;
  late String? _mediaType;
  late bool _favoritesOnly;
  late String _sortBy;
  late bool _sortAscending;

  @override
  void initState() {
    super.initState();
    _appSource =
        widget.currentOptions.appSource ??
        widget.currentOptions.filter.appSourceValue;
    _mediaType =
        widget.currentOptions.mediaType ??
        widget.currentOptions.filter.mediaType;
    _favoritesOnly =
        widget.currentOptions.favoritesOnly ||
        widget.currentOptions.filter == RecordingFilter.favorites;
    _sortBy = widget.currentOptions.sortBy;
    _sortAscending = widget.currentOptions.sortAscending;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            color: theme.brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.3 : 0.15,
            ),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('filter_and_sort_tooltip'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _appSource = null;
                    _mediaType = null;
                    _favoritesOnly = false;
                    _sortBy = 'created_at';
                    _sortAscending = false;
                  });
                },
                child: Text(context.tr('clear')),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              children: [
                // App Source Filter
                _buildFilterHeader(context.tr('filter_app_source')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: context.tr('filter_all'),
                      isSelected: _appSource == null,
                      onSelected: () => setState(() => _appSource = null),
                    ),
                    _buildChoiceChip(
                      label: context.tr('filter_cellular'),
                      isSelected: _appSource == 'Cellular',
                      onSelected: () => setState(() => _appSource = 'Cellular'),
                    ),
                    _buildChoiceChip(
                      label: 'Viber',
                      isSelected: _appSource == 'Viber',
                      onSelected: () => setState(() => _appSource = 'Viber'),
                    ),
                    _buildChoiceChip(
                      label: 'Telegram',
                      isSelected: _appSource == 'Telegram',
                      onSelected: () => setState(() => _appSource = 'Telegram'),
                    ),
                    _buildChoiceChip(
                      label: 'WhatsApp',
                      isSelected: _appSource == 'WhatsApp',
                      onSelected: () => setState(() => _appSource = 'WhatsApp'),
                    ),
                    _buildChoiceChip(
                      label: 'Messenger',
                      isSelected: _appSource == 'Messenger',
                      onSelected: () =>
                          setState(() => _appSource = 'Messenger'),
                    ),
                    _buildChoiceChip(
                      label: 'WeChat',
                      isSelected: _appSource == 'WeChat',
                      onSelected: () => setState(() => _appSource = 'WeChat'),
                    ),
                    _buildChoiceChip(
                      label: 'Instagram',
                      isSelected: _appSource == 'Instagram',
                      onSelected: () => setState(() => _appSource = 'Instagram'),
                    ),
                    _buildChoiceChip(
                      label: 'Discord',
                      isSelected: _appSource == 'Discord',
                      onSelected: () => setState(() => _appSource = 'Discord'),
                    ),
                    _buildChoiceChip(
                      label: 'Signal',
                      isSelected: _appSource == 'Signal',
                      onSelected: () => setState(() => _appSource = 'Signal'),
                    ),
                    _buildChoiceChip(
                      label: 'LINE',
                      isSelected: _appSource == 'LINE',
                      onSelected: () => setState(() => _appSource = 'LINE'),
                    ),
                    _buildChoiceChip(
                      label: 'Skype',
                      isSelected: _appSource == 'Skype',
                      onSelected: () => setState(() => _appSource = 'Skype'),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 3. Media Format Filter
                _buildFilterHeader(context.tr('filter_media_format')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: context.tr('filter_all_formats'),
                      isSelected: _mediaType == null,
                      icon: Icons.perm_media_outlined,
                      onSelected: () => setState(() => _mediaType = null),
                    ),
                    _buildChoiceChip(
                      label: '${context.tr('audio_label')} (M4A)',
                      isSelected: _mediaType == 'audio',
                      icon: Icons.mic_rounded,
                      onSelected: () => setState(() => _mediaType = 'audio'),
                    ),
                    _buildChoiceChip(
                      label: '${context.tr('video_label')} (MP4)',
                      isSelected: _mediaType == 'video',
                      icon: Icons.videocam_rounded,
                      onSelected: () => setState(() => _mediaType = 'video'),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 4. Favorites Filter
                _buildFilterHeader(context.tr('filter_special')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      avatar: Icon(
                        _favoritesOnly
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 16,
                        color: _favoritesOnly ? Colors.white : Colors.amber,
                      ),
                      label: Text(context.tr('filter_favorites_only')),
                      selected: _favoritesOnly,
                      selectedColor: theme.colorScheme.primary,
                      onSelected: (val) => setState(() => _favoritesOnly = val),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 5. Sort By
                _buildFilterHeader(context.tr('filter_sort_order')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: context.tr('sort_newest'),
                      isSelected: _sortBy == 'created_at' && !_sortAscending,
                      icon: Icons.arrow_downward_rounded,
                      onSelected: () => setState(() {
                        _sortBy = 'created_at';
                        _sortAscending = false;
                      }),
                    ),
                    _buildChoiceChip(
                      label: context.tr('sort_oldest'),
                      isSelected: _sortBy == 'created_at' && _sortAscending,
                      icon: Icons.arrow_upward_rounded,
                      onSelected: () => setState(() {
                        _sortBy = 'created_at';
                        _sortAscending = true;
                      }),
                    ),
                    _buildChoiceChip(
                      label: context.tr('sort_size'),
                      isSelected: _sortBy == 'file_size',
                      icon: Icons.data_usage_rounded,
                      onSelected: () => setState(() {
                        _sortBy = 'file_size';
                        _sortAscending = false;
                      }),
                    ),
                    _buildChoiceChip(
                      label: context.tr('sort_duration'),
                      isSelected: _sortBy == 'duration_sec',
                      icon: Icons.timer_outlined,
                      onSelected: () => setState(() {
                        _sortBy = 'duration_sec';
                        _sortAscending = false;
                      }),
                    ),
                    _buildChoiceChip(
                      label: context.tr('sort_name_az'),
                      isSelected: _sortBy == 'caller_name',
                      icon: Icons.sort_by_alpha_rounded,
                      onSelected: () => setState(() {
                        _sortBy = 'caller_name';
                        _sortAscending = true;
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  FilterSortOptions(
                    appSource: _appSource,
                    mediaType: _mediaType,
                    favoritesOnly: _favoritesOnly,
                    sortBy: _sortBy,
                    sortAscending: _sortAscending,
                  ),
                );
              },
              child: Text(context.tr('apply_filter_btn')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            )
          : null,
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : const Color(0xFFF1F5F9),
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.grey.shade300 : Colors.blueGrey.shade800),
      ),
    );
  }
}
