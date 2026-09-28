import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_model.dart';
import '../services/mangadex_service.dart';

class MangaProvider extends ChangeNotifier {
  final MangaDexService _service = MangaDexService();

  static const String _safeSearchPrefKey = 'mangaverse_safe_search_enabled';

  List<MangaModel> _popularManga = [];
  List<MangaModel> _latestManga = [];
  List<MangaModel> _searchResults = [];
  List<MangaModel> _advancedSearchResults = [];

  bool _isLoadingPopular = false;
  bool _isLoadingLatest = false;
  bool _isSearching = false;
  bool _isAdvancedSearching = false;

  String _selectedLanguage = 'id'; // Default Bahasa Indonesia
  String _selectedComicType = 'all'; // all, manga, manhwa, manhua
  bool _isSafeSearchEnabled = true; // Default Terkunci Aman (18+ nonaktif)
  String? _errorMessage;

  // State untuk Pencarian Lanjutan
  String _advComicType = 'all';
  String _advStatus = 'all'; // all, ongoing, completed
  String _advLanguage = 'id';
  List<String> _advSelectedGenreIds = [];
  List<String> _advSelectedRatings = ['safe', 'suggestive', 'erotica', 'pornographic'];

  List<MangaModel> get popularManga => _popularManga;
  List<MangaModel> get latestManga => _latestManga;
  List<MangaModel> get searchResults => _searchResults;
  List<MangaModel> get advancedSearchResults => _advancedSearchResults;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingLatest => _isLoadingLatest;
  bool get isSearching => _isSearching;
  bool get isAdvancedSearching => _isAdvancedSearching;
  String get selectedLanguage => _selectedLanguage;
  String get selectedComicType => _selectedComicType;
  bool get isSafeSearchEnabled => _isSafeSearchEnabled;
  String? get errorMessage => _errorMessage;

  String get advComicType => _advComicType;
  String get advStatus => _advStatus;
  String get advLanguage => _advLanguage;
  List<String> get advSelectedGenreIds => _advSelectedGenreIds;
  List<String> get advSelectedRatings => _advSelectedRatings;

  List<String> get currentContentRatings => _isSafeSearchEnabled
      ? ['safe', 'suggestive']
      : ['safe', 'suggestive', 'erotica', 'pornographic'];

  /// Inisialisasi preferensi Safe Search saat startup
  Future<void> initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSafeSearchEnabled = prefs.getBool(_safeSearchPrefKey) ?? true;
      notifyListeners();
    } catch (_) {}
    await fetchHomeData();
  }

  /// Mengubah status Safe Search (Filter Konten Dewasa)
  Future<void> setSafeSearch(bool enabled) async {
    _isSafeSearchEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_safeSearchPrefKey, enabled);
    } catch (_) {}
    await fetchHomeData();
  }

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
        contentRatings: currentContentRatings,
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
        contentRatings: currentContentRatings,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingLatest = false;
      notifyListeners();
    }
  }

  /// Pencarian Cepat di Beranda
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
        contentRatings: currentContentRatings,
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

  // --- LOGIKA PENCARIAN LANJUTAN (SEARCH TAB) ---

  void setAdvComicType(String type) {
    _advComicType = type;
    notifyListeners();
  }

  void setAdvStatus(String status) {
    _advStatus = status;
    notifyListeners();
  }

  void setAdvLanguage(String lang) {
    _advLanguage = lang;
    notifyListeners();
  }

  void toggleAdvGenre(String genreId) {
    if (_advSelectedGenreIds.contains(genreId)) {
      _advSelectedGenreIds.remove(genreId);
    } else {
      _advSelectedGenreIds.add(genreId);
    }
    notifyListeners();
  }

  void toggleAdvRating(String rating) {
    if (_advSelectedRatings.contains(rating)) {
      if (_advSelectedRatings.length > 1) {
        _advSelectedRatings.remove(rating);
      }
    } else {
      _advSelectedRatings.add(rating);
    }
    notifyListeners();
  }

  void resetAdvFilters() {
    _advComicType = 'all';
    _advStatus = 'all';
    _advLanguage = 'id';
    _advSelectedGenreIds.clear();
    _advSelectedRatings = ['safe', 'suggestive', 'erotica', 'pornographic'];
    _advancedSearchResults.clear();
    notifyListeners();
  }

  /// Eksekusi Pencarian Lanjutan Berdasarkan Filter Lengkap
  Future<void> executeAdvancedSearch(String query) async {
    _isAdvancedSearching = true;
    notifyListeners();

    try {
      final lang = _advLanguage == 'all' ? null : _advLanguage;
      
      // Tentukan contentRatings yang diizinkan
      List<String> ratingsToUse;
      if (_isSafeSearchEnabled) {
        ratingsToUse = ['safe', 'suggestive'];
      } else {
        ratingsToUse = _advSelectedRatings.isNotEmpty
            ? _advSelectedRatings
            : ['safe', 'suggestive', 'erotica', 'pornographic'];
      }

      _advancedSearchResults = await _service.searchManga(
        query,
        limit: 40,
        language: lang,
        comicType: _advComicType,
        status: _advStatus,
        includedTags: _advSelectedGenreIds.isNotEmpty ? _advSelectedGenreIds : null,
        contentRatings: ratingsToUse,
      );
    } catch (e) {
      _advancedSearchResults = [];
    } finally {
      _isAdvancedSearching = false;
      notifyListeners();
    }
  }
}
