import 'package:flutter/material.dart';
import '../models/chapter_model.dart';
import '../services/suwayomi_service.dart';

class ChapterProvider extends ChangeNotifier {
  final SuwayomiService _suwayomiService = SuwayomiService();

  List<ChapterModel> _chapters = [];
  bool _isLoading = false;
  bool _isAscending = true; // true = 1 -> end, false = end -> 1
  String _chapterLanguage = 'all';
  String? _errorMessage;

  List<ChapterModel> get chapters => _isAscending ? _chapters : _chapters.reversed.toList();
  bool get isLoading => _isLoading;
  bool get isAscending => _isAscending;
  String get chapterLanguage => _chapterLanguage;
  String? get errorMessage => _errorMessage;

  /// Memuat daftar chapter untuk komik tertentu dari Suwayomi
  Future<void> fetchChapters(
    String mangaId, {
    String? defaultLanguage,
    List<String>? contentRatings,
    bool autoFallback = true,
    String? serverType,
    String? suwayomiUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = suwayomiUrl ?? 'https://attending-alien-voip-katrina.trycloudflare.com';
      _chapters = await _suwayomiService.getMangaChapters(url, mangaId);
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

  void changeLanguage(
    String mangaId,
    String lang, {
    List<String>? contentRatings,
    String? serverType,
    String? suwayomiUrl,
  }) {
    _chapterLanguage = lang;
    fetchChapters(
      mangaId,
      defaultLanguage: lang,
      suwayomiUrl: suwayomiUrl,
    );
  }
}
