import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';
import 'edit_notes_bottom_sheet.dart';

class EditNotesDialog extends StatefulWidget {
  final String initialNotes;

  const EditNotesDialog({super.key, required this.initialNotes});

  static Future<String?> show(BuildContext context, {required String initialNotes}) {
    return EditNotesBottomSheet.show(context, initialNotes: initialNotes);
  }

  @override
  State<EditNotesDialog> createState() => _EditNotesDialogState();
}

class _EditNotesDialogState extends State<EditNotesDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('edit_notes_title'), style: const TextStyle(fontSize: 16)),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(
          hintText: context.tr('edit_notes_hint'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}
