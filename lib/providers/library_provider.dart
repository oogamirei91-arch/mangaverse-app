import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../models/reading_history_model.dart';
import '../services/library_storage_service.dart';

class LibraryProvider extends ChangeNotifier {
  final LibraryStorageService _storage = LibraryStorageService();

  List<MangaModel> _bookmarks = [];
  List<ReadingHistoryModel> _history = [];
  bool _isLoading = false;

  List<MangaModel> get bookmarks => _bookmarks;
  List<ReadingHistoryModel> get history => _history;
  bool get isLoading => _isLoading;

  /// Memuat data bookmark dan histori saat aplikasi dibuka
  Future<void> loadLibraryData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _storage.getBookmarks(),
        _storage.getHistory(),
      ]);
      _bookmarks = results[0] as List<MangaModel>;
      _history = results[1] as List<ReadingHistoryModel>;
    } catch (_) {
      _bookmarks = [];
      _history = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cek apakah manga sedang di-bookmark
  bool isBookmarked(String mangaId) {
    return _bookmarks.any((m) => m.id == mangaId);
  }

  /// Toggle Bookmark (Simpan/Hapus)
  Future<void> toggleBookmark(MangaModel manga) async {
    await _storage.toggleBookmark(manga);
    _bookmarks = await _storage.getBookmarks();
    notifyListeners();
  }

  /// Ambil histori bacaan spesifik untuk 1 komik tertentu
  ReadingHistoryModel? getHistoryForManga(String mangaId) {
    try {
      return _history.firstWhere((h) => h.mangaId == mangaId);
    } catch (_) {
      return null;
    }
  }

  /// Simpan progres bacaan saat membuka/membaca chapter
  Future<void> updateReadingProgress({
    required String mangaId,
    required String mangaTitle,
    required String coverUrl,
    required String chapterId,
    required String chapterNumber,
    String? chapterTitle,
    required int pageNumber,
    required int totalPages,
  }) async {
    final entry = ReadingHistoryModel(
      mangaId: mangaId,
      mangaTitle: mangaTitle,
      coverUrl: coverUrl,
      chapterId: chapterId,
      chapterNumber: chapterNumber,
      chapterTitle: chapterTitle,
      pageNumber: pageNumber,
      totalPages: totalPages,
      lastReadAt: DateTime.now(),
    );

    await _storage.saveHistory(entry);
    _history = await _storage.getHistory();
    notifyListeners();
  }

  /// Hapus satu item dari riwayat
  Future<void> removeHistoryItem(String mangaId) async {
    await _storage.removeHistoryItem(mangaId);
    _history = await _storage.getHistory();
    notifyListeners();
  }

  /// Bersihkan seluruh riwayat
  Future<void> clearAllHistory() async {
    await _storage.clearAllHistory();
    _history = [];
    notifyListeners();
  }
}
