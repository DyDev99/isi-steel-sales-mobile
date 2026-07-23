import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class NotesSection extends StatefulWidget {
  const NotesSection({super.key, required this.notes, required this.onAddNote});
  final List<String> notes;
  final ValueChanged<String> onAddNote;

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAddNote(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('leads.no_notes'.tr,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          )
        else
          ...widget.notes.map(
            (n) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Text(n,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'leads.add_note_hint'.tr,
                  hintStyle:
                      TextStyle(color: colors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: colors.card,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _submit,
              icon: Icon(Icons.send_rounded, color: scheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}
