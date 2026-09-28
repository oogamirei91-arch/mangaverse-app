import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_model.dart';
import '../models/suwayomi_source_model.dart';
import '../services/mangadex_service.dart';
import '../services/suwayomi_service.dart';

class MangaProvider extends ChangeNotifier {
  final MangaDexService _service = MangaDexService();
  final SuwayomiService _suwayomiService = SuwayomiService();

  static const String _safeSearchPrefKey = 'mangaverse_safe_search_enabled';
  static const String _activeServerPrefKey = 'kuro_active_server';
  static const String _suwayomiUrlPrefKey = 'kuro_suwayomi_url';
  static const String _suwayomiSourceIdPrefKey = 'kuro_suwayomi_source_id';
  static const String _suwayomiSourceNamePrefKey = 'kuro_suwayomi_source_name';

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

  // --- MULTI-SERVER & SUWAYOMI CONFIGURATION ---
  String _activeServer = 'mangadex'; // 'mangadex' | 'suwayomi'
  String _suwayomiUrl = 'http://10.0.2.2:4567';
  String? _suwayomiSourceId;
  String? _suwayomiSourceName;
  List<SuwayomiSourceModel> _suwayomiSources = [];
  bool _isTestingSuwayomi = false;
  String? _suwayomiConnectionStatus;
  bool _isSuwayomiConnected = false;

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

  // Getters Multi-Server & Suwayomi
  String get activeServer => _activeServer;
  bool get isSuwayomiActive => _activeServer == 'suwayomi';
  String get suwayomiUrl => _suwayomiUrl;
  String? get suwayomiSourceId => _suwayomiSourceId;
  String? get suwayomiSourceName => _suwayomiSourceName;
  List<SuwayomiSourceModel> get suwayomiSources => _suwayomiSources;
  bool get isTestingSuwayomi => _isTestingSuwayomi;
  String? get suwayomiConnectionStatus => _suwayomiConnectionStatus;
  bool get isSuwayomiConnected => _isSuwayomiConnected;

  String get advComicType => _advComicType;
  String get advStatus => _advStatus;
  String get advLanguage => _advLanguage;
  List<String> get advSelectedGenreIds => _advSelectedGenreIds;
  List<String> get advSelectedRatings => _advSelectedRatings;

  List<String> get currentContentRatings => _isSafeSearchEnabled
      ? ['safe', 'suggestive']
      : ['safe', 'suggestive', 'erotica', 'pornographic'];

  /// Inisialisasi preferensi saat startup
  Future<void> initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSafeSearchEnabled = prefs.getBool(_safeSearchPrefKey) ?? true;
      _activeServer = prefs.getString(_activeServerPrefKey) ?? 'mangadex';
      _suwayomiUrl = prefs.getString(_suwayomiUrlPrefKey) ?? 'http://10.0.2.2:4567';
      _suwayomiSourceId = prefs.getString(_suwayomiSourceIdPrefKey);
      _suwayomiSourceName = prefs.getString(_suwayomiSourceNamePrefKey);
      notifyListeners();

