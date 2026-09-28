import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chapter_model.dart';
import '../models/chapter_pages_model.dart';
import '../models/manga_model.dart';
import '../models/suwayomi_source_model.dart';

class SuwayomiService {
  final http.Client _client = http.Client();

  /// Membersihkan URL agar valid (menghapus trailing slash, memastikan http/https, membersihkan subpath)
  String cleanUrl(String rawUrl) {
    String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return 'https://attending-alien-voip-katrina.trycloudflare.com';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    // Jika user tidak sengaja menyalin URL lengkap dengan subpath
    if (trimmed.endsWith('/api/v1/source/list')) {
      trimmed = trimmed.substring(0, trimmed.length - '/api/v1/source/list'.length);
    } else if (trimmed.endsWith('/api/v1')) {
      trimmed = trimmed.substring(0, trimmed.length - '/api/v1'.length);
    } else if (trimmed.endsWith('/api')) {
      trimmed = trimmed.substring(0, trimmed.length - '/api'.length);
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Menguji koneksi ke Suwayomi-Server dan mengambil sumber yang terpasang
  Future<({bool success, int sourceCount, String? message, List<SuwayomiSourceModel> sources})> testConnection(
    String serverUrl,
  ) async {
    final base = cleanUrl(serverUrl);
    try {
      final uri = Uri.parse('$base/api/v1/source/list');
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final bodyTrimmed = res.body.trim();
        // Cegah FormatException jika server merespons halaman HTML (misal redirect ISP / WebUI SPA)
        if (bodyTrimmed.startsWith('<') || (!bodyTrimmed.startsWith('[') && !bodyTrimmed.startsWith('{'))) {
          return (
            success: false,
            sourceCount: 0,
            message: 'Respons berupa halaman HTML, bukan data API Suwayomi. Cukup masukkan alamat host:port tanpa subpath.',
            sources: <SuwayomiSourceModel>[],
          );
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(bodyTrimmed);
        } catch (e) {
          final preview = bodyTrimmed.length > 50 ? bodyTrimmed.substring(0, 50) : bodyTrimmed;
          return (
            success: false,
            sourceCount: 0,
            message: 'Gagal parse JSON ($preview...). Error: $e',
            sources: <SuwayomiSourceModel>[],
          );
        }

        if (decoded is List) {
          final sources = decoded.map((item) => SuwayomiSourceModel.fromJson(item)).toList();
          return (
            success: true,
            sourceCount: sources.length,
            message: 'Terhubung! Ditemukan ${sources.length} ekstensi sumber.',
            sources: sources,
          );
        } else {
          return (
            success: false,
            sourceCount: 0,
            message: 'Format data Suwayomi tidak sesuai.',
            sources: <SuwayomiSourceModel>[],
          );
        }
      } else {
        return (
          success: false,
          sourceCount: 0,
          message: 'Server merespons kode: ${res.statusCode}',
          sources: <SuwayomiSourceModel>[],
        );
      }
    } catch (e) {
      return (
        success: false,
        sourceCount: 0,
        message: 'Gagal: $e',
        sources: <SuwayomiSourceModel>[],
      );
    }
  }

  /// Mengambil daftar ekstensi sumber (sources) yang terpasang di Suwayomi
  Future<List<SuwayomiSourceModel>> getSources(String serverUrl) async {
    final base = cleanUrl(serverUrl);
    final uri = Uri.parse('$base/api/v1/source/list');
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((item) => SuwayomiSourceModel.fromJson(item)).toList();
    }
    throw Exception('Gagal memuat sumber Suwayomi (${res.statusCode})');
  }

