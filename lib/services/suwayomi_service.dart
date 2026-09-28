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
    if (trimmed.isEmpty) return 'https://pilot-omaha-korea-limousines.trycloudflare.com';
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
          final sources = decoded
              .map((item) => SuwayomiSourceModel.fromJson(item))
              .where((s) {
                if (s.id == '0') return false;
                final l = s.lang.toLowerCase();
                return l == 'id' || l == 'en' || l == 'eng' || l == 'all';
              })
              .toList();
          return (
            success: true,
            sourceCount: sources.length,
            message: 'Terhubung! Ditemukan ${sources.length} ekstensi sumber (ID, EN & Galeri).',
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
      final bodyTrimmed = res.body.trim();
      if (bodyTrimmed.startsWith('<') || !bodyTrimmed.startsWith('[')) {
        throw Exception('Server mengembalikan respons HTML, bukan data ekstensi.');
      }
      final List data = jsonDecode(bodyTrimmed);
      return data
          .map((item) => SuwayomiSourceModel.fromJson(item))
          .where((s) {
            if (s.id == '0') return false;
            final l = s.lang.toLowerCase();
            return l == 'id' || l == 'en' || l == 'eng' || l == 'all';
          })
          .toList();
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
      final bodyTrimmed = res.body.trim();
      if (bodyTrimmed.startsWith('<')) {
        throw Exception('Server mengembalikan respons web HTML, bukan data komik.');
      }
      final json = jsonDecode(bodyTrimmed);
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
      final bodyTrimmed = res.body.trim();
      if (bodyTrimmed.startsWith('<')) {
        throw Exception('Server mengembalikan respons web HTML, bukan data komik.');
      }
      final json = jsonDecode(bodyTrimmed);
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
      final bodyTrimmed = res.body.trim();
      if (bodyTrimmed.startsWith('<')) {
        throw Exception('Server mengembalikan respons web HTML, bukan data pencarian.');
      }
      final json = jsonDecode(bodyTrimmed);
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
      final bodyTrimmed = res.body.trim();
      if (bodyTrimmed.startsWith('<')) {
        throw Exception('Server mengembalikan respons web HTML, bukan data komik.');
      }
      final item = jsonDecode(bodyTrimmed) as Map<String, dynamic>;
      return MangaModel.fromSuwayomi(item, base);
    }
    throw Exception('Gagal memuat detail komik dari Suwayomi (${res.statusCode})');
  }

  /// Mengambil daftar chapter dari komik di Suwayomi
  Future<List<ChapterModel>> getMangaChapters(String serverUrl, String mangaId) async {
    final base = cleanUrl(serverUrl);
    final uri = Uri.parse('$base/api/v1/manga/$mangaId/chapters');
    final res = await _client.get(uri).timeout(const Duration(seconds: 25));

    if (res.statusCode == 200) {
      final bodyTrimmed = res.body.trim();
      if (bodyTrimmed.startsWith('<')) {
        throw Exception('Server mengembalikan respons web HTML, bukan data chapter.');
      }
      final json = jsonDecode(bodyTrimmed);
      final List data = json is List ? json : (json['chapters'] as List? ?? []);

      return data.map((item) {
        return ChapterModel.fromSuwayomi(item as Map<String, dynamic>, mangaId: mangaId);
      }).toList();
    }
    throw Exception('Gagal memuat chapter Suwayomi (${res.statusCode})');
  }

  /// Mengambil URL gambar halaman dari chapter di Suwayomi dengan auto-retry
  Future<ChapterPagesModel> getChapterPages(
    String serverUrl,
    String mangaId,
    String chapterIndexOrId, {
    int? chapterIndex,
  }) async {
    final base = cleanUrl(serverUrl);
    // Suwayomi API v1 mewajibkan chapterIndex (misal 1, 2, 539), BUKAN chapterId database (misal 4858).
    String targetIndex = (chapterIndex != null && chapterIndex > 0)
        ? chapterIndex.toString()
        : chapterIndexOrId;

    int attempts = 0;
    const maxAttempts = 2;
    String lastError = '';

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final uri = Uri.parse('$base/api/v1/manga/$mangaId/chapter/$targetIndex');
        final res = await _client.get(uri).timeout(const Duration(seconds: 25));

        if (res.statusCode == 200) {
          final bodyTrimmed = res.body.trim();
          // Cegah parsing FormatException jika server mengembalikan fallback HTML SPA WebUI
          if (bodyTrimmed.startsWith('<') || (!bodyTrimmed.startsWith('{') && !bodyTrimmed.startsWith('['))) {
            throw Exception('Situs sumber mengembalikan halaman web HTML (mungkin terblokir Cloudflare atau proteksi ISP).');
          }

          final item = jsonDecode(bodyTrimmed) as Map<String, dynamic>;
          final int pageCount = (item['pageCount'] as num?)?.toInt() ?? 0;

          if (pageCount > 0) {
            final List<String> pageUrls = List.generate(
              pageCount,
              (index) => '$base/api/v1/manga/$mangaId/chapter/$targetIndex/page/$index',
            );

            return ChapterPagesModel(
              baseUrl: base,
              pageUrls: pageUrls,
            );
          } else if (pageCount == -1 || pageCount == 0) {
            // Suwayomi mungkin sedang onlineFetch ke website sumber, beri waktu sejenak lalu coba lagi
            if (attempts < maxAttempts) {
              await Future.delayed(const Duration(milliseconds: 1500));
              continue;
            }
            throw Exception('Halaman chapter belum tersedia dari situs sumber (pageCount = 0).');
          }
        } else if (res.statusCode == 404) {
          // Jika 404 dan targetIndex tadinya chapterId (bukan chapter.index),
          // cari chapter.index sebenarnya dari daftar chapters komik ini secara otomatis
          if (attempts == 1 && chapterIndex == null) {
            try {
              final chapters = await getMangaChapters(serverUrl, mangaId);
              final match = chapters.firstWhere(
                (c) => c.id == targetIndex || c.chapter == targetIndex,
                orElse: () => chapters.first,
              );
              if (match.index != null && match.index.toString() != targetIndex) {
                targetIndex = match.index.toString();
                continue; // Coba lagi dengan index yang tepat!
              }
            } catch (_) {}
          }
          throw Exception('Chapter tidak ditemukan di situs aslinya (404 Not Found - tautan mati atau telah dihapus).');
        } else if (res.statusCode == 500) {
          final body = res.body.trim();
          if (body.contains('No such host') || body.contains('UnknownHostException')) {
            throw Exception('Domain situs komik ini tidak dapat dijangkau (domain web aslinya mungkin telah berganti atau terblokir DNS).');
          } else if (body.contains('Cloudflare') || body.contains('403') || body.contains('Turnstile')) {
            throw Exception('Situs sumber komik dilindungi Cloudflare / Captcha sehingga chapter gagal dimuat.');
          }
          lastError = 'Situs sumber komik merespons error (500).';
        } else {
          lastError = 'Server Suwayomi merespons kode: ${res.statusCode}.';
        }
      } catch (e) {
        lastError = e.toString().replaceFirst('Exception: ', '');
        if (attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
        }
      }
    }

    throw Exception(
      lastError.isNotEmpty
          ? lastError
          : 'Gagal memuat halaman chapter. Silakan coba chapter lain atau gunakan sumber alternatif.',
    );
  }

  List<MangaModel> _parseMangaList(List data, String base, String sourceId) {
    return data.map((item) {
      return MangaModel.fromSuwayomi(item as Map<String, dynamic>, base, defaultSourceId: sourceId);
    }).toList();
  }
}
