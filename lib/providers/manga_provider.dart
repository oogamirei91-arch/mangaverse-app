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
  String _suwayomiUrl = 'https://pilot-omaha-korea-limousines.trycloudflare.com';
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
  String _lastSearchQuery = '';

  String get lastSearchQuery => _lastSearchQuery;
  bool get isSearchActive => _isSearching || _lastSearchQuery.isNotEmpty;
  String get selectedLanguage => _selectedLanguage;
  String get selectedComicType => _selectedComicType;
  bool get isSafeSearchEnabled => _isSafeSearchEnabled;
  String? get errorMessage => _errorMessage;

  /// Urutkan sumber agar sumber unggulan (MangaWest, Komikindo, Kiryuu, MangaFox, Mangabat, Manhwa.cc) berada paling atas
  List<SuwayomiSourceModel> _sortSources(List<SuwayomiSourceModel> list) {
    final copy = List<SuwayomiSourceModel>.from(list);
    copy.sort((a, b) {
      final pA = a.priorityOrder;
      final pB = b.priorityOrder;
      if (pA != pB) return pA.compareTo(pB);
      final langRankA = a.lang.toLowerCase() == 'id' ? 0 : (a.lang.toLowerCase() == 'en' ? 1 : 2);
      final langRankB = b.lang.toLowerCase() == 'id' ? 0 : (b.lang.toLowerCase() == 'en' ? 1 : 2);
      if (langRankA != langRankB) return langRankA.compareTo(langRankB);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return copy;
  }

  // Filter Sumber Komik: BAHASA ID, EN & SEMUA (ALL / GALERI / COSPLAY)
  // Serta difilter berdasarkan status Safe Search (Safe vs 18+)
  List<SuwayomiSourceModel> get suwayomiSources {
    final online = _suwayomiSources.where((s) {
      if (s.id == '0') return false;
      final l = s.lang.toLowerCase();
      return l == 'id' || l == 'en' || l == 'eng' || l == 'all';
    }).toList();

    // Saat Safe Search ON: sembunyikan sumber khusus 18+ murni
    // Saat Safe Search OFF (Filter 18+ ON): tampilkan semua sumber ID, EN & ALL termasuk Cosplay/18+
    if (_isSafeSearchEnabled) {
      final safe = online.where((s) => !s.isDedicatedNsfw).toList();
      return _sortSources(safe.isNotEmpty ? safe : online);
    } else {
      return _sortSources(online);
    }
  }

  /// Seluruh sumber ID, EN, ALL tanpa terpengaruh filter safe search (untuk tab/picker)
  List<SuwayomiSourceModel> get allSuwayomiSourcesRaw {
    return _sortSources(_suwayomiSources.where((s) {
      if (s.id == '0') return false;
      final l = s.lang.toLowerCase();
      return l == 'id' || l == 'en' || l == 'eng' || l == 'all';
    }).toList());
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
      _suwayomiUrl = prefs.getString(_suwayomiUrlPrefKey) ?? 'https://pilot-omaha-korea-limousines.trycloudflare.com';
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
      // Simpan sumber bahasa ID, EN, dan ALL (Cosplay & Galeri), buang bahasa asing lainnya
      _suwayomiSources = result.sources.where((s) {
        if (s.id == '0') return false;
        final l = s.lang.toLowerCase();
        return l == 'id' || l == 'en' || l == 'eng' || l == 'all';
      }).toList();
      final availableSources = suwayomiSources;

      // Jika belum ada sumber yang dipilih atau sumber tidak valid di mode saat ini
      if (availableSources.isNotEmpty &&
          (_suwayomiSourceId == null ||
           _suwayomiSourceId!.isEmpty ||
           !availableSources.any((s) => s.id == _suwayomiSourceId))) {
        // Sumber server awal bahasa Indonesia: Komikindo atau MangaWest atau Kiryuu
        final defaultSrc = availableSources.firstWhere(
          (s) => s.isKomikindo,
          orElse: () => availableSources.firstWhere(
            (s) => s.isMangaWest,
            orElse: () => availableSources.firstWhere(
              (s) => s.isKiryuu,
              orElse: () => availableSources.first,
            ),
          ),
        );
        _suwayomiSourceId = defaultSrc.id;
        _suwayomiSourceName = defaultSrc.displayName;
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

  /// Ganti filter bahasa (id = Indonesia, en = Inggris, all = Semua, gallery = Cosplay & Galeri)
  void setLanguageFilter(String lang) {
    if (_selectedLanguage != lang) {
      _selectedLanguage = lang;
      notifyListeners();

      final available = suwayomiSources;
      if (lang == 'id') {
        final idSource = available.firstWhere(
          (s) => s.isKomikindo,
          orElse: () => available.firstWhere(
            (s) => s.isMangaWest,
            orElse: () => available.firstWhere(
              (s) => s.isKiryuu,
              orElse: () => available.firstWhere(
                (s) => s.lang.toLowerCase() == 'id',
                orElse: () => available.first,
              ),
            ),
          ),
        );
        setSuwayomiSource(idSource.id, idSource.displayName);
      } else if (lang == 'en') {
        final enSource = available.firstWhere(
          (s) => s.isMangabat,
          orElse: () => available.firstWhere(
            (s) => s.isMangaFox,
            orElse: () => available.firstWhere(
              (s) => s.isManhwaCc,
              orElse: () => available.firstWhere(
                (s) => s.lang.toLowerCase() == 'en' || s.lang.toLowerCase() == 'eng',
                orElse: () => available.first,
              ),
            ),
          ),
        );
        setSuwayomiSource(enSource.id, enSource.displayName);
      } else if (lang == 'gallery' || lang == 'cosplay') {
        final galSource = available.firstWhere(
          (s) => s.name.toLowerCase().contains('cosplay') || s.lang.toLowerCase() == 'all',
          orElse: () => available.first,
        );
        setSuwayomiSource(galSource.id, galSource.displayName);
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
    final cleanQ = query.trim();
    if (cleanQ.isEmpty) {
      clearSearch();
      return;
    }

    _lastSearchQuery = cleanQ;
    _isSearching = true;
    notifyListeners();

    try {
      if (_suwayomiSourceId != null && _suwayomiSourceId!.isNotEmpty) {
        var results = await _suwayomiService.searchManga(
          _suwayomiUrl,
          _suwayomiSourceId!,
          cleanQ,
          page: 1,
        );

        // Fallback jika sumber aktif 0 hasil: coba cari di sumber utama bahasa yang sama
        if (results.isEmpty) {
          final currentSrc = _suwayomiSources.firstWhere(
            (s) => s.id == _suwayomiSourceId,
            orElse: () => SuwayomiSourceModel(id: '', name: '', lang: 'id'),
          );
          final sameLangAlternates = suwayomiSources.where(
            (s) => s.id != _suwayomiSourceId && s.lang.toLowerCase() == currentSrc.lang.toLowerCase() && s.isFeatured,
          );
          for (final alt in sameLangAlternates) {
            try {
              final altRes = await _suwayomiService.searchManga(_suwayomiUrl, alt.id, cleanQ, page: 1);
              if (altRes.isNotEmpty) {
                results = altRes;
                break;
              }
            } catch (_) {}
          }
        }

        _searchResults = results;
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
    _lastSearchQuery = '';
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
    if (genreId == 'all') {
      _advSelectedGenreIds.clear();
      notifyListeners();
      return;
    }
    if (_advSelectedGenreIds.contains(genreId)) {
      _advSelectedGenreIds.remove(genreId);
    } else {
      _advSelectedGenreIds.add(genreId);
    }
    notifyListeners();
  }

  void selectAllGenres() {
    _advSelectedGenreIds.clear();
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
        // Tentukan kata kunci pencarian yang dikirim ke sumber:
        // 1. Jika query diisi user -> gunakan query
        // 2. Jika query kosong tapi ada genre terpilih -> gunakan genre sebagai query
        // 3. Jika query kosong tapi tipe komik (manhwa/manhua) dipilih -> gunakan tipe komik
        // 4. Jika semua kosong -> ambil komik populer
        String targetQuery = query.trim();
        if (targetQuery.isEmpty) {
          if (_advSelectedGenreIds.isNotEmpty) {
            targetQuery = _advSelectedGenreIds.first;
          } else if (_advComicType != 'all') {
            targetQuery = _advComicType;
          }
        }

        List<MangaModel> rawResults;
        if (targetQuery.isEmpty) {
          rawResults = await _suwayomiService.getPopularManga(
            _suwayomiUrl,
            _suwayomiSourceId!,
            page: 1,
          );
        } else {
          rawResults = await _suwayomiService.searchManga(
            _suwayomiUrl,
            _suwayomiSourceId!,
            targetQuery,
            page: 1,
          );
          // Fallback jika sumber aktif 0 hasil: coba cari di sumber rekomendasi lainnya dalam bahasa yang sama
          if (rawResults.isEmpty) {
            final currentSrc = _suwayomiSources.firstWhere(
              (s) => s.id == _suwayomiSourceId,
              orElse: () => SuwayomiSourceModel(id: '', name: '', lang: 'id'),
            );
            final alternates = suwayomiSources.where(
              (s) => s.id != _suwayomiSourceId && s.lang.toLowerCase() == currentSrc.lang.toLowerCase() && s.isFeatured,
            );
            for (final alt in alternates) {
              try {
                final altRes = await _suwayomiService.searchManga(_suwayomiUrl, alt.id, targetQuery, page: 1);
                if (altRes.isNotEmpty) {
                  rawResults = altRes;
                  break;
                }
              } catch (_) {}
            }
          }
        }

        // Terapkan filter client-side secara cerdas dan toleran
        _advancedSearchResults = rawResults.where((manga) {
          // 0. Filter Safe Search (18+ / NSFW)
          if (_isSafeSearchEnabled && _isNsfwManga(manga)) {
            return false;
          }

          // 1. Filter Status Komik (ongoing / completed)
          if (_advStatus != 'all') {
            final st = manga.status.toLowerCase();
            // Hanya filter jika status sudah diketahui ('unknown' tidak dibuang)
            if (st != 'unknown' && st.isNotEmpty && st != '0') {
              if (_advStatus == 'ongoing' && !st.contains('ongoing') && !st.contains('publishing') && !st.contains('1')) {
                return false;
              }
              if (_advStatus == 'completed' && !st.contains('completed') && !st.contains('finished') && !st.contains('2')) {
                return false;
              }
            }
          }

          // 2. Filter Tipe Komik (Manga, Manhwa, Manhua)
          if (_advComicType != 'all') {
            final typeLower = _advComicType.toLowerCase();
            final titleLower = manga.title.toLowerCase();
            final tagsLower = manga.tags.map((t) => t.toLowerCase()).toList();
            final descLower = (manga.description ?? '').toLowerCase();

            if (tagsLower.isNotEmpty || descLower.isNotEmpty) {
              final matches = titleLower.contains(typeLower) ||
                  tagsLower.any((t) => t.contains(typeLower)) ||
                  descLower.contains(typeLower);
              if (!matches) return false;
            } else {
              // Jika tags belum diinisialisasi (ringkasan Tachiyomi),
              // cek apakah judul mengandung kata kunci tipe jika user mencari kata spesifik
              if (titleLower.contains('manga') || titleLower.contains('manhwa') || titleLower.contains('manhua')) {
                if (!titleLower.contains(typeLower)) return false;
              }
            }
          }

          // 3. Filter Genre Terpilih
          if (_advSelectedGenreIds.isNotEmpty) {
            final tagsLower = manga.tags.map((t) => t.toLowerCase()).toList();
            final descLower = (manga.description ?? '').toLowerCase();

            // Jika tags terisi dari Suwayomi, cek apakah memuat genre
            if (tagsLower.isNotEmpty) {
              for (final genre in _advSelectedGenreIds) {
                final gLower = genre.toLowerCase();
                final hasTag = tagsLower.any((t) => t.contains(gLower));
                final hasDesc = descLower.contains(gLower);
                if (!hasTag && !hasDesc) {
                  return false;
                }
              }
            } else if (descLower.isNotEmpty) {
              // Cek deskripsi jika tags kosong
              for (final genre in _advSelectedGenreIds) {
                if (!descLower.contains(genre.toLowerCase())) {
                  return false;
                }
              }
            } else {
              // Jika tags & deskripsi kosong dari ringkasan list Tachiyomi,
              // jangan eliminasi karena sudah dicari via query genre ke sumber
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
