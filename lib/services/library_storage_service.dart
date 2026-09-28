import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_model.dart';
import '../models/reading_history_model.dart';

class LibraryStorageService {
  static const String _bookmarksKey = 'manga_user_bookmarks';
  static const String _historyKey = 'manga_user_history';

  /// Mengambil semua manga yang di-bookmark
  Future<List<MangaModel>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_bookmarksKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.map<MangaModel>((item) {
        final cover = item['directCoverUrl'] ?? item['coverUrl'] ?? item['coverFileName'];
        return MangaModel(
          id: item['id'] ?? '',
          title: item['title'] ?? '',
          description: item['description'],
          status: item['status'] ?? 'unknown',
          year: item['year'],
          directCoverUrl: cover,
          coverFileName: cover,
          tags: (item['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          author: item['author'],
          sourceId: item['sourceId'],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Menambah atau Menghapus Bookmark
  Future<bool> toggleBookmark(MangaModel manga) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    final exists = bookmarks.any((b) => b.id == manga.id);

    if (exists) {
      bookmarks.removeWhere((b) => b.id == manga.id);
    } else {
      bookmarks.insert(0, manga);
    }

    final rawList = bookmarks.map((b) => {
      'id': b.id,
      'title': b.title,
      'description': b.description,
      'status': b.status,
      'year': b.year,
      'directCoverUrl': b.coverUrl,
      'coverFileName': b.coverUrl,
      'tags': b.tags,
      'author': b.author,
      'sourceId': b.sourceId,
    }).toList();

    await prefs.setString(_bookmarksKey, jsonEncode(rawList));
    return !exists;
  }

  /// Mengambil semua histori bacaan
  Future<List<ReadingHistoryModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List decoded = jsonDecode(jsonString);
      return decoded
          .map<ReadingHistoryModel>((item) => ReadingHistoryModel.fromJson(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Memperbarui progres bacaan (Upsert ke daftar histori)
  Future<void> saveReadingProgress({
    required String mangaId,
    required String mangaTitle,
    required String coverUrl,
    required String chapterId,
    required String chapterNumber,
    required int lastPageRead,
    required int totalPages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = await getHistory();

    historyList.removeWhere((h) => h.mangaId == mangaId);

    final newHistory = ReadingHistoryModel(
      mangaId: mangaId,
      mangaTitle: mangaTitle,
      coverUrl: coverUrl,
      chapterId: chapterId,
      chapterNumber: chapterNumber,
      lastPageRead: lastPageRead,
      totalPages: totalPages,
      lastReadAt: DateTime.now(),
    );

    historyList.insert(0, newHistory);

    // Batasi histori hingga 100 komik terakhir
    if (historyList.length > 100) {
      historyList.removeRange(100, historyList.length);
    }

    final rawList = historyList.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(rawList));
  }

  /// Menghapus histori bacaan untuk komik tertentu
  Future<void> removeHistory(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = await getHistory();
    historyList.removeWhere((h) => h.mangaId == mangaId);

    final rawList = historyList.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(rawList));
  }

  /// Menghapus semua riwayat bacaan
  Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
