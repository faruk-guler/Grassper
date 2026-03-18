import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../models/note_model.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  void _showPermanentDeleteDialog(BuildContext context, Note note, NoteProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kalıcı Olarak Sil?'),
        content: const Text('Bu not kalıcı olarak silinecek ve geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              provider.permanentDelete(note);
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context);
    final theme = Theme.of(context);
    final deletedNotes = provider.trash;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.trash, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        actions: [
          if (deletedNotes.isNotEmpty)
            TextButton(
              onPressed: () => _showEmptyTrashDialog(context, provider),
              child: const Text(AppStrings.emptyTrash, style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
      body: deletedNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: theme.dividerColor),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.trashEmpty,
                    style: TextStyle(color: theme.iconTheme.color),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: deletedNotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = deletedNotes[index];
                return _buildTrashCard(context, note, provider, theme);
              },
            ),
    );
  }

  void _showEmptyTrashDialog(BuildContext context, NoteProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.emptyTrashTitle),
        content: const Text(AppStrings.emptyTrashConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              provider.emptyTrash();
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.emptyTrash, style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashCard(BuildContext context, Note note, NoteProvider provider, ThemeData theme) {
    return Container(
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
                    icon: const Icon(Icons.restore, size: 20),
                    onPressed: () => provider.restoreFromTrash(note),
                    tooltip: AppStrings.restore,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, size: 20, color: AppColors.danger),
                    onPressed: () => _showPermanentDeleteDialog(context, note, provider),
                    tooltip: AppStrings.permanentDelete,
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
    );
  }
}
