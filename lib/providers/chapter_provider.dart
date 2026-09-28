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
  List<String>? _contentRatings;

  List<ChapterModel> get chapters => _isAscending ? _chapters : _chapters.reversed.toList();
  bool get isLoading => _isLoading;
  bool get isAscending => _isAscending;
  String get chapterLanguage => _chapterLanguage;
  String? get errorMessage => _errorMessage;

  /// Memuat daftar chapter untuk komik tertentu disesuaikan dengan bahasa aktif
  Future<void> fetchChapters(
    String mangaId, {
    String? defaultLanguage,
    List<String>? contentRatings,
    bool autoFallback = true,
  }) async {
    if (defaultLanguage != null && defaultLanguage.isNotEmpty) {
      _chapterLanguage = defaultLanguage;
    }
    if (contentRatings != null) {
      _contentRatings = contentRatings;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _chapters = await _service.getMangaChapters(
        mangaId,
        language: _chapterLanguage,
        limit: 100,
        contentRatings: _contentRatings,
      );

      // Jika chapter bahasa Indonesia kosong dan user memilih ID serta autoFallback aktif
      if (_chapters.isEmpty && _chapterLanguage == 'id' && autoFallback) {
        final enChapters = await _service.getMangaChapters(
          mangaId,
          language: 'en',
          limit: 100,
          contentRatings: _contentRatings,
        );
        if (enChapters.isNotEmpty) {
          _chapters = enChapters;
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

  void changeLanguage(String mangaId, String lang, {List<String>? contentRatings}) {
    _chapterLanguage = lang;
    if (contentRatings != null) {
      _contentRatings = contentRatings;
    }
    fetchChapters(
      mangaId,
      defaultLanguage: lang,
      contentRatings: _contentRatings,
      autoFallback: false,
    );
  }
}
