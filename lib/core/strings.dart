/// Uygulama genelinde kullanılan tüm sabit metinler.
/// Lokalizasyon eklenecekse bu dosya kolayca dönüştürülebilir.
class AppStrings {
  // Genel
  static const appName = 'Grassper';
  static const appVersion = 'v1.2.4';
  static const appDescription = 'Minimalist, güvenli, açık kaynak ve hız odaklı çapraz platform not alma uygulaması.';
  static const madeBy = '@sentifoss/faruk-guler';

  // Home
  static const noNotesYet = 'Henüz bir not yok. Yeni bir tane ekleyerek başla!';
  static const noSearchResults = 'Aramanızla eşleşen not bulunamadı.';
  static const searchHint = 'Notlarda ara...';
  static const untitledNote = 'Başlıksız Not';
  static const noContent = 'İçerik yok';
  static const clearFilter = 'Filtreyi Temizle';

  // Not İşlemleri
  static const moveToArchive = 'Arşive Taşı';
  static const delete = 'Sil';
  static const noteArchived = 'Not arşivlendi';
  static const noteMovedToTrash = 'Not çöp kutusuna taşındı';
  static const pinNote = 'Sabitle';

  // Not Editörü
  static const titleHint = 'Başlık';
  static const contentHint = 'Bir şeyler yaz...';
  static const save = 'Kaydet';
  static const noteEmpty = 'Not boş bırakılamaz.';
  static const deleteNote = 'Notu Sil';
  static const deleteNoteConfirm = 'Bu not çöp kutusuna taşınacak.';
  static const cancel = 'İptal';

  // Takvim
  static const calendarView = 'Takvim Görünümü';

  // Arşiv
  static const archivedNotes = 'Arşivlenmiş Notlar';
  static const noArchivedNotes = 'Arşivlenmiş notunuz yok.';
  static const unarchive = 'Arşivden Çıkar';

  // Çöp Kutusu
  static const trash = 'Çöp Kutusu';
  static const trashEmpty = 'Çöp kutusu boş.';
  static const emptyTrash = 'Boşalt';
  static const emptyTrashTitle = 'Çöp Kutusunu Boşalt?';
  static const emptyTrashConfirm = 'Tüm notlar kalıcı olarak silinecek. Bu işlem geri alınamaz.';
  static const restore = 'Geri Yükle';
  static const permanentDelete = 'Kalıcı Olarak Sil';

  // Profil & Ayarlar
  static const profileSettings = 'Profil ve Ayarlar';
  static const backupEmail = 'Yedekleme E-Posta Adresi';
  static const emailHint = 'ornek@mail.com';
  static const weekStartDay = 'Hafta Başlangıç Günü';
  static const monday = 'Pazartesi';
  static const sunday = 'Pazar';
  static const dataBackup = 'Veri Yedekleme';
  static const importNotes = 'İçe Aktar';
  static const exportNotes = 'Dışa Aktar';
  static const emailBackup = 'Mail Yedekleme';
  static const syncNow = 'Şimdi Senkronize Et';
  static const enterEmailFirst = 'Lütfen önce bir yedekleme e-postası girin.';
  static const syncStarting = 'Senkronizasyon başlatılıyor...';
  static const removePhoto = 'Resmi Kaldır';
  static const dailyAutoBackup = 'Günlük Otomatik Yedekleme';
  static const lastAutoBackup = 'Son Otomatik Yedekleme: ';
  static const never = 'Hiçbir zaman';

  // Sıralama
  static const sortBy = 'Sırala';
  static const sortAlphabetical = 'A-Z (Başlık)';
  static const sortAlphabeticalReverse = 'Z-A (Başlık)';
  static const sortNewerFirst = 'Yeniden Eskiye';
  static const sortOlderFirst = 'Eskiden Yeniye';

  // İçe/Dışa Aktarma sonuçları
  static String importSuccess(int count) => '$count not başarıyla içe aktarıldı.';
  static const importFailed = 'İçe aktarma başarısız oldu veya iptal edildi.';

  // About
  static const madeWithLove = 'ile yapıldı.';
  static const madeByPrefix = '@sentifoss/faruk-guler tarafından ';

  // Not sayısı
  static String noteCount(int count) => '$count not';
}
