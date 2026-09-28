import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chapter_model.dart';
import '../../providers/library_provider.dart';
import '../../providers/manga_provider.dart';
import '../../providers/reader_provider.dart';

class ReaderScreen extends StatefulWidget {
  final ChapterModel chapter;
  final String mangaTitle;
  final String? mangaId;
  final String? mangaCoverUrl;

  const ReaderScreen({
    super.key,
    required this.chapter,
    required this.mangaTitle,
    this.mangaId,
    this.mangaCoverUrl,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reader = context.read<ReaderProvider>();
      final mangaProvider = context.read<MangaProvider>();
      await reader.loadChapter(
        widget.chapter.id,
        mangaId: widget.mangaId ?? widget.chapter.mangaId,
        serverType: widget.chapter.serverType,
        suwayomiUrl: mangaProvider.suwayomiUrl,
      );

      // Simpan progres awal saat chapter berhasil dimuat
      _saveProgress(1, reader.totalPages);
    });
  }

  void _saveProgress(int page, int total) {
    if (widget.mangaId != null && total > 0) {
      context.read<LibraryProvider>().updateReadingProgress(
        mangaId: widget.mangaId!,
        mangaTitle: widget.mangaTitle,
        coverUrl: widget.mangaCoverUrl ?? '',
        chapterId: widget.chapter.id,
        chapterNumber: widget.chapter.chapter,
        chapterTitle: widget.chapter.title,
        pageNumber: page,
        totalPages: total,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: reader.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Memuat halaman komik (Mode Cepat)...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            )
          : reader.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 48),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal Membuka Chapter',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reader.errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                              label: const Text('Kembali'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                final mangaProvider = context.read<MangaProvider>();
                                reader.loadChapter(
                                  widget.chapter.id,
                                  mangaId: widget.mangaId,
                                  serverType: widget.chapter.serverType,
                                  suwayomiUrl: mangaProvider.suwayomiUrl,
                                );
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // 1. Reader Content Canvas
                    GestureDetector(
                      onTap: () => reader.toggleControls(),
                      child: reader.readerMode == ReaderMode.webtoon
                          ? _buildWebtoonView(reader)
                          : _buildMangaPagedView(reader),
                    ),

                    // 2. Top App Bar Overlay
                    if (reader.showControls) _buildTopOverlay(context, reader),

                    // 3. Bottom Controls Overlay
                    if (reader.showControls) _buildBottomOverlay(context, reader),
                  ],
                ),
    );
  }

  /// Mode Webtoon: Scroll Vertikal Cepat dengan Pre-fetching 2500px dan MemCache
  Widget _buildWebtoonView(ReaderProvider reader) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      cacheExtent: 2500, // Preload gambar ke depan agar tidak blank saat scroll cepat
      itemCount: reader.pageUrls.length,
      itemBuilder: (context, index) {
        final url = reader.pageUrls[index];
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.fitWidth,
          memCacheWidth: 1080, // Optimasi RAM agar decode gambar 4x lebih cepat
          placeholder: (context, url) => Container(
            height: 350,
            color: const Color(0xFF141414),
            child: Center(
              child: Text(
                'Halaman ${index + 1}',
                style: const TextStyle(color: Colors.white24, fontSize: 14),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: const Color(0xFF1F1F1F),
            child: const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.redAccent),
            ),
          ),
        );
      },
    );
  }

  /// Mode Manga Klasik: Horizontal Right-To-Left dengan Pinch-to-Zoom
  Widget _buildMangaPagedView(ReaderProvider reader) {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(
            reader.pageUrls[index],
            maxWidth: 1080, // Optimasi memori
          ),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.5,
          heroAttributes: PhotoViewHeroAttributes(tag: 'page_$index'),
        );
      },
      itemCount: reader.pageUrls.length,
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      pageController: _pageController,
      onPageChanged: (index) {
        final page = index + 1;
        reader.setCurrentPage(page);
        _saveProgress(page, reader.totalPages);
      },
      reverse: reader.readerMode == ReaderMode.mangaRTL,
    );
  }

  Widget _buildTopOverlay(BuildContext context, ReaderProvider reader) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 8,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.mangaTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.chapter.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            // Tombol Toggle Kualitas Cepat (Data Saver) vs Asli (HQ)
            IconButton(
              icon: Icon(
                reader.isDataSaver ? Icons.bolt_rounded : Icons.hd_rounded,
                color: reader.isDataSaver ? const Color(0xFFFFD166) : Colors.white,
              ),
              tooltip: reader.isDataSaver ? 'Mode Cepat Aktif (Klik untuk Mode HQ)' : 'Mode HQ Aktif (Klik untuk Mode Cepat)',
              onPressed: () {
                reader.toggleDataSaver();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      reader.isDataSaver ? 'Beralih ke Mode Cepat (Hemat Kuota)' : 'Beralih ke Kualitas Asli (HQ)',
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
            // Toggle Mode Baca (Webtoon / Manga Paged)
            IconButton(
              icon: Icon(
                reader.readerMode == ReaderMode.webtoon
                    ? Icons.view_day_rounded
                    : Icons.menu_book_rounded,
                color: Colors.white,
              ),
              tooltip: reader.readerMode == ReaderMode.webtoon
                  ? 'Ubah ke Mode Manga (Horizontal)'
                  : 'Ubah ke Mode Webtoon (Vertikal)',
              onPressed: () {
                reader.setReaderMode(
                  reader.readerMode == ReaderMode.webtoon
                      ? ReaderMode.mangaRTL
                      : ReaderMode.webtoon,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(BuildContext context, ReaderProvider reader) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 16,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reader.readerMode == ReaderMode.webtoon
                      ? 'Mode Webtoon (Vertikal)'
                      : 'Mode Manga (Kanan ke Kiri)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white60),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${reader.pageUrls.length} Halaman ${reader.isDataSaver ? "• ⚡ Cepat" : ""}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
