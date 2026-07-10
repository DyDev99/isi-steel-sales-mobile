import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.notes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No notes yet',
                style: TextStyle(color: Vibe.muted, fontSize: 12.5)),
          )
        else
          ...widget.notes.map(
            (n) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Vibe.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Vibe.stroke),
              ),
              child: Text(n,
                  style: const TextStyle(color: Vibe.text, fontSize: 13)),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Vibe.text, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Add a note…',
                  hintStyle: const TextStyle(color: Vibe.muted, fontSize: 13),
                  filled: true,
                  fillColor: Vibe.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Vibe.stroke),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded, color: Vibe.violet),
            ),
          ],
        ),
      ],
    );
  }
}
