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

  String _selectedLanguage = 'all';
  String _selectedComicType = 'all';
  bool _isSafeSearchEnabled = true;
  String? _errorMessage;

  // --- SUWAYOMI SERVER CONFIGURATION ---
  String _suwayomiUrl = 'https://attending-alien-voip-katrina.trycloudflare.com';
  String? _suwayomiSourceId;
  String? _suwayomiSourceName;
  List<SuwayomiSourceModel> _suwayomiSources = [];
  bool _isTestingSuwayomi = false;
  String? _suwayomiConnectionStatus;
  bool _isSuwayomiConnected = false;

  // State Pencarian Lanjutan
  String _advComicType = 'all';
  String _advStatus = 'all';
  String _advLanguage = 'all';
  List<String> _advSelectedGenreIds = [];
  List<String> _advSelectedRatings = ['safe', 'suggestive', 'erotica', 'pornographic'];

  List<MangaModel> get popularManga => _applyContentFilter(_popularManga);
  List<MangaModel> get latestManga => _applyContentFilter(_latestManga);
  List<MangaModel> get searchResults => _applyContentFilter(_searchResults);
  List<MangaModel> get advancedSearchResults => _applyContentFilter(_advancedSearchResults);
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingLatest => _isLoadingLatest;
  bool get isSearching => _isSearching;
  bool get isAdvancedSearching => _isAdvancedSearching;
  String get selectedLanguage => _selectedLanguage;
  String get selectedComicType => _selectedComicType;
  bool get isSafeSearchEnabled => _isSafeSearchEnabled;
  String? get errorMessage => _errorMessage;

  // Filter Sumber Komik: HANYA BAHASA ID & EN (sumber bahasa lain tidak dimasukkan)
  // Serta difilter berdasarkan status Safe Search (Safe vs 18+)
  List<SuwayomiSourceModel> get suwayomiSources {
    final online = _suwayomiSources.where((s) {
      if (s.id == '0') return false;
      final l = s.lang.toLowerCase();
      return l == 'id' || l == 'en' || l == 'eng';
    }).toList();

    // Saat Safe Search ON: sembunyikan sumber khusus 18+ murni
    // Saat Safe Search OFF (Filter 18+ ON): tampilkan semua sumber ID & EN termasuk 18+
    if (_isSafeSearchEnabled) {
      final safe = online.where((s) => !s.isDedicatedNsfw).toList();
      return safe.isNotEmpty ? safe : online;
    } else {
      return online;
    }
  }

  // Getters Suwayomi & Server
  String get activeServer => 'suwayomi';
  bool get isSuwayomiActive => true;
  String get suwayomiUrl => _suwayomiUrl;
  String? get suwayomiSourceId => _suwayomiSourceId;
  String? get suwayomiSourceName => _suwayomiSourceName;
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
      _suwayomiUrl = prefs.getString(_suwayomiUrlPrefKey) ?? 'https://attending-alien-voip-katrina.trycloudflare.com';
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
      // HANYA simpan sumber bahasa ID dan EN, buang semua bahasa lainnya
      _suwayomiSources = result.sources.where((s) {
        if (s.id == '0') return false;
        final l = s.lang.toLowerCase();
        return l == 'id' || l == 'en' || l == 'eng';
      }).toList();
      final availableSources = suwayomiSources;

      // Jika belum ada sumber yang dipilih atau sumber tidak valid di mode saat ini
      if (availableSources.isNotEmpty &&
          (_suwayomiSourceId == null ||
           _suwayomiSourceId!.isEmpty ||
           !availableSources.any((s) => s.id == _suwayomiSourceId))) {
        _suwayomiSourceId = availableSources.first.id;
        _suwayomiSourceName = availableSources.first.displayName;
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
    await setSafeSearch(!_isSafeSearchEnabled);
  }

  /// Mengatur Safe Search secara eksplisit
  Future<void> setSafeSearch(bool enabled) async {
    _isSafeSearchEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_safeSearchPrefKey, _isSafeSearchEnabled);
    } catch (_) {}

    // Otomatis alihkan sumber aktif ke sumber yang sesuai dengan mode baru
    final available = suwayomiSources;
    if (available.isNotEmpty && !available.any((s) => s.id == _suwayomiSourceId)) {
      await setSuwayomiSource(available.first.id, available.first.displayName);
    } else {
      await fetchHomeData();
    }
  }

  /// Filter konten komik berdasarkan status Safe Search
  List<MangaModel> _applyContentFilter(List<MangaModel> list) {
    if (_isSafeSearchEnabled) {
      // Safe Search ON: Sembunyikan semua komik yang berbau NSFW / 18+
      return list.where((m) => !_isNsfwManga(m)).toList();
    } else {
      // Safe Search OFF (Filter 18+ ON): Munculkan semua komik termasuk 18+ dan NSFW
      return list;
    }
  }

  /// Deteksi apakah komik memiliki konten NSFW / 18+
  bool _isNsfwManga(MangaModel m) {
    const nsfwKeywords = [
      'hentai',
      'ecchi',
      'adult',
      'mature',
      'erotica',
      'pornographic',
      'smut',
      '18+',
      'doujinshi',
      'r-18',
      'r18',
      'nsfw',
    ];
    final tagsLower = m.tags.map((t) => t.toLowerCase()).toList();
    for (final kw in nsfwKeywords) {
      if (tagsLower.any((t) => t.contains(kw))) return true;
      if (m.title.toLowerCase().contains(kw)) return true;
    }
    // Jika komik berasal dari sumber khusus 18+/Hentai murni (3Hentai, HentaiFox, dll)
    if (m.sourceId != null) {
      final src = _suwayomiSources.firstWhere(
        (s) => s.id == m.sourceId,
        orElse: () => SuwayomiSourceModel(id: '', name: '', lang: '', isNsfw: false),
      );
      if (src.isDedicatedNsfw) return true;
    }
    return false;
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

  /// Ganti filter bahasa (id = Indonesia, en = Inggris, all = Semua ID & EN)
  void setLanguageFilter(String lang) {
    if (_selectedLanguage != lang) {
      _selectedLanguage = lang;
      notifyListeners();

      final available = suwayomiSources;
      if (lang == 'id') {
        final idSource = available.firstWhere(
          (s) => s.lang.toLowerCase() == 'id',
          orElse: () => available.first,
        );
        setSuwayomiSource(idSource.id, idSource.displayName);
      } else if (lang == 'en') {
        final enSource = available.firstWhere(
          (s) => s.lang.toLowerCase() == 'en' || s.lang.toLowerCase() == 'eng',
          orElse: () => available.first,
        );
        setSuwayomiSource(enSource.id, enSource.displayName);
      } else {
        fetchHomeData();
      }
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
    _advLanguage = 'all';
    _advSelectedGenreIds.clear();
    _advSelectedRatings = ['safe', 'suggestive', 'erotica', 'pornographic'];
    _advancedSearchResults.clear();
    notifyListeners();
  }

  /// Eksekusi Pencarian Lanjutan dengan Filter Sesuai Sumber
  Future<void> executeAdvancedSearch(String query) async {
    _isAdvancedSearching = true;
    notifyListeners();

    try {
      if (_suwayomiSourceId != null && _suwayomiSourceId!.isNotEmpty) {
        final rawResults = await _suwayomiService.searchManga(
          _suwayomiUrl,
          _suwayomiSourceId!,
          query,
          page: 1,
        );

        _advancedSearchResults = rawResults.where((manga) {
          // 1. Filter Status
          if (_advStatus != 'all') {
            final st = manga.status.toLowerCase();
            if (_advStatus == 'ongoing' && !st.contains('ongoing') && !st.contains('publishing')) {
              return false;
            }
            if (_advStatus == 'completed' && !st.contains('completed') && !st.contains('finished')) {
              return false;
            }
          }

          // 2. Filter Tipe Komik (Manga, Manhwa, Manhua)
          if (_advComicType != 'all') {
            final typeLower = _advComicType.toLowerCase();
            final titleLower = manga.title.toLowerCase();
            final tagsLower = manga.tags.map((t) => t.toLowerCase()).toList();
            final matchesType = titleLower.contains(typeLower) || tagsLower.contains(typeLower);
            if (!matchesType) return false;
          }

          // 3. Filter Genre Terpilih
          if (_advSelectedGenreIds.isNotEmpty) {
            final tagsLower = manga.tags.map((t) => t.toLowerCase()).toList();
            for (final genre in _advSelectedGenreIds) {
              if (!tagsLower.any((t) => t.contains(genre.toLowerCase()))) {
                return false;
              }
            }
          }

          return true;
        }).toList();
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
