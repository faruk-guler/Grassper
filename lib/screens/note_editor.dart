import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../core/constants.dart';
import '../core/strings.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isPinned = false;
  bool _isImportant = false;
  int? _colorValue;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _isPinned = widget.note?.isPinned ?? false;
    _isImportant = widget.note?.isImportant ?? false;
    _colorValue = widget.note?.colorValue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.noteEmpty),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
      return;
    }

    final provider = Provider.of<NoteProvider>(context, listen: false);

    if (widget.note != null) {
      // Update existing
      widget.note!.title = title;
      widget.note!.content = content;
      widget.note!.isPinned = _isPinned;
      widget.note!.isImportant = _isImportant;
      widget.note!.colorValue = _colorValue;
      widget.note!.updatedAt = DateTime.now().millisecondsSinceEpoch;
      provider.saveNote(widget.note!);
    } else {
      // Create new — use UUID for collision-safe IDs
      final now = DateTime.now().millisecondsSinceEpoch;
      final newNote = Note(
        id: const Uuid().v4(),
        title: title,
        content: content,
        isPinned: _isPinned,
        isImportant: _isImportant,
        colorValue: _colorValue,
        updatedAt: now,
        createdAt: now,
      );
      provider.saveNote(newNote);
    }
    
    Navigator.pop(context);
  }

  void _deleteNote() {
    if (widget.note != null) {
      final provider = Provider.of<NoteProvider>(context, listen: false);
      provider.deleteNote(widget.note!);
    }
    Navigator.pop(context);
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 120,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: AppColors.noteColors.length,
            itemBuilder: (context, index) {
              final color = AppColors.noteColors[index];
              return GestureDetector(
                onTap: () {
                  setState(() => _colorValue = color == Colors.transparent ? null : color.value);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: color == Colors.transparent ? Theme.of(context).scaffoldBackgroundColor : color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (_colorValue == color.value || (color == Colors.transparent && _colorValue == null))
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.3),
                      width: 2.5,
                    ),
                    boxShadow: [
                      if (color != Colors.transparent)
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: (_colorValue == color.value || (color == Colors.transparent && _colorValue == null))
                      ? Icon(
                          color == Colors.transparent ? Icons.block : Icons.check,
                          color: (color == Colors.transparent || color.computeLuminance() > 0.5)
                              ? Colors.black87
                              : Colors.white,
                        )
                      : (color == Colors.transparent ? const Icon(Icons.block, size: 16, color: Colors.grey) : null),
                ),
              );
            },
          ),
        );
      },
    );
  }  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = _colorValue != null ? Color(_colorValue!) : theme.scaffoldBackgroundColor;
    final isDarkColor = _colorValue != null && Color(_colorValue!).computeLuminance() < 0.5;
    final textColor = _colorValue != null 
        ? (isDarkColor ? Colors.white : Colors.black87)
        : theme.textTheme.bodyLarge?.color;
    final hintColor = textColor?.withOpacity(0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: _saveNote,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.palette_outlined, color: textColor),
            onPressed: _showColorPicker,
          ),
          IconButton(
            icon: Icon(Icons.share, color: textColor),
            onPressed: () {
              final title = _titleController.text.trim();
              final content = _contentController.text.trim();
              if (title.isNotEmpty || content.isNotEmpty) {
                Share.share('$title\n\n$content');
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.push_pin,
              color: _isImportant 
                  ? AppColors.danger 
                  : (_isPinned ? (_colorValue != null ? textColor : theme.primaryColor) : textColor),
            ),
            onPressed: () {
              setState(() {
                if (!_isPinned) {
                  _isPinned = true;
                } else if (!_isImportant) {
                  _isImportant = true;
                } else {
                  _isPinned = false;
                  _isImportant = false;
                }
              });
            },
          ),
          if (widget.note != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: _colorValue != null ? textColor : AppColors.danger),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text(AppStrings.deleteNote),
                    content: const Text(AppStrings.deleteNoteConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(AppStrings.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteNote();
                        },
                        child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorValue != null ? textColor : theme.primaryColor,
                foregroundColor: _colorValue != null ? bgColor : theme.scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(AppStrings.save),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                decoration: InputDecoration(
                  hintText: AppStrings.titleHint,
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  style: TextStyle(fontSize: 17, height: 1.5, color: textColor),
                  decoration: InputDecoration(
                    hintText: AppStrings.contentHint,
                    hintStyle: TextStyle(color: hintColor),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
