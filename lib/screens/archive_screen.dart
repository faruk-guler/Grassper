import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../models/note_model.dart';
import 'note_editor.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context);
    final theme = Theme.of(context);
    final archivedNotes = provider.notes.where((n) => n.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.archivedNotes, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: archivedNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: theme.dividerColor),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noArchivedNotes,
                    style: TextStyle(color: theme.iconTheme.color),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: archivedNotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = archivedNotes[index];
                return _buildArchiveCard(context, note, provider, theme);
              },
            ),
    );
  }

  Widget _buildArchiveCard(BuildContext context, Note note, NoteProvider provider, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? AppStrings.untitledNote : note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.unarchive, size: 20),
                      onPressed: () => provider.unarchiveNote(note),
                      tooltip: AppStrings.unarchive,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                      onPressed: () => provider.deleteNote(note),
                      tooltip: AppStrings.delete,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              style: TextStyle(color: theme.iconTheme.color, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
