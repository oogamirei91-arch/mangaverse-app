import 'package:flutter/material.dart';
import '../models/chapter_model.dart';
import '../services/mangadex_service.dart';

class ChapterProvider extends ChangeNotifier {
  final MangaDexService _service = MangaDexService();

  List<ChapterModel> _chapters = [];
  bool _isLoading = false;
  bool _isAscending = true; // true = 1 -> end, false = end -> 1
  String _chapterLanguage = 'id';
  String? _errorMessage;

  List<ChapterModel> get chapters => _isAscending ? _chapters : _chapters.reversed.toList();
  bool get isLoading => _isLoading;
  bool get isAscending => _isAscending;
  String get chapterLanguage => _chapterLanguage;
  String? get errorMessage => _errorMessage;

  /// Memuat daftar chapter untuk komik tertentu
  Future<void> fetchChapters(String mangaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _chapters = await _service.getMangaChapters(
        mangaId,
        language: _chapterLanguage,
        limit: 100,
      );

      // Jika chapter bahasa Indonesia kosong, coba fallback ke bahasa Inggris
      if (_chapters.isEmpty && _chapterLanguage == 'id') {
        _chapters = await _service.getMangaChapters(
          mangaId,
          language: 'en',
          limit: 100,
        );
        if (_chapters.isNotEmpty) {
          _chapterLanguage = 'en';
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSortOrder() {
    _isAscending = !_isAscending;
    notifyListeners();
  }

  void changeLanguage(String mangaId, String lang) {
    _chapterLanguage = lang;
    fetchChapters(mangaId);
  }
}
