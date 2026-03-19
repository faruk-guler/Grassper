import 'enums.dart';

/// Uygulama genelinde kullanılan tüm sabit metinler.
/// Çoklu dil desteği (TR/EN) sağlar.
class AppStrings {
  static AppLanguage _language = AppLanguage.tr;

  static void setLanguage(AppLanguage lang) {
    _language = lang;
  }

  static bool get isTr => _language == AppLanguage.tr;

  // Genel
  static String get appName => 'Grassper';
  static String get appVersion => 'v1.2.4';
  static String get appDescription => isTr 
      ? 'Minimalist, güvenli, açık kaynak ve hız odaklı çapraz platform not alma uygulaması.' 
      : 'Minimalist, secure, open source and speed-oriented cross-platform note-taking app.';
  static String get madeBy => '@sentifoss/faruk-guler';

  // Home
  static String get noNotesYet => isTr 
      ? 'Henüz bir not yok. Yeni bir tane ekleyerek başla!' 
      : 'No notes yet. Start by adding a new one!';
  static String get noSearchResults => isTr 
      ? 'Aramanızla eşleşen not bulunamadı.' 
      : 'No notes found matching your search.';
  static String get searchHint => isTr ? 'Notlarda ara...\u200E' : 'Search notes...\u200E';
  static String get untitledNote => isTr ? 'Başlıksız Not' : 'Untitled Note';
  static String get noContent => isTr ? 'İçerik yok' : 'No content';
  static String get clearFilter => isTr ? 'Filtreyi Temizle' : 'Clear Filter';

  // Not İşlemleri
  static String get moveToArchive => isTr ? 'Arşive Taşı' : 'Move to Archive';
  static String get delete => isTr ? 'Sil' : 'Delete';
  static String get noteArchived => isTr ? 'Not arşivlendi' : 'Note archived';
  static String get notesArchived => isTr ? 'Notlar arşivlendi' : 'Notes archived';
  static String get noteMovedToTrash => isTr ? 'Not çöp kutusuna taşındı' : 'Note moved to trash';
  static String get notesMovedToTrash => isTr ? 'Notlar çöp kutusuna taşındı' : 'Notes moved to trash';
  static String get pinNote => isTr ? 'Sabitle' : 'Pin';

  // Not Editörü
  static String get titleHint => isTr ? 'Başlık' : 'Title';
  static String get contentHint => isTr ? 'Bir şeyler yaz...\u200E' : 'Write something...\u200E';
  static String get save => isTr ? 'Kaydet' : 'Save';
  static String get noteEmpty => isTr ? 'Not boş bırakılamaz.' : 'Note cannot be empty.';
  static String get deleteNote => isTr ? 'Notu Sil' : 'Delete Note';
  static String get deleteNoteConfirm => isTr 
      ? 'Bu not çöp kutusuna taşınacak.' 
      : 'This note will be moved to trash.';
  static String get cancel => isTr ? 'İptal' : 'Cancel';

  // Takvim
  static String get calendarView => isTr ? 'Takvim Görünümü' : 'Calendar View';

  // Arşiv
  static String get archivedNotes => isTr ? 'Arşivlenmiş Notlar' : 'Archived Notes';
  static String get noArchivedNotes => isTr ? 'Arşivlenmiş notunuz yok.' : 'You have no archived notes.';
  static String get unarchive => isTr ? 'Arşivden Çıkar' : 'Unarchive';

  // Çöp Kutusu
  static String get trash => isTr ? 'Çöp Kutusu' : 'Trash';
  static String get trashEmpty => isTr ? 'Çöp kutusu boş.' : 'Trash is empty.';
  static String get emptyTrash => isTr ? 'Boşalt' : 'Empty Trash';
  static String get emptyTrashTitle => isTr ? 'Çöp Kutusunu Boşalt?' : 'Empty Trash?';
  static String get emptyTrashConfirm => isTr 
      ? 'Tüm notlar kalıcı olarak silinecek. Bu işlem geri alınamaz.' 
      : 'All notes will be permanently deleted. This action cannot be undone.';
  static String get restore => isTr ? 'Geri Yükle' : 'Restore';
  static String get permanentDelete => isTr ? 'Kalıcı Olarak Sil' : 'Delete Permanently';

  // Profil & Ayarlar
  static String get profileSettings => isTr ? 'Profil ve Ayarlar' : 'Profile & Settings';
  static String get backupEmail => isTr ? 'Yedekleme E-Posta Adresi' : 'Backup Email Address';
  static String get emailHint => isTr ? 'ornek@mail.com' : 'example@mail.com';
  static String get weekStartDay => isTr ? 'Hafta Başlangıç Günü' : 'Week Start Day';
  static String get monday => isTr ? 'Pazartesi' : 'Monday';
  static String get sunday => isTr ? 'Pazar' : 'Sunday';
  static String get dataBackup => isTr ? 'Veri Yedekleme' : 'Data Backup';
  static String get importNotes => isTr ? 'İçe Aktar' : 'Import';
  static String get exportNotes => isTr ? 'Dışa Aktar' : 'Export';
  static String get emailBackup => isTr ? 'Mail Yedekleme' : 'Email Backup';
  static String get syncNow => isTr ? 'Şimdi Senkronize Et' : 'Sync Now';
  static String get enterEmailFirst => isTr 
      ? 'Lütfen önce bir yedekleme e-postası girin.' 
      : 'Please enter a backup email first.';
  static String get syncStarting => isTr ? 'Senkronizasyon başlatılıyor...' : 'Syncing starting...';
  static String get removePhoto => isTr ? 'Resmi Kaldır' : 'Remove Photo';
  static String get dailyAutoBackup => isTr ? 'Günlük Otomatik Yedekleme' : 'Daily Auto Backup';
  static String get lastAutoBackup => isTr ? 'Son Otomatik Yedekleme: ' : 'Last Auto Backup: ';
  static String get never => isTr ? 'Hiçbir zaman' : 'Never';

  // Sıralama
  static String get sortBy => isTr ? 'Sırala' : 'Sort By';
  static String get sortAlphabetical => isTr ? 'A-Z (Başlık)' : 'A-Z (Title)';
  static String get sortAlphabeticalReverse => isTr ? 'Z-A (Başlık)' : 'Z-A (Title)';
  static String get sortNewerFirst => isTr ? 'Yeniden Eskiye' : 'Newest First';
  static String get sortOlderFirst => isTr ? 'Eskiden Yeniye' : 'Oldest First';

  // İçe/Dışa Aktarma sonuçları
  static String importSuccess(int count) => isTr 
      ? '$count not başarıyla içe aktarıldı.' 
      : 'Successfully imported $count notes.';
  static String get importFailed => isTr 
      ? 'İçe aktarma başarısız oldu veya iptal edildi.' 
      : 'Import failed or was cancelled.';

  // About
  static String get madeWithLove => isTr ? 'ile yapıldı.' : 'with love.';
  static String get madeByPrefix => isTr 
      ? 'Bu uygulama @sentifoss/faruk-guler tarafından ' 
      : 'This app was made by @sentifoss/faruk-guler ';

  // Not sayısı
  static String noteCount(int count) => isTr ? '$count not' : '$count notes';

  // Dil Seçimi
  static String get language => isTr ? 'Dil' : 'Language';
  static String get turkish => 'Türkçe';
  static String get english => 'English';
  static String get unpinNote => isTr ? 'Sabitlemeyi Kaldır' : 'Unpin';
  static String get importantPin => isTr ? 'Önemli Olarak İşaretle' : 'Mark as Important';
}