      if (_activeServer == 'suwayomi') {
        // Cek koneksi & muat sumber Suwayomi di latar belakang
        testSuwayomiConnection();
      }
    } catch (_) {}
    await fetchHomeData();
  }

  /// Mengubah Server Aktif ('mangadex' atau 'suwayomi')
  Future<void> setActiveServer(String server) async {
    if (_activeServer != server) {
      _activeServer = server;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_activeServerPrefKey, server);
      } catch (_) {}
      await fetchHomeData();
    }
  }

  /// Mengatur Alamat URL Suwayomi-Server
  Future<void> setSuwayomiUrl(String url) async {
    _suwayomiUrl = url.trim();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_suwayomiUrlPrefKey, _suwayomiUrl);
    } catch (_) {}
  }

  /// Memilih Sumber/Ekstensi aktif di Suwayomi (e.g. MangaFox, KomikIndo)
  Future<void> setSuwayomiSource(String sourceId, String sourceName) async {
    _suwayomiSourceId = sourceId;
    _suwayomiSourceName = sourceName;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_suwayomiSourceIdPrefKey, sourceId);
      await prefs.setString(_suwayomiSourceNamePrefKey, sourceName);
    } catch (_) {}
    if (_activeServer == 'suwayomi') {
      await fetchHomeData();
    }
  }

  /// Menguji koneksi ke Suwayomi-Server dan memuat daftar ekstensi
  Future<void> testSuwayomiConnection({String? customUrl}) async {
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      _suwayomiUrl = customUrl.trim();
    }
    _isTestingSuwayomi = true;
    _suwayomiConnectionStatus = null;
    notifyListeners();

    final result = await _suwayomiService.testConnection(_suwayomiUrl);
    _isTestingSuwayomi = false;
    _isSuwayomiConnected = result.success;
    _suwayomiConnectionStatus = result.message;

    if (result.success) {
      _suwayomiSources = result.sources;
      // Jika belum ada sumber yang dipilih, default ke sumber pertama
      if ((_suwayomiSourceId == null || _suwayomiSourceId!.isEmpty) && result.sources.isNotEmpty) {
        _suwayomiSourceId = result.sources.first.id;
        _suwayomiSourceName = result.sources.first.name;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_suwayomiSourceIdPrefKey, _suwayomiSourceId!);
          await prefs.setString(_suwayomiSourceNamePrefKey, _suwayomiSourceName!);
        } catch (_) {}
      }
    }
    notifyListeners();
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
      if (_activeServer == 'suwayomi') {
        if (_suwayomiSourceId != null && _suwayomiSourceId!.isNotEmpty) {
          _popularManga = await _suwayomiService.getPopularManga(
            _suwayomiUrl,
            _suwayomiSourceId!,
            page: 1,
          );
        } else {
          _popularManga = [];
        }
      } else {
        final lang = _selectedLanguage == 'all' ? null : _selectedLanguage;
        _popularManga = await _service.getPopularManga(
          limit: 10,
          language: lang,
          comicType: _selectedComicType,
          contentRatings: currentContentRatings,
        );
      }
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
      if (_activeServer == 'suwayomi') {
        if (_suwayomiSourceId != null && _suwayomiSourceId!.isNotEmpty) {
          _latestManga = await _suwayomiService.getLatestUpdates(
            _suwayomiUrl,
            _suwayomiSourceId!,
            page: 1,
          );
        } else {
          _latestManga = [];
        }
      } else {
        final lang = _selectedLanguage == 'all' ? null : _selectedLanguage;
        _latestManga = await _service.getLatestUpdates(
          limit: 20,
          language: lang,
          comicType: _selectedComicType,
          contentRatings: currentContentRatings,
        );
      }
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
      if (_activeServer == 'suwayomi') {
        if (_suwayomiSourceId != null && _suwayomiSourceId!.isNotEmpty) {
          _searchResults = await _suwayomiService.searchManga(
            _suwayomiUrl,
            _suwayomiSourceId!,
            query,
            page: 1,
          );
        } else {
          _searchResults = [];
        }
      } else {
        final lang = _selectedLanguage == 'all' ? null : _selectedLanguage;
        _searchResults = await _service.searchManga(
          query,
          limit: 30,
          language: lang,
          comicType: _selectedComicType,
          contentRatings: currentContentRatings,
        );
      }
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
      if (_activeServer == 'suwayomi') {
        if (_suwayomiSourceId != null && _suwayomiSourceId!.isNotEmpty) {
          _advancedSearchResults = await _suwayomiService.searchManga(
            _suwayomiUrl,
            _suwayomiSourceId!,
            query,
            page: 1,
          );
        } else {
          _advancedSearchResults = [];
        }
      } else {
        final lang = _advLanguage == 'all' ? null : _advLanguage;
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
      }
    } catch (e) {
      _advancedSearchResults = [];
    } finally {
      _isAdvancedSearching = false;
      notifyListeners();
    }
  }
}
