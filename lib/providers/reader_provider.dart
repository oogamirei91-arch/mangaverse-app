import 'package:flutter/material.dart';
import '../models/chapter_pages_model.dart';
import '../services/mangadex_service.dart';

enum ReaderMode {
  webtoon, // Vertical Continuous Scroll
  mangaRTL, // Horizontal Right to Left (Klasik Manga Jepang)
  comicLTR, // Horizontal Left to Right (Komik Barat)
}

class ReaderProvider extends ChangeNotifier {
  final MangaDexService _service = MangaDexService();

  ChapterPagesModel? _pagesData;
  List<String> _pageUrls = [];
  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 0;
  bool _showControls = true;
  // Default diaktifkan (true) agar komik / manhwa dimuat 3x-5x lebih cepat
  bool _isDataSaver = true;
  ReaderMode _readerMode = ReaderMode.webtoon;

  ChapterPagesModel? get pagesData => _pagesData;
  List<String> get pageUrls => _pageUrls;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get showControls => _showControls;
  bool get isDataSaver => _isDataSaver;
  ReaderMode get readerMode => _readerMode;

  /// Memuat halaman-halaman dari sebuah chapter
  Future<void> loadChapter(String chapterId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      _pagesData = await _service.getChapterPages(chapterId);
      if (_pagesData != null) {
        _pageUrls = _pagesData!.getPageUrls(isDataSaver: _isDataSaver);
        _totalPages = _pageUrls.length;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat halaman chapter: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  void setReaderMode(ReaderMode mode) {
    _readerMode = mode;
    notifyListeners();
  }

  /// Beralih antara mode cepat (Data Saver) dan kualitas asli (HQ)
  void toggleDataSaver() {
    _isDataSaver = !_isDataSaver;
    if (_pagesData != null) {
      _pageUrls = _pagesData!.getPageUrls(isDataSaver: _isDataSaver);
    }
    notifyListeners();
  }
}
