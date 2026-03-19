import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'note_editor.dart';
import 'profile_settings.dart';
import 'calendar_screen.dart';
import 'sketch_screen.dart';
import 'archive_screen.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isActionInProgress = false; // Prevent multiple triggers
  
  // Selection Mode
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context);
    final theme = Theme.of(context);

    // Filter notes
    final notes = provider.notes.where((note) {
      if (note.isArchived) return false;
      
      // Date Filter
      if (provider.selectedDate != null) {
        final noteDate = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
        if (noteDate.year != provider.selectedDate!.year ||
            noteDate.month != provider.selectedDate!.month ||
            noteDate.day != provider.selectedDate!.day) {
          return false;
        }
      }

      // Search Filter
      final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Directionality(
      textDirection: provider.isLeftHanded ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isSelectionMode ? _buildSelectionHeader(provider) : _buildHeader(provider),
                const SizedBox(height: 24),
                _buildSearchBar(theme),
                const SizedBox(height: 16),
                Expanded(
                  child: notes.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty 
                                ? AppStrings.noNotesYet 
                                : AppStrings.noSearchResults,
                            style: TextStyle(color: theme.iconTheme.color),
                          ),
                        )
                      : provider.isGridView
                          ? GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.78, // Boyunu biraz daha uzatmak için 0.8 yerine 0.78
                              ),
                              itemCount: notes.length,
                              itemBuilder: (context, index) {
                                final note = notes[index];
                                return _buildNoteCard(note, provider, theme);
                              },
                            )
                          : ListView.separated(
                              itemCount: notes.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final note = notes[index];
                                return _buildNoteCard(note, provider, theme);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _isSelectionMode ? null : Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 40, end: 12),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () async {
              if (_isActionInProgress) return;
              _isActionInProgress = true;
              await _takeQuickPhoto();
              _isActionInProgress = false;
            },
            onPanUpdate: (details) async {
              // Upward swipe detection on the FAB
              if (!_isActionInProgress && details.delta.dy < -5) {
                _isActionInProgress = true;
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SketchScreen()),
                );
                _isActionInProgress = false;
              }
            },
            child: FloatingActionButton(
              onPressed: () async {
                if (_isActionInProgress) return;
                _isActionInProgress = true;
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
                );
                _isActionInProgress = false;
              },
              backgroundColor: theme.primaryColor,
              child: Icon(Icons.add, color: theme.scaffoldBackgroundColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionHeader(NoteProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedNoteIds.clear();
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedNoteIds.length} ${AppStrings.isTr ? 'Seçildi' : 'Selected'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  final notes = provider.notes.where((n) => !n.isArchived).toList();
                  if (_selectedNoteIds.length == notes.length) {
                    _selectedNoteIds.clear();
                  } else {
                    _selectedNoteIds.addAll(notes.map((n) => n.id));
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              onPressed: () {
                if (_selectedNoteIds.isEmpty) return;
                final notesToArchive = provider.notes
                    .where((n) => _selectedNoteIds.contains(n.id))
                    .toList();
                provider.archiveMultipleNotes(notesToArchive);
                setState(() {
                  _isSelectionMode = false;
                  _selectedNoteIds.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_selectedNoteIds.length > 1 ? AppStrings.notesArchived : AppStrings.noteArchived),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () {
                if (_selectedNoteIds.isEmpty) return;
                
                final notesToDelete = provider.notes
                    .where((n) => _selectedNoteIds.contains(n.id))
                    .toList();

                provider.deleteMultipleNotes(notesToDelete);
                setState(() {
                  _isSelectionMode = false;
                  _selectedNoteIds.clear();
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_selectedNoteIds.length > 1 ? AppStrings.notesMovedToTrash : AppStrings.noteMovedToTrash),
                    backgroundColor: AppColors.danger,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(NoteProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort),
              tooltip: AppStrings.sortBy,
              onSelected: (option) => provider.setSortOption(option),
              itemBuilder: (context) => [
                _buildSortItem(SortOption.alphabetical, AppStrings.sortAlphabetical, provider.sortOption),
                _buildSortItem(SortOption.alphabeticalReverse, AppStrings.sortAlphabeticalReverse, provider.sortOption),
                _buildSortItem(SortOption.newestFirst, AppStrings.sortNewerFirst, provider.sortOption),
                _buildSortItem(SortOption.oldestFirst, AppStrings.sortOlderFirst, provider.sortOption),
              ],
            ),
            if (provider.selectedDate != null)
              IconButton(
                icon: const Icon(Icons.calendar_today, color: AppColors.danger),
                onPressed: () => provider.setSelectedDate(null),
                tooltip: AppStrings.clearFilter,
              ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(provider.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded),
              onPressed: () => provider.toggleTheme(),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
                );
              },
              child: CircleAvatar(
                backgroundColor: Theme.of(context).cardColor,
                backgroundImage: provider.profilePictureBase64 != null
                    ? MemoryImage(base64Decode(provider.profilePictureBase64!))
                    : null,
                child: provider.profilePictureBase64 == null
                    ? Icon(Icons.person, color: Theme.of(context).iconTheme.color)
                    : null,
              ),
            )
          ],
        )
      ],
    );
  }

  PopupMenuItem<SortOption> _buildSortItem(SortOption option, String title, SortOption current) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 18,
            color: option == current ? Theme.of(context).primaryColor : Colors.transparent,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: AppStrings.searchHint,
          hintStyle: TextStyle(color: theme.iconTheme.color),
          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
          border: InputBorder.none,
          contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note, NoteProvider provider, ThemeData theme) {
    final hasCustomColor = note.colorValue != null;
    final cardColor = hasCustomColor ? Color(note.colorValue!) : theme.cardColor;
    final isDarkColor = hasCustomColor && Color(note.colorValue!).computeLuminance() < 0.5;
    final textColor = hasCustomColor 
        ? (isDarkColor ? Colors.white : Colors.black87)
        : theme.textTheme.bodyLarge?.color;
    final secondaryTextColor = hasCustomColor
        ? (isDarkColor ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6))
        : theme.iconTheme.color;

    final isSelected = _selectedNoteIds.contains(note.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedNoteIds.remove(note.id);
              if (_selectedNoteIds.isEmpty) _isSelectionMode = false;
            } else {
              _selectedNoteIds.add(note.id);
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
          );
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedNoteIds.add(note.id);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.primaryColor 
                : (hasCustomColor ? Colors.black.withOpacity(0.05) : theme.dividerColor),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (hasCustomColor || isSelected)
              BoxShadow(
                color: isSelected 
                    ? theme.primaryColor.withOpacity(0.3) 
                    : Color(note.colorValue!).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (note.imageBase64 != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(note.imageBase64!),
                          height: provider.isGridView ? 80 : 120, // 100 yerine 80
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (note.title.isNotEmpty)
                        Expanded(
                          child: Text(
                            note.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600, 
                              fontSize: 16,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(), // Başlık yoksa pini sağa itmek için
                      IconButton(
                        onPressed: () => provider.togglePin(note),
                        icon: Icon(
                          Icons.push_pin,
                          size: 28,
                          color: note.isImportant 
                              ? AppColors.danger 
                              : (note.isPinned 
                                  ? (hasCustomColor ? textColor : theme.primaryColor) 
                                  : (hasCustomColor ? secondaryTextColor?.withOpacity(0.2) : theme.iconTheme.color?.withValues(alpha: 0.1))),
                        ),
                        tooltip: AppStrings.pinNote,
                      ),
                    ],
                  ),
                  if (note.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      note.content,
                      style: TextStyle(
                        color: secondaryTextColor, 
                        fontSize: 14,
                      ),
                      maxLines: provider.isGridView ? 2 : 8, // 3 yerine 2
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takeQuickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      final base64String = base64Encode(bytes);
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final newNote = Note(
        id: const Uuid().v4(),
        title: '',
        content: '',
        imageBase64: base64String,
        updatedAt: now,
        createdAt: now,
      );
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(note: newNote),
          ),
        );
      }
    }
  }
}
