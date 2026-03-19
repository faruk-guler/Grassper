import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../core/enums.dart';
import '../models/note_model.dart';
import '../utils/web_download_helper.dart';

enum SortOption { alphabetical, alphabeticalReverse, newestFirst, oldestFirst }

class NoteProvider with ChangeNotifier {
  late Box<Note> _notesBox;
  late Box<Note> _trashBox;
  late Box _settingsBox;

  List<Note> _notes = [];
  List<Note> _trash = [];
  bool _isDarkMode = false;
  bool _isLoading = true;
  DateTime? _selectedDate;
  String? _profilePictureBase64;
  String? _backupEmail;
  StartingDayOfWeek _startingDayOfWeek = StartingDayOfWeek.monday;
  SortOption _sortOption = SortOption.newestFirst;
  bool _autoBackupEnabled = false;
  DateTime? _lastAutoBackupTime;
  bool _isLeftHanded = false;
  bool _isGridView = false;
  AppLanguage _language = AppLanguage.tr;

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  DateTime? get selectedDate => _selectedDate;
  String? get profilePictureBase64 => _profilePictureBase64;
  String? get backupEmail => _backupEmail;
  StartingDayOfWeek get startingDayOfWeek => _startingDayOfWeek;
  SortOption get sortOption => _sortOption;
  bool get autoBackupEnabled => _autoBackupEnabled;
  bool get isLeftHanded => _isLeftHanded;
  bool get isGridView => _isGridView;
  AppLanguage get language => _language;
  DateTime? get lastAutoBackupTime => _lastAutoBackupTime;
  List<Note> get notes => _notes;
  List<Note> get trash => _trash;

  NoteProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _notesBox = Hive.box<Note>('notesBox');
      _trashBox = Hive.box<Note>('trashBox');
      _settingsBox = Hive.box('settingsBox');

      _isDarkMode = _settingsBox.get('isDarkMode', defaultValue: false);
      _profilePictureBase64 = _settingsBox.get('profilePictureBase64');
      _backupEmail = _settingsBox.get('backupEmail');

      final startDayIndex = _settingsBox.get('startingDayOfWeek', defaultValue: StartingDayOfWeek.monday.index);
      _startingDayOfWeek = StartingDayOfWeek.values[startDayIndex];

      final sortIndex = _settingsBox.get('sortOption', defaultValue: SortOption.newestFirst.index);
      _sortOption = SortOption.values[sortIndex];

      _autoBackupEnabled = _settingsBox.get('autoBackupEnabled', defaultValue: false);
      final lastBackupMs = _settingsBox.get('lastAutoBackupTime') as int?;
      if (lastBackupMs != null) {
        _lastAutoBackupTime = DateTime.fromMillisecondsSinceEpoch(lastBackupMs);
      }
      
      _isLeftHanded = _settingsBox.get('isLeftHanded', defaultValue: false);
      _isGridView = _settingsBox.get('isGridView', defaultValue: false);
      _language = AppLanguage.values[_settingsBox.get('language', defaultValue: AppLanguage.tr.index)];
      AppStrings.setLanguage(_language);