  /// Mengambil komik terpopuler dari sumber tertentu di Suwayomi
  Future<List<MangaModel>> getPopularManga(
    String serverUrl,
    String sourceId, {
    int page = 1,
  }) async {
    final base = cleanUrl(serverUrl);
    final uri = Uri.parse('$base/api/v1/source/$sourceId/popular/$page');
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json is List ? json : (json['mangaList'] as List? ?? []);
      return _parseMangaList(data, base, sourceId);
    }
    throw Exception('Gagal memuat komik populer Suwayomi (${res.statusCode})');
  }

  /// Mengambil update terbaru dari sumber tertentu di Suwayomi
  Future<List<MangaModel>> getLatestUpdates(
    String serverUrl,
    String sourceId, {
    int page = 1,
  }) async {
    final base = cleanUrl(serverUrl);
    final uri = Uri.parse('$base/api/v1/source/$sourceId/latest/$page');
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json is List ? json : (json['mangaList'] as List? ?? []);
      return _parseMangaList(data, base, sourceId);
    }
    throw Exception('Gagal memuat update terbaru Suwayomi (${res.statusCode})');
  }

  /// Mencari komik berdasarkan kata kunci di sumber Suwayomi
  Future<List<MangaModel>> searchManga(
    String serverUrl,
    String sourceId,
    String query, {
    int page = 1,
  }) async {
    final base = cleanUrl(serverUrl);
    final uri = Uri.parse('$base/api/v1/source/$sourceId/search/$page?query=${Uri.encodeComponent(query.trim())}');
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json is List ? json : (json['mangaList'] as List? ?? []);
      return _parseMangaList(data, base, sourceId);
    }
    throw Exception('Gagal mencari komik di Suwayomi (${res.statusCode})');
  }

  /// Mengambil detail komik dari Suwayomi
  Future<MangaModel> getMangaDetail(String serverUrl, String mangaId) async {
    final base = cleanUrl(serverUrl);
    final uri = Uri.parse('$base/api/v1/manga/$mangaId');
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final item = jsonDecode(res.body) as Map<String, dynamic>;
      return MangaModel.fromSuwayomi(item, base);
    }
    throw Exception('Gagal memuat detail komik dari Suwayomi (${res.statusCode})');
  }

  /// Mengambil daftar chapter dari komik di Suwayomi
  Future<List<ChapterModel>> getMangaChapters(String serverUrl, String mangaId) async {
    final base = cleanUrl(serverUrl);
    final uri = Uri.parse('$base/api/v1/manga/$mangaId/chapters');
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json is List ? json : (json['chapters'] as List? ?? []);

      return data.map((item) {
        return ChapterModel.fromSuwayomi(item as Map<String, dynamic>, mangaId: mangaId);
      }).toList();
    }
    throw Exception('Gagal memuat chapter Suwayomi (${res.statusCode})');
  }

  /// Mengambil URL gambar halaman dari chapter di Suwayomi
  Future<ChapterPagesModel> getChapterPages(
    String serverUrl,
    String mangaId,
    String chapterId,
  ) async {
    final base = cleanUrl(serverUrl);
    
    // 1. Dapatkan info chapter untuk mengetahui total halaman
    final uri = Uri.parse('$base/api/v1/manga/$mangaId/chapter/$chapterId');
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final item = jsonDecode(res.body) as Map<String, dynamic>;
      final int pageCount = (item['pageCount'] as num?)?.toInt() ?? 0;

      if (pageCount > 0) {
        final List<String> pageUrls = List.generate(
          pageCount,
          (index) => '$base/api/v1/manga/$mangaId/chapter/$chapterId/page/$index',
        );

        return ChapterPagesModel(
          baseUrl: base,
          pageUrls: pageUrls,
        );
      }
    }

    // 2. Fallback alternatif ke endpoint pages jika ada
    final pagesUri = Uri.parse('$base/api/v1/manga/$mangaId/chapter/$chapterId/pages');
    final pagesRes = await _client.get(pagesUri).timeout(const Duration(seconds: 15));

    if (pagesRes.statusCode == 200) {
      final pagesJson = jsonDecode(pagesRes.body);
      final List pagesList = pagesJson is List ? pagesJson : [];
      final List<String> pageUrls = pagesList.map((p) {
        final str = p.toString();
        return str.startsWith('http') ? str : '$base$str';
      }).toList();

      return ChapterPagesModel(
        baseUrl: base,
        pageUrls: pageUrls,
      );
    }

    throw Exception('Gagal memuat halaman chapter Suwayomi');
  }

  List<MangaModel> _parseMangaList(List data, String base, String sourceId) {
    return data.map((item) {
      return MangaModel.fromSuwayomi(item as Map<String, dynamic>, base, defaultSourceId: sourceId);
    }).toList();
  }
}
