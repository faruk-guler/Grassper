import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import 'note_editor.dart';
import 'profile_settings.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40, right: 12),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
            );
          },
          backgroundColor: theme.primaryColor,
          child: Icon(Icons.add, color: theme.scaffoldBackgroundColor),
        ),
      ),
    );
  }

  Widget _buildHeader(NoteProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.notes, color: Theme.of(context).primaryColor, size: 28),
          ],
        ),
        Row(
          children: [
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          backgroundColor: theme.scaffoldBackgroundColor,
          builder: (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.archive, color: theme.iconTheme.color),
                  title: Text(AppStrings.moveToArchive, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.archiveNote(note);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.noteArchived), duration: Duration(seconds: 2)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.danger),
                  title: const Text(AppStrings.delete, style: TextStyle(color: AppColors.danger)),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.deleteNote(note);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.noteMovedToTrash, style: TextStyle(color: Colors.white)), backgroundColor: AppColors.danger, duration: Duration(seconds: 2)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasCustomColor ? Colors.black.withOpacity(0.05) : theme.dividerColor,
          ),
          boxShadow: [
            if (hasCustomColor)
              BoxShadow(
                color: Color(note.colorValue!).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? AppStrings.untitledNote : note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 16,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => provider.togglePin(note),
                  icon: Icon(
                    Icons.push_pin,
                    size: 28,
                    color: note.isImportant 
                        ? AppColors.danger 
                        : (note.isPinned 
                            ? (hasCustomColor ? textColor : theme.primaryColor) 
                            : (hasCustomColor ? secondaryTextColor : theme.iconTheme.color?.withValues(alpha: 0.3))),
                  ),
                  tooltip: AppStrings.pinNote,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.content.isEmpty ? AppStrings.noContent : note.content,
              style: TextStyle(
                color: secondaryTextColor, 
                fontSize: 14,
              ),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
