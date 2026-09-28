import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../services/mangadex_service.dart';

class MangaProvider extends ChangeNotifier {
  final MangaDexService _service = MangaDexService();

  List<MangaModel> _popularManga = [];
  List<MangaModel> _latestManga = [];
  List<MangaModel> _searchResults = [];

  bool _isLoadingPopular = false;
  bool _isLoadingLatest = false;
  bool _isSearching = false;
  String _selectedLanguage = 'id'; // Default Bahasa Indonesia
  String _selectedComicType = 'all'; // all, manga, manhwa, manhua
  String? _errorMessage;

  List<MangaModel> get popularManga => _popularManga;
  List<MangaModel> get latestManga => _latestManga;
  List<MangaModel> get searchResults => _searchResults;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingLatest => _isLoadingLatest;
  bool get isSearching => _isSearching;
  String get selectedLanguage => _selectedLanguage;
  String get selectedComicType => _selectedComicType;
  String? get errorMessage => _errorMessage;

  /// Memuat data beranda awal
  Future<void> fetchHomeData() async {
    await Future.wait([
      fetchPopular(),
      fetchLatest(),
    ]);
  }

  /// Ganti filter tipe komik (all, manga, manhwa, manhua)
  void setComicType(String type) {
    if (_selectedComicType != type) {
      _selectedComicType = type;
      notifyListeners();
      fetchHomeData();
    }
  }

  /// Ganti filter bahasa (id = Indonesia, en = Inggris, all = Semua)
  void setLanguageFilter(String lang) {
    if (_selectedLanguage != lang) {
      _selectedLanguage = lang;
      notifyListeners();
      fetchHomeData();
    }
  }

  Future<void> fetchPopular() async {
    _isLoadingPopular = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final lang = _selectedLanguage == 'all' ? null : _selectedLanguage;
      _popularManga = await _service.getPopularManga(
        limit: 10,
        language: lang,
        comicType: _selectedComicType,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingPopular = false;
      notifyListeners();
    }
  }

  Future<void> fetchLatest() async {
    _isLoadingLatest = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final lang = _selectedLanguage == 'all' ? null : _selectedLanguage;
      _latestManga = await _service.getLatestUpdates(
        limit: 20,
        language: lang,
        comicType: _selectedComicType,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingLatest = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final lang = _selectedLanguage == 'all' ? null : _selectedLanguage;
      _searchResults = await _service.searchManga(
        query,
        limit: 30,
        language: lang,
        comicType: _selectedComicType,
      );
    } catch (e) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
}
