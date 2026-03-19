import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import 'sketch_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  int? _colorValue;
  String? _imageBase64;
  Note? _activeNote;

  @override
  void initState() {
    super.initState();
    _activeNote = widget.note;
    _titleController = TextEditingController(text: _activeNote?.title ?? '');
    _contentController = TextEditingController(text: _activeNote?.content ?? '');
    _colorValue = _activeNote?.colorValue;
    _imageBase64 = _activeNote?.imageBase64;
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

    if (title.isEmpty && content.isEmpty && _imageBase64 == null) {
      if (_activeNote != null) {
        Provider.of<NoteProvider>(context, listen: false).deleteNote(_activeNote!);
      }
      return;
    }

    final provider = Provider.of<NoteProvider>(context, listen: false);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_activeNote != null) {
      // Update existing
      _activeNote!.title = title;
      _activeNote!.content = content;
      _activeNote!.colorValue = _colorValue;
      _activeNote!.imageBase64 = _imageBase64;
      _activeNote!.updatedAt = now;
      provider.saveNote(_activeNote!);
    } else {
      // Create new - ONLY save if title or content is NOT empty
      // This prevents auto-saving pure camera photos if user discards from NoteEditor
      if (title.isEmpty && content.isEmpty) {
        return; 
      }
      
      _activeNote = Note(
        id: const Uuid().v4(),
        title: title,
        content: content,
        isPinned: false,
        isImportant: false,
        colorValue: _colorValue,
        imageBase64: _imageBase64,
        updatedAt: now,
        createdAt: now,
      );
      provider.saveNote(_activeNote!);
    }
  }

  void _deleteNote() {
    if (_activeNote != null) {
      final provider = Provider.of<NoteProvider>(context, listen: false);
      provider.deleteNote(_activeNote!);
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
                  _saveNote(); // Auto-save on color change
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = _colorValue != null ? Color(_colorValue!) : theme.scaffoldBackgroundColor;
    final isDarkColor = _colorValue != null && Color(_colorValue!).computeLuminance() < 0.5;
    final textColor = _colorValue != null 
        ? (isDarkColor ? Colors.white : Colors.black87)
        : theme.textTheme.bodyLarge?.color;
    final hintColor = textColor?.withOpacity(0.5);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveNote();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.palette_outlined, color: textColor),
              onPressed: _showColorPicker,
            ),
            IconButton(
              icon: Icon(Icons.share, color: textColor),
              onPressed: () async {
                final title = _titleController.text.trim();
                final content = _contentController.text.trim();
                final shareText = '$title\n\n$content';

                if (_imageBase64 != null) {
                  try {
                    final tempDir = await getTemporaryDirectory();
                    final file = await File('${tempDir.path}/shared_image.png').create();
                    await file.writeAsBytes(base64Decode(_imageBase64!));
                    await Share.shareXFiles([XFile(file.path)], text: shareText);
                  } catch (e) {
                    Share.share(shareText);
                  }
                } else if (title.isNotEmpty || content.isNotEmpty) {
                  Share.share(shareText);
                }
              },
            ),
            if (_activeNote != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: _colorValue != null ? textColor : AppColors.danger),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.delete, color: AppColors.danger),
                            title: Text(AppStrings.deleteNote),
                            subtitle: Text(AppStrings.deleteNoteConfirm),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(AppStrings.cancel),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deleteNote();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(AppStrings.delete, style: const TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_imageBase64 != null)
                  Stack(
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: MemoryImage(base64Decode(_imageBase64!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _imageBase64 = null;
                            if (_activeNote != null) {
                              _activeNote!.drawingData = null;
                              _activeNote!.imageBase64 = null;
                            }
                            _saveNote();
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      if (_activeNote?.drawingData != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SketchScreen(note: _activeNote),
                                ),
                              );
                              if (result == true) {
                                setState(() {
                                  _imageBase64 = _activeNote?.imageBase64;
                                });
                              }
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(AppStrings.isTr ? 'Çizimi Düzenle' : 'Edit Drawing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                if (_imageBase64 != null) const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  onChanged: (_) => _saveNote(),
                  decoration: InputDecoration(
                    hintText: AppStrings.titleHint,
                    hintStyle: TextStyle(color: hintColor),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  onChanged: (_) => _saveNote(),
                  style: TextStyle(fontSize: 17, height: 1.5, color: textColor),
                  decoration: InputDecoration(
                    hintText: AppStrings.contentHint,
                    hintStyle: TextStyle(color: hintColor),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
