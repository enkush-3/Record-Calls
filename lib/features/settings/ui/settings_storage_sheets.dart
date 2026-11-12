part of 'settings_screen.dart';

extension _SettingsStorageSheets on _SettingsScreenState {
  void _showChangeDirectorySheet() {
    final settings = ref.read(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_special_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.tr('storage_select_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('storage_select_desc'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Predefined directories
            ...settings.availableDirectories.map((dirInfo) {
              final title =
                  dirInfo['title'] ?? context.tr('active_folder_title');
              final path = dirInfo['path'] ?? '';
              final desc = dirInfo['description'];
              final isSelected = settings.storageDirectory == path;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.folder_outlined,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey.shade600,
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (desc != null && desc.isNotEmpty) ...[
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        path,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ref
                        .read(settingsProvider.notifier)
                        .setStorageDirectory(path);
                    if (mounted) {
                      _showSnackBarMessage();
                    }
                  },
                ),
              );
            }),

            const SizedBox(height: 8),

            // Custom path option
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: Text(
                  context.tr('storage_custom_prompt'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.tr('storage_custom_hint'),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showCustomPathBottomSheet(settings.storageDirectory);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomPathBottomSheet(String currentPath) {
    final controller = TextEditingController(text: currentPath);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_location_alt_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('storage_custom_title'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('storage_custom_desc'),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: context.tr('storage_directory_label'),
                  hintText: '/storage/emulated/0/...',
                  filled: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    tooltip: context.tr('storage_paste_tooltip'),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null && data!.text!.isNotEmpty) {
                        controller.text = data.text!.trim();
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('storage_common_paths'),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ActionChip(
                    label: const Text(
                      'Recordings',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      controller.text = '/storage/emulated/0/Recordings';
                    },
                  ),
                  ActionChip(
                    label: const Text(
                      'Music/Recordings',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      controller.text = '/storage/emulated/0/Music/Recordings';
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(context.tr('cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final newPath = controller.text.trim();
                      if (newPath.isNotEmpty) {
                        Navigator.of(ctx).pop();
                        await ref
                            .read(settingsProvider.notifier)
                            .setStorageDirectory(newPath);
                        if (mounted) {
                          _showSnackBarMessage();
                        }
                      }
                    },
                    child: Text(context.tr('save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
