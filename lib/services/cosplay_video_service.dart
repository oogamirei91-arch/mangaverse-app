import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;
import '../models/cosplay_video_model.dart';

/// Layanan untuk mendeteksi, mengekstrak, dan mendekripsi video cosplay (CosplayTele & Cossora)
class CosplayVideoService {
  final http.Client _client = http.Client();

  /// Mengambil daftar video yang tersedia pada postingan Cosplay
  Future<List<CosplayVideoModel>> fetchVideosForManga(
    String mangaUrlOrSlug, {
    String? chapterRealUrl,
    String? mangaTitle,
  }) async {
    final List<CosplayVideoModel> videos = [];

    try {
      // 1. Tentukan target URL web asli
      String targetUrl = '';
      if (chapterRealUrl != null &&
          chapterRealUrl.isNotEmpty &&
          chapterRealUrl.startsWith('http')) {
        targetUrl = chapterRealUrl;
      } else if (mangaUrlOrSlug.startsWith('http')) {
        targetUrl = mangaUrlOrSlug;
      } else {
        final cleanSlug = mangaUrlOrSlug.startsWith('/') ? mangaUrlOrSlug : '/$mangaUrlOrSlug';
        targetUrl = 'https://cosplaytele.com$cleanSlug';
      }

      // 2. Fetch HTML dari postingan cosplay
      final pageRes = await _client.get(
        Uri.parse(targetUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));

      if (pageRes.statusCode != 200) {
        return [];
      }

      final html = pageRes.body;

      // 3. Ekstrak semua URL embed Cossora Stream
      final embedRegex = RegExp(
        r'https?://cossora\.stream/embed/([a-zA-Z0-9-]+)',
        caseSensitive: false,
      );
      final matches = embedRegex.allMatches(html);

      final Set<String> uniqueEmbeds = {};
      for (final m in matches) {
        final fullMatch = m.group(0);
        if (fullMatch != null) {
          uniqueEmbeds.add(fullMatch);
        }
      }

      int videoIndex = 1;
      for (final embedUrl in uniqueEmbeds) {
        try {
          final idMatch = RegExp(r'/embed/([a-zA-Z0-9-]+)').firstMatch(embedUrl);
          final videoId = idMatch?.group(1) ?? 'vid_$videoIndex';

          // Fetch embed HTML untuk mendekripsi stream m3u8
          final embedRes = await _client.get(
            Uri.parse(embedUrl),
            headers: {
              'Referer': 'https://cosplaytele.com/',
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            },
          ).timeout(const Duration(seconds: 10));

          String videoTitle = 'Video $videoIndex';
          String? masterM3u8;
          String? url480p;
          String? url720p;
          String? url1080p;

          if (embedRes.statusCode == 200) {
            final embedBody = embedRes.body;

            // Ekstrak Judul
            final titleMatch = RegExp(
              r'<title>Player\s*\|\s*(.*?)</title>',
              caseSensitive: false,
            ).firstMatch(embedBody);
            if (titleMatch != null && titleMatch.group(1) != null) {
              final rawTitle = titleMatch.group(1)!.trim();
              if (rawTitle.isNotEmpty && !rawTitle.toLowerCase().contains('no video')) {
                videoTitle = rawTitle.replaceAll('.mp4', '').replaceAll('.m3u8', '');
              }
            }

            // Ekstrak ciphertext & key AES
            final urlMatch = RegExp(r"const\s+videoURL\s*=\s*'([^']+)'").firstMatch(embedBody);
            final keyMatch = RegExp(r"decryptLink\s*\(\s*videoURL\s*,\s*'([^']+)'\s*\)").firstMatch(embedBody);

            if (urlMatch != null && keyMatch != null) {
              final encUrl = urlMatch.group(1)!;
              final encKey = keyMatch.group(1)!;

              masterM3u8 = _decryptCossoraAes(encUrl, encKey);

              if (masterM3u8 != null && masterM3u8.contains('.m3u8')) {
                // Buat variasi resolusi dari 480p hingga 1024p (1080p)
                url480p = masterM3u8
                    .replaceAll('index.m3u8', 'master_480p.m3u8')
                    .replaceAll('master_720p.m3u8', 'master_480p.m3u8')
                    .replaceAll('master_1080p.m3u8', 'master_480p.m3u8');
                url720p = masterM3u8
                    .replaceAll('index.m3u8', 'master_720p.m3u8')
                    .replaceAll('master_480p.m3u8', 'master_720p.m3u8')
                    .replaceAll('master_1080p.m3u8', 'master_720p.m3u8');
                url1080p = masterM3u8
                    .replaceAll('index.m3u8', 'master_1080p.m3u8')
                    .replaceAll('master_720p.m3u8', 'master_1080p.m3u8')
                    .replaceAll('master_480p.m3u8', 'master_1080p.m3u8');
              }
            }
          }

          videos.add(
            CosplayVideoModel(
              id: videoId,
              title: videoTitle,
              embedUrl: embedUrl,
              masterM3u8: masterM3u8,
              url480p: url480p,
              url720p: url720p,
              url1080p: url1080p,
            ),
          );
          videoIndex++;
        } catch (_) {
          // Tetap masukkan fallback embed URL jika dekripsi gagal
          videos.add(
            CosplayVideoModel(
              id: 'vid_$videoIndex',
              title: 'Video $videoIndex',
              embedUrl: embedUrl,
            ),
          );
          videoIndex++;
        }
      }
    } catch (_) {}

    return videos;
  }

  /// Mendekripsi link video Cossora Stream menggunakan AES-128-CBC
  String? _decryptCossoraAes(String base64Data, String keyUtf8) {
    try {
      final rawBytes = base64Decode(base64Data);
      if (rawBytes.length <= 16) return null;

      final ivBytes = rawBytes.sublist(0, 16);
      final cipherBytes = rawBytes.sublist(16);

      final key = Key.fromUtf8(keyUtf8);
      final iv = IV(Uint8List.fromList(ivBytes));
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));

      final decrypted = encrypter.decrypt(Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
      return decrypted.trim();
    } catch (_) {
      return null;
    }
  }
}
