import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cosplay_video_model.dart';
import '../../models/manga_model.dart';
import '../../services/cosplay_video_service.dart';

/// Halaman Pemutar Video Khusus Cosplay & Galeri (CosplayTele / Cossora)
/// Mendukung multi-kualitas dari 480p hingga 1024p / 1080p, serta multi-video episode
class CosplayVideoPlayerScreen extends StatefulWidget {
  final MangaModel manga;
  final String? chapterRealUrl;

  const CosplayVideoPlayerScreen({
    super.key,
    required this.manga,
    this.chapterRealUrl,
  });

  @override
  State<CosplayVideoPlayerScreen> createState() => _CosplayVideoPlayerScreenState();
}

class _CosplayVideoPlayerScreenState extends State<CosplayVideoPlayerScreen> {
  final CosplayVideoService _videoService = CosplayVideoService();
  WebViewController? _webViewController;

  bool _isLoading = true;
  String? _errorMessage;
  List<CosplayVideoModel> _videos = [];
  int _currentVideoIndex = 0;
  String _selectedQuality = 'Auto'; // 'Auto', '480p', '720p', '1024p'
  bool _useNativeHls = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vids = await _videoService.fetchVideosForManga(
        widget.manga.url,
        chapterRealUrl: widget.chapterRealUrl,
        mangaTitle: widget.manga.title,
      );

      if (vids.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Tidak ditemukan file video pada set cosplay ini.';
        });
        return;
      }

      setState(() {
        _videos = vids;
        _currentVideoIndex = 0;
        _isLoading = false;
      });

      _initPlayer();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat video: ${e.toString().replaceFirst("Exception: ", "")}';
      });
    }
  }

  void _initPlayer() {
    if (_videos.isEmpty) return;

    final currentVideo = _videos[_currentVideoIndex];
    final streamUrl = currentVideo.getUrlForQuality(_selectedQuality);

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            // Izinkan domain stream video & CDN utama
            if (url.contains('cossora.stream') ||
                url.contains('cosplaytele.com') ||
                url.contains('jsdelivr.net') ||
                url.contains('googleapis.com') ||
                url.contains('gstatic.com') ||
                url.contains('blob:') ||
                url.contains('data:')) {
              return NavigationDecision.navigate;
            }
            // Blokir iklan pop-up & redirect eksternal
            return NavigationDecision.prevent;
          },
        ),
      );

    if (_useNativeHls && currentVideo.masterM3u8 != null) {
      // Gunakan Custom HTML5 HLS Player dengan HLS.js untuk kontrol resolusi instan
      final html = _buildHlsHtml(streamUrl);
      controller.loadHtmlString(html, baseUrl: 'https://cossora.stream');
    } else {
      // Fallback ke embed iframe resmi dengan Referer header
      controller.loadRequest(
        Uri.parse(currentVideo.embedUrl),
        headers: {
          'Referer': 'https://cosplaytele.com/',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        },
      );
    }

    setState(() {
      _webViewController = controller;
    });
  }

  String _buildHlsHtml(String streamUrl) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1.5.7"></script>
  <style>
    * { box-sizing: border-box; }
    body, html { margin:0; padding:0; width:100%; height:100%; background:#000; overflow:hidden; display:flex; justify-content:center; align-items:center; }
    video { width:100%; height:100%; object-fit:contain; outline:none; }
  </style>
</head>
<body>
  <video id="video" controls autoplay playsinline webkit-playsinline></video>
  <script>
    var video = document.getElementById('video');
    var videoSrc = '$streamUrl';

    function initHls() {
      if (Hls.isSupported()) {
        var hls = new Hls({
          enableWorker: true,
          lowLatencyMode: true,
          xhrSetup: function(xhr, url) {
            xhr.withCredentials = false;
          }
        });
        hls.loadSource(videoSrc);
        hls.attachMedia(video);
        hls.on(Hls.Events.MANIFEST_PARSED, function() {
          video.play().catch(function(e) {});
        });
        hls.on(Hls.Events.ERROR, function(event, data) {
          if (data.fatal) {
            switch(data.type) {
              case Hls.ErrorTypes.NETWORK_ERROR:
                hls.startLoad();
                break;
              case Hls.ErrorTypes.MEDIA_ERROR:
                hls.recoverMediaError();
                break;
              default:
                hls.destroy();
                break;
            }
          }
        });
      } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = videoSrc;
        video.addEventListener('loadedmetadata', function() {
          video.play().catch(function(e) {});
        });
      }
    }
    initHls();
  </script>
