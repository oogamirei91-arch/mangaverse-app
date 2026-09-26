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
      return decoded.map((item) {
        return MangaModel(
          id: item['id'],
          title: item['title'],
          description: item['description'],
          status: item['status'] ?? 'unknown',
          year: item['year'],
          coverFileName: item['coverFileName'],
          tags: (item['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          author: item['author'],
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
      'coverFileName': b.coverFileName,
      'tags': b.tags,
      'author': b.author,
    }).toList();

    await prefs.setString(_bookmarksKey, jsonEncode(rawList));
    return !exists; // Mengembalikan status baru (true jika sekarang aktif)
  }

  /// Cek apakah komik tertentu ada di bookmark
  Future<bool> isBookmarked(String mangaId) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.id == mangaId);
  }

  /// Menyimpan progres bacaan komik ke riwayat
  Future<void> saveHistory(ReadingHistoryModel history) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getHistory();

    // Hapus entri lama untuk manga yang sama agar tidak duplikat
    currentList.removeWhere((item) => item.mangaId == history.mangaId);
    // Masukkan riwayat terbaru ke paling atas
    currentList.insert(0, history);

    // Batasi riwayat maksimal 50 komik terakhir
    final trimmedList = currentList.take(50).toList();
    final jsonList = trimmedList.map((e) => e.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// Mengambil seluruh riwayat bacaan
  Future<List<ReadingHistoryModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.map((e) => ReadingHistoryModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Hapus satu item dari riwayat
  Future<void> removeHistoryItem(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getHistory();
    currentList.removeWhere((item) => item.mangaId == mangaId);
    final jsonList = currentList.map((e) => e.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// Bersihkan seluruh riwayat baca
  Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
