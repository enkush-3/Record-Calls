import 'package:flutter/material.dart';
import '../../state/recording_filter.dart';

class FilterChipBar extends StatelessWidget {
  final RecordingFilter activeFilter;
  final ValueChanged<RecordingFilter> onFilterSelected;

  const FilterChipBar({
    super.key,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: RecordingFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = RecordingFilter.values[index];
          final isSelected = filter == activeFilter;

          IconData? icon;
          if (filter == RecordingFilter.video) {
            icon = Icons.videocam_rounded;
          } else if (filter == RecordingFilter.audio) {
            icon = Icons.audiotrack_rounded;
          } else if (filter == RecordingFilter.favorites) {
            icon = Icons.star_rounded;
          }

          return ChoiceChip(
            avatar: icon != null
                ? Icon(
                    icon,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? Colors.grey.shade400
                              : Colors.blueGrey.shade600),
                  )
                : null,
            label: Text(filter.getLocalizedLabel(context)),
            selected: isSelected,
            selectedColor: theme.colorScheme.primary,
            backgroundColor: isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  )
                : const Color(0xFFF1F5F9),
            onSelected: (_) => onFilterSelected(filter),
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
              ),
            ),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade300 : Colors.blueGrey.shade800),
            ),
          );
        },
      ),
    );
  }
}