      _loadNotes();
    } catch (e) {
      debugPrint('Hive initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadNotes() {
    // BUG FIX: Filter out archived notes from the main list
    _notes = _notesBox.values.toList();
    _trash = _trashBox.values.toList();

    _notes.sort((a, b) {
      // 1. Important (Red Pin) always first
      if (a.isImportant && !b.isImportant) return -1;
      if (!a.isImportant && b.isImportant) return 1;

      // 2. Normal Pinned next
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // 3. Then apply selected sort option
      switch (_sortOption) {
        case SortOption.alphabetical:
          if (a.title.isEmpty && b.title.isNotEmpty) return 1;
          if (a.title.isNotEmpty && b.title.isEmpty) return -1;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortOption.alphabeticalReverse:
          if (a.title.isEmpty && b.title.isNotEmpty) return 1;
          if (a.title.isNotEmpty && b.title.isEmpty) return -1;
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case SortOption.newestFirst:
          // Newest Edit first
          return b.updatedAt.compareTo(a.updatedAt);
        case SortOption.oldestFirst:
          // Least recently edited first (consistent with newestFirst)
          return a.updatedAt.compareTo(b.updatedAt);
      }
    });

    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _settingsBox.put('sortOption', option.index);
    _loadNotes();
  }

  void setAutoBackup(bool enabled) {
    _autoBackupEnabled = enabled;
    _settingsBox.put('autoBackupEnabled', enabled);
    notifyListeners();
  }

  /// Uygulama her açılışında çağrılır. 24 saat geçmişse otomatik yedek alır.
  Future<void> autoBackupIfNeeded() async {
    if (!_autoBackupEnabled || kIsWeb) return;
    final now = DateTime.now();
    if (_lastAutoBackupTime != null &&
        now.difference(_lastAutoBackupTime!).inHours < 24) return;
    try {
      final exportData = {
        'notes': _notes.map((n) => n.toJson()).toList(),
        'trash': _trash.map((n) => n.toJson()).toList(),
      };
      final jsonString = jsonEncode(exportData);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/grassper_auto_backup.json');
      await file.writeAsString(jsonString);
      _lastAutoBackupTime = now;
      _settingsBox.put('lastAutoBackupTime', now.millisecondsSinceEpoch);
      notifyListeners();
      debugPrint('Auto backup completed: ${file.path}');
    } catch (e) {
      debugPrint('Auto backup error: $e');
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _settingsBox.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  void toggleLeftHandedMode() {
    _isLeftHanded = !_isLeftHanded;
    _settingsBox.put('isLeftHanded', _isLeftHanded);
    notifyListeners();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    _settingsBox.put('isGridView', _isGridView);
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    _settingsBox.put('language', lang.index);
    AppStrings.setLanguage(lang);
    notifyListeners();
  }

  void setProfilePicture(String base64String) {
    _profilePictureBase64 = base64String;
    _settingsBox.put('profilePictureBase64', base64String);
    notifyListeners();
  }

  void removeProfilePicture() {
    _profilePictureBase64 = null;
    _settingsBox.delete('profilePictureBase64');
    notifyListeners();
  }

  void setBackupEmail(String email) {
    _backupEmail = email;
    _settingsBox.put('backupEmail', email);
    notifyListeners();
  }

  void setStartingDayOfWeek(StartingDayOfWeek day) {
    _startingDayOfWeek = day;
    _settingsBox.put('startingDayOfWeek', day.index);
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note);
    _loadNotes();
  }

  Future<void> togglePin(Note note) async {
    if (!note.isPinned) {
      // Unpinned -> Pinned (Normal)
      note.isPinned = true;
      note.isImportant = false;
    } else if (!note.isImportant) {
      // Pinned (Normal) -> Pinned (Important)
      note.isImportant = true;
    } else {
      // Pinned (Important) -> Unpinned
      note.isPinned = false;
      note.isImportant = false;
    }
    
    note.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await note.save();
    _loadNotes();
  }

  Future<void> deleteNote(Note note, {bool toTrash = true}) async {
    if (toTrash) {
      final noteCopy = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        isPinned: false, // Reset pins in trash
        isArchived: note.isArchived,
        isImportant: false, // Reset pins in trash
        colorValue: note.colorValue,
        imageBase64: note.imageBase64,
        drawingData: note.drawingData,
        updatedAt: note.updatedAt,
        createdAt: note.createdAt,
      );
      await _trashBox.put(noteCopy.id, noteCopy);
    }
    await _notesBox.delete(note.id);
    _loadNotes();
  }

  Future<void> deleteMultipleNotes(List<Note> notesToTags, {bool toTrash = true}) async {
    for (var note in notesToTags) {
      if (toTrash) {
        final noteCopy = Note(
          id: note.id,
          title: note.title,
          content: note.content,
          isPinned: false,
          isArchived: note.isArchived,
          isImportant: false,
          colorValue: note.colorValue,
          imageBase64: note.imageBase64,
          drawingData: note.drawingData,
          updatedAt: note.updatedAt,
          createdAt: note.createdAt,
        );
        await _trashBox.put(noteCopy.id, noteCopy);
      }
      await _notesBox.delete(note.id);
    }
    _loadNotes();
  }

  Future<void> archiveNote(Note note) async {
    note.isArchived = true;
    note.isPinned = false;
    note.isImportant = false; // BUG FIX: Red pin states also cleared
    await note.save();
    _loadNotes();
  }

  Future<void> archiveMultipleNotes(List<Note> notesToArchive) async {
    for (var note in notesToArchive) {
      note.isArchived = true;
      note.isPinned = false;
      note.isImportant = false;
      await note.save();
    }
    _loadNotes();
  }

  Future<void> unarchiveNote(Note note) async {
    note.isArchived = false;
    await note.save();
    _loadNotes();
  }

  Future<void> restoreFromTrash(Note note) async {
    final noteCopy = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      isImportant: note.isImportant,
      colorValue: note.colorValue,
      updatedAt: note.updatedAt,
      createdAt: note.createdAt,
    );
    await _notesBox.put(noteCopy.id, noteCopy);
    await _trashBox.delete(note.id);
    _loadNotes();
  }

  Future<void> permanentDelete(Note note) async {
    await _trashBox.delete(note.id);
    _loadNotes();
  }

  Future<void> emptyTrash() async {
    await _trashBox.clear();
    _loadNotes();
  }

  Future<void> exportNotes() async {
    try {
      final exportData = {
        'notes': _notes.map((n) => n.toJson()).toList(),
        'trash': _trash.map((n) => n.toJson()).toList(),
      };
      final jsonString = jsonEncode(exportData);
      const fileName = 'grassper_notes_backup.json';

      debugPrint('Export initiated. kIsWeb: $kIsWeb');
      if (kIsWeb) {
        debugPrint('Web Export: Triggering download for $fileName');
        WebDownloadHelper.download(jsonString, fileName);
        return;
      }

      debugPrint('Mobile Export: Creating temp file...');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Grassper Not Yedeklemesi',
        text: 'Grassper notlarınız yedek olarak ekteki dosyada bulunmaktadır.',
      );
    } catch (e) {
      debugPrint('Export Error: $e');
    }
  }

  Future<void> syncToEmail() async {
    if (_backupEmail == null || _backupEmail!.isEmpty) {
      debugPrint('Sync Error: No backup email set.');
      return;
    }

    try {
      final notesJson = _notes.map((n) => n.toJson()).toList();
      final jsonString = jsonEncode(notesJson);
      const fileName = 'grassper_notes_backup.json';

      if (kIsWeb) {
        // Web'de flutter_email_sender çalışmaz, indirme+uyarı yapıyoruz
        WebDownloadHelper.download(jsonString, fileName);
        debugPrint('Web Sync: Downloaded, manually email to $_backupEmail');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      final Email email = Email(
        body: 'Grassper notlarınızın güncel yedek dosyası ektedir.',
        subject: 'Grassper Senkronizasyon Yedeklemesi',
        recipients: [_backupEmail!],
        attachmentPaths: [file.path],
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
      debugPrint('Sync initiated via email.');
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  /// İçe aktar. Başarılı olursa içe aktarılan not sayısını döner, hata/iptal durumunda -1.
  Future<int> importNotes() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: kIsWeb,
      );

      if (result != null &&
          (result.files.single.path != null || (kIsWeb && result.files.single.bytes != null))) {
        String content;
        if (kIsWeb) {
          content = utf8.decode(result.files.single.bytes!);
        } else {
          final file = File(result.files.single.path!);
          content = await file.readAsString();
        }

        final decoded = jsonDecode(content);
        int importedCount = 0;

        // Yeni format: {notes: [...], trash: [...]}
        if (decoded is Map<String, dynamic>) {
          final notesList = decoded['notes'] as List<dynamic>? ?? [];
          for (var item in notesList) {
            final note = Note.fromJson(item as Map<String, dynamic>);
            await _notesBox.put(note.id, note);
            importedCount++;
          }
          final trashList = decoded['trash'] as List<dynamic>? ?? [];
          for (var item in trashList) {
            final note = Note.fromJson(item as Map<String, dynamic>);
            await _trashBox.put(note.id, note);
            importedCount++;
          }
        } else if (decoded is List<dynamic>) {
          // Eski format: düz liste
          for (var item in decoded) {
            final note = Note.fromJson(item as Map<String, dynamic>);
            await _notesBox.put(note.id, note);
            importedCount++;
          }
        }

        _loadNotes();
        debugPrint('$importedCount not başarıyla içe aktarıldı.');
        return importedCount;
      }
      return -1;
    } catch (e) {
      debugPrint('Import Error: $e');
      return -1;
    }
  }
}
