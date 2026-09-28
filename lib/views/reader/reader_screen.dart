import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chapter_model.dart';
import '../../models/manga_model.dart';
import '../../providers/library_provider.dart';
import '../../providers/manga_provider.dart';
import '../../providers/reader_provider.dart';
import '../../services/suwayomi_service.dart';
import '../video/cosplay_video_player_screen.dart';

class ReaderScreen extends StatefulWidget {
  final ChapterModel chapter;
  final String mangaTitle;
  final String? mangaId;
  final String? mangaCoverUrl;
  final List<ChapterModel>? chapters;

  const ReaderScreen({
    super.key,
    required this.chapter,
    required this.mangaTitle,
    this.mangaId,
    this.mangaCoverUrl,
    this.chapters,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  late ScrollController _scrollController;
  late ChapterModel _currentChapter;
  List<ChapterModel> _allChapters = [];
  bool _isLoadingNextChapter = false;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _pageController = PageController();
    _scrollController = ScrollController();

    if (widget.chapters != null && widget.chapters!.isNotEmpty) {
      _allChapters = List.from(widget.chapters!);
    }

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mangaProvider = context.read<MangaProvider>();
      if (_allChapters.isEmpty && widget.mangaId != null) {
        _fetchChapterList(mangaProvider.suwayomiUrl);
      }
      await _loadCurrentChapterPages();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Deteksi jika user scroll ke bagian paling bawah (ambang batas 24px)
    if (currentScroll >= maxScroll - 24 && maxScroll > 100) {
      if (_nextChapter != null && !_isLoadingNextChapter) {
        _loadNextChapter();
      }
    }
  }

  Future<void> _fetchChapterList(String suwayomiUrl) async {
    try {
      final chs = await SuwayomiService().getMangaChapters(suwayomiUrl, widget.mangaId!);
      if (mounted) {
        setState(() {
          _allChapters = chs;
        });
      }
    } catch (_) {}
  }

  List<ChapterModel> get _sortedChaptersAsc {
    final list = List<ChapterModel>.from(_allChapters);
    list.sort((a, b) {
      final numA = double.tryParse(a.chapter) ?? (a.index?.toDouble() ?? 0.0);
      final numB = double.tryParse(b.chapter) ?? (b.index?.toDouble() ?? 0.0);
      if (numA != numB) return numA.compareTo(numB);
      return (a.index ?? 0).compareTo(b.index ?? 0);
    });
    return list;
  }

  ChapterModel? get _nextChapter {
    final sorted = _sortedChaptersAsc;
    if (sorted.isEmpty) return null;

    final idx = sorted.indexWhere((c) => c.id == _currentChapter.id);
    if (idx != -1 && idx + 1 < sorted.length) {
      return sorted[idx + 1];
    }

    final curNum = double.tryParse(_currentChapter.chapter);
    if (curNum != null) {
      for (final ch in sorted) {
        final chNum = double.tryParse(ch.chapter);
        if (chNum != null && chNum > curNum) {
          return ch;
        }
      }
    }
    return null;
  }

  bool get _isLastChapter {
    if (_allChapters.isEmpty) return false;
    return _nextChapter == null;
  }

  Future<void> _loadCurrentChapterPages() async {
    final reader = context.read<ReaderProvider>();
    final mangaProvider = context.read<MangaProvider>();

    await reader.loadChapter(
      _currentChapter.id,
      chapterIndex: _currentChapter.index,
      mangaId: widget.mangaId ?? _currentChapter.mangaId,
      serverType: _currentChapter.serverType,
      suwayomiUrl: mangaProvider.suwayomiUrl,
    );

    _saveProgress(1, reader.totalPages);
  }

  Future<void> _loadNextChapter() async {
    final next = _nextChapter;
    if (next == null || _isLoadingNextChapter) return;

    setState(() {
      _isLoadingNextChapter = true;
      _currentChapter = next;
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    await _loadCurrentChapterPages();

    if (mounted) {
      setState(() {
        _isLoadingNextChapter = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Membuka ${next.displayName}...'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _saveProgress(int page, int total) {
    if (widget.mangaId != null && total > 0) {
      context.read<LibraryProvider>().updateReadingProgress(
        mangaId: widget.mangaId!,
        mangaTitle: widget.mangaTitle,
        coverUrl: widget.mangaCoverUrl ?? '',
        chapterId: _currentChapter.id,
        chapterIndex: _currentChapter.index,
        chapterNumber: _currentChapter.chapter,
        chapterTitle: _currentChapter.title,
        pageNumber: page,
        totalPages: total,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
                                _loadCurrentChapterPages();
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

  /// Mode Webtoon: Scroll Vertikal Cepat dengan Pre-fetching 2500px dan Auto-load Next Chapter di Ujung Bawah
  Widget _buildWebtoonView(ReaderProvider reader) {
    final hasFooter = reader.pageUrls.isNotEmpty;
    final totalCount = reader.pageUrls.length + (hasFooter ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      cacheExtent: 2500,
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == reader.pageUrls.length) {
          return _buildChapterEndFooter(reader);
        }

        final url = reader.pageUrls[index];
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.fitWidth,
          memCacheWidth: 1080,
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
    final hasFooter = reader.pageUrls.isNotEmpty;
    final totalCount = reader.pageUrls.length + (hasFooter ? 1 : 0);

    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (BuildContext context, int index) {
        if (index == reader.pageUrls.length) {
          return PhotoViewGalleryPageOptions.customChild(
            child: Center(
              child: SingleChildScrollView(
                child: _buildChapterEndFooter(reader),
              ),
            ),
          );
        }

        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(
            reader.pageUrls[index],
            maxWidth: 1080,
          ),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.5,
          heroAttributes: PhotoViewHeroAttributes(tag: 'page_$index'),
        );
      },
      itemCount: totalCount,
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      pageController: _pageController,
      onPageChanged: (index) {
        final page = index + 1;
        reader.setCurrentPage(page);
        if (index < reader.pageUrls.length) {
          _saveProgress(page, reader.totalPages);
        }
      },
      reverse: reader.readerMode == ReaderMode.mangaRTL,
    );
  }

  /// Komponen Footer di Akhir Halaman: Navigasi Chapter Berikutnya atau Badge END
  Widget _buildChapterEndFooter(ReaderProvider reader) {
    if (_isLoadingNextChapter) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        color: const Color(0xFF0F0F12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Memuat ${_nextChapter?.displayName ?? "Chapter Selanjutnya"}...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLastChapter) {
      // Tampilan jika chapter sudah habis (Tamat / END)
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        color: const Color(0xFF0D0D0F),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3366), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3366).withOpacity(0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                '— END —',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chapter Sudah Habis (Tamat)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda telah menyelesaikan chapter terakhir dari komik ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali ke Detail'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    final nextCh = _nextChapter;
    if (nextCh != null) {
      // Tampilan jika ada chapter berikutnya
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        color: const Color(0xFF111114),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_downward_rounded, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'Akhir dari ${_currentChapter.displayName}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Gulir ke bawah untuk membuka chapter berikutnya',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNextChapter,
              icon: const Icon(Icons.skip_next_rounded, size: 20),
              label: Text('Buka ${nextCh.displayName}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
                    _currentChapter.displayName,
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
            // Tombol Tonton Video Cosplay jika tersedia
            if (widget.mangaTitle.toLowerCase().contains('cosplay') ||
                widget.mangaTitle.toLowerCase().contains('video') ||
                _currentChapter.url.contains('cosplaytele')) ...[
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE63946).withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                ),
                tooltip: 'Tonton Video Cosplay (480p - 1024p)',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CosplayVideoPlayerScreen(
                        manga: MangaModel(
                          id: widget.mangaId ?? widget.mangaTitle,
                          title: widget.mangaTitle,
                          status: 'ongoing',
                          realUrl: _currentChapter.url,
                          directCoverUrl: widget.mangaCoverUrl,
                        ),
                        chapterRealUrl: _currentChapter.url,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 2),
            ],
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