</body>
</html>
''';
  }

  void _switchQuality(String quality) {
    if (_selectedQuality == quality) return;
    setState(() {
      _selectedQuality = quality;
    });

    final currentVideo = _videos[_currentVideoIndex];
    final newUrl = currentVideo.getUrlForQuality(quality);

    if (_useNativeHls && currentVideo.masterM3u8 != null) {
      final html = _buildHlsHtml(newUrl);
      _webViewController?.loadHtmlString(html, baseUrl: 'https://cossora.stream');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kualitas video diubah ke: $quality'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _switchVideo(int index) {
    if (index < 0 || index >= _videos.length) return;
    setState(() {
      _currentVideoIndex = index;
    });
    _initPlayer();
  }

  Future<void> _openInExternalPlayer() async {
    if (_videos.isEmpty) return;
    final currentVideo = _videos[_currentVideoIndex];
    final streamUrl = currentVideo.getUrlForQuality(_selectedQuality);

    final uri = Uri.parse(streamUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(Uri.parse(currentVideo.embedUrl), mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka pemutar eksternal.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVideo = _videos.isNotEmpty ? _videos[_currentVideoIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0B0E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.manga.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (_videos.isNotEmpty)
              Text(
                'Video ${_currentVideoIndex + 1} dari ${_videos.length} • $_selectedQuality',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.secondaryColor,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.primaryColor, size: 20),
            tooltip: 'Buka di Pemutar Eksternal (VLC/MX Player)',
            onPressed: _openInExternalPlayer,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
            tooltip: 'Muat Ulang Video',
            onPressed: _initPlayer,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Mendekripsi & Memuat Stream Video Cosplay...',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_rounded, size: 48, color: Colors.white38),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchVideos,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // 1. AREA PEMUTAR VIDEO (16:9 / Responsive Aspect Ratio)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: _webViewController != null
                            ? WebViewWidget(controller: _webViewController!)
                            : const Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryColor),
                              ),
                      ),
                    ),

                    // 2. KONTROL PILIHAN KUALITAS (480p, 720p, 1024p, Auto)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppTheme.surfaceColor,
                      child: Row(
                        children: [
                          const Icon(Icons.hd_rounded, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Kualitas:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildQualityChip('Auto', 'Otomatis'),
                                  const SizedBox(width: 6),
                                  _buildQualityChip('480p', '480p SD'),
                                  const SizedBox(width: 6),
                                  _buildQualityChip('720p', '720p HD'),
                                  const SizedBox(width: 6),
                                  _buildQualityChip('1024p', '1024p FHD'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white10, height: 1),

                    // 3. DAFTAR EPISODE / VIDEO (JIKA ADA LEBIH DARI 1 VIDEO)
                    Expanded(
                      child: Container(
                        color: const Color(0xFF0F1015),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daftar Video (${_videos.length} Video)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Multi-Resolution HLS',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // List kartu video
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _videos.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final vid = _videos[index];
                                final isSelected = index == _currentVideoIndex;

                                return InkWell(
                                  onTap: () => _switchVideo(index),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryColor.withOpacity(0.15)
                                          : AppTheme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : Colors.white.withOpacity(0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isSelected ? Icons.play_arrow_rounded : Icons.play_arrow_outlined,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Video ${index + 1}: ${vid.title}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Resolusi: 480p • 720p • 1024p',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Memutar',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // Tombol Aksi Tambahan
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openInExternalPlayer,
                                icon: const Icon(Icons.live_tv_rounded, size: 18),
                                label: const Text('Putar di VLC / MX Player Eksternal'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.secondaryColor,
                                  side: BorderSide(color: AppTheme.secondaryColor.withOpacity(0.4)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildQualityChip(String key, String label) {
    final isSelected = _selectedQuality.toLowerCase() == key.toLowerCase();

    return GestureDetector(
      onTap: () => _switchQuality(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
