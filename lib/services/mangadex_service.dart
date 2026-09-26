import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga_model.dart';
import '../models/chapter_model.dart';
import '../models/chapter_pages_model.dart';

class MangaDexService {
  static const String baseUrl = 'https://api.mangadex.org';

  final http.Client _client;

  MangaDexService({http.Client? client}) : _client = client ?? http.Client();

  /// Mengambil daftar Manga Terpopuler
  Future<List<MangaModel>> getPopularManga({
    int limit = 20,
    int offset = 0,
    String? language = 'id',
  }) async {
    final Map<String, dynamic> queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      'order[followedCount]': 'desc',
      'includes[]': ['cover_art', 'author', 'artist'],
      'contentRating[]': ['safe', 'suggestive'],
    };

    if (language != null && language.isNotEmpty) {
      queryParams['availableTranslatedLanguage[]'] = language;
    }

    final uri = Uri.parse('$baseUrl/manga').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((item) => MangaModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat manga populer (${response.statusCode})');
    }
  }

  /// Mengambil daftar Manga yang Baru Diupdate
  Future<List<MangaModel>> getLatestUpdates({
    int limit = 20,
    int offset = 0,
    String? language = 'id',
  }) async {
    final Map<String, dynamic> queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      'order[latestUploadedChapter]': 'desc',
      'includes[]': ['cover_art', 'author'],
      'contentRating[]': ['safe', 'suggestive'],
    };

    if (language != null && language.isNotEmpty) {
      queryParams['availableTranslatedLanguage[]'] = language;
    }

    final uri = Uri.parse('$baseUrl/manga').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((item) => MangaModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat update terbaru (${response.statusCode})');
    }
  }

  /// Mencari Manga berdasarkan Keyword/Judul
  Future<List<MangaModel>> searchManga(
    String query, {
    int limit = 20,
    int offset = 0,
    String? language,
  }) async {
    if (query.trim().isEmpty) return [];

    final Map<String, dynamic> queryParams = {
      'title': query.trim(),
      'limit': limit.toString(),
      'offset': offset.toString(),
      'order[relevance]': 'desc',
      'includes[]': ['cover_art', 'author'],
      'contentRating[]': ['safe', 'suggestive'],
    };

    if (language != null && language.isNotEmpty) {
      queryParams['availableTranslatedLanguage[]'] = language;
    }

    final uri = Uri.parse('$baseUrl/manga').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((item) => MangaModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal mencari komik (${response.statusCode})');
    }
  }

  /// Mengambil Detail Spesifik Manga (beserta cover & author)
  Future<MangaModel> getMangaDetail(String mangaId) async {
    final uri = Uri.parse('$baseUrl/manga/$mangaId?includes[]=cover_art&includes[]=author&includes[]=artist');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return MangaModel.fromJson(json['data']);
    } else {
      throw Exception('Gagal memuat detail komik (${response.statusCode})');
    }
  }

  /// Mengambil Daftar Chapter dari sebuah Manga
  Future<List<ChapterModel>> getMangaChapters(
    String mangaId, {
    String language = 'id',
    int limit = 100,
    int offset = 0,
  }) async {
    final Map<String, dynamic> queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      'order[chapter]': 'asc', // Urutkan dari chapter 1 ke atas
      'includes[]': ['scanlation_group', 'user'],
      'contentRating[]': ['safe', 'suggestive'],
    };

    if (language.isNotEmpty && language != 'all') {
      queryParams['translatedLanguage[]'] = language;
    }

    final uri = Uri.parse('$baseUrl/manga/$mangaId/feed').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((item) => ChapterModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat chapter (${response.statusCode})');
    }
  }

  /// Mengambil URL Gambar Halaman Chapter via MangaDex@Home
  Future<ChapterPagesModel> getChapterPages(String chapterId) async {
    final uri = Uri.parse('$baseUrl/at-home/server/$chapterId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ChapterPagesModel.fromJson(json);
    } else {
      throw Exception('Gagal memuat halaman komik (${response.statusCode})');
    }
  }
}
