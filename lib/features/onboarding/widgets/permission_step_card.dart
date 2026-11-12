import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';

class PermissionStepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final bool isCompleted;
  final Widget child;

  const PermissionStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCompleted ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isCompleted
                      ? Colors.green
                      : theme.colorScheme.primary,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$stepNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? (isDark
                                ? Colors.green.shade300
                                : Colors.green.shade700)
                          : theme.textTheme.titleMedium?.color,
                    ),
                  ),
                ),
                if (isCompleted)
                  Chip(
                    label: Text(
                      context.tr('granted_badge'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.green.shade300
                            : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF14331C)
                        : const Color(0xFFE8F5E9),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
