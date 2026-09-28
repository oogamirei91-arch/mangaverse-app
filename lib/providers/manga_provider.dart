import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_model.dart';
import '../models/suwayomi_source_model.dart';
import '../services/suwayomi_service.dart';

class MangaProvider extends ChangeNotifier {
  final SuwayomiService _suwayomiService = SuwayomiService();

  static const String _safeSearchPrefKey = 'mangaverse_safe_search_enabled';
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

  String _selectedLanguage = 'id';
  String _selectedComicType = 'all';
  bool _isSafeSearchEnabled = true;
  String? _errorMessage;

  // --- SUWAYOMI SERVER CONFIGURATION ---
  String _suwayomiUrl = 'http://172.16.2.102:4567';
  String? _suwayomiSourceId;
  String? _suwayomiSourceName;
  List<SuwayomiSourceModel> _suwayomiSources = [];
  bool _isTestingSuwayomi = false;
  String? _suwayomiConnectionStatus;
  bool _isSuwayomiConnected = false;

  // State Pencarian Lanjutan
  String _advComicType = 'all';
  String _advStatus = 'all';
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

  // Getters Suwayomi & Server
  String get activeServer => 'suwayomi';
  bool get isSuwayomiActive => true;
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
      _suwayomiUrl = prefs.getString(_suwayomiUrlPrefKey) ?? 'http://172.16.2.102:4567';
      _suwayomiSourceId = prefs.getString(_suwayomiSourceIdPrefKey);
      _suwayomiSourceName = prefs.getString(_suwayomiSourceNamePrefKey);
      notifyListeners();

      // Sambungkan ke Suwayomi dan ambil sumber komik
      await testSuwayomiConnection();
    } catch (_) {}
    await fetchHomeData();
  }

  void setActiveServer(String server) {
    // KuroReader sekarang 100% menggunakan Suwayomi
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

  /// Memilih Sumber Komik Aktif dari Suwayomi (Komikindo, Kiryuu, MangaFox, dll)
  Future<void> setSuwayomiSource(String sourceId, String sourceName) async {
    if (_suwayomiSourceId != sourceId) {
      _suwayomiSourceId = sourceId;
      _suwayomiSourceName = sourceName;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_suwayomiSourceIdPrefKey, sourceId);
        await prefs.setString(_suwayomiSourceNamePrefKey, sourceName);
      } catch (_) {}
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
      // Filter out Local source jika ada sumber manga online
      final availableSources = result.sources.where((s) => s.id != '0').toList();
      final effectiveSources = availableSources.isNotEmpty ? availableSources : result.sources;

      // Jika belum ada sumber yang dipilih, default ke sumber online pertama
      if ((_suwayomiSourceId == null || _suwayomiSourceId!.isEmpty) && effectiveSources.isNotEmpty) {
        _suwayomiSourceId = effectiveSources.first.id;
        _suwayomiSourceName = effectiveSources.first.displayName;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_suwayomiSourceIdPrefKey, _suwayomiSourceId!);
          await prefs.setString(_suwayomiSourceNamePrefKey, _suwayomiSourceName!);
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  /// Toggle Safe Search (Filter 18+)
  Future<void> toggleSafeSearch() async {
    _isSafeSearchEnabled = !_isSafeSearchEnabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_safeSearchPrefKey, _isSafeSearchEnabled);
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
      if (_suwayomiSourceId != null && _suwayomiSourceId!.isNotEmpty) {
        _popularManga = await _suwayomiService.getPopularManga(
          _suwayomiUrl,
          _suwayomiSourceId!,
          page: 1,
        );
      } else {
        _popularManga = [];
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
      if (_suwayomiSourceId != null && _suwayomiSourceId!.isNotEmpty) {
        _latestManga = await _suwayomiService.getLatestUpdates(
          _suwayomiUrl,
          _suwayomiSourceId!,
          page: 1,
        );
      } else {
        _latestManga = [];
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

  /// Eksekusi Pencarian Lanjutan
  Future<void> executeAdvancedSearch(String query) async {
    _isAdvancedSearching = true;
    notifyListeners();

    try {
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
    } catch (e) {
      _advancedSearchResults = [];
    } finally {
      _isAdvancedSearching = false;
      notifyListeners();
    }
  }
}
