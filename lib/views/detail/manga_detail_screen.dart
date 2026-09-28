import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chapter_model.dart';
import '../../models/manga_model.dart';
import '../../providers/chapter_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/manga_provider.dart';
import '../reader/reader_screen.dart';
import '../video/cosplay_video_player_screen.dart';

class MangaDetailScreen extends StatefulWidget {
  final MangaModel manga;

  const MangaDetailScreen({super.key, required this.manga});

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  bool _isSynopsisExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mangaProvider = context.read<MangaProvider>();
      context.read<ChapterProvider>().fetchChapters(
        widget.manga.id,
        suwayomiUrl: mangaProvider.suwayomiUrl,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapterProvider = context.watch<ChapterProvider>();
    final library = context.watch<LibraryProvider>();
    final isBookmarked = library.isBookmarked(widget.manga.id);
    final history = library.getHistoryForManga(widget.manga.id);

    final titleLower = widget.manga.title.toLowerCase();
    final hasCosplayOrVideo = titleLower.contains('video') ||
        titleLower.contains('photos') ||
        (widget.manga.source?.toLowerCase().contains('cosplay') ?? false) ||
        (widget.manga.source?.toLowerCase().contains('tele') ?? false);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar dengan Hero Backdrop
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (hasCosplayOrVideo) ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946).withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                  ),
                  tooltip: 'Tonton Video Cosplay',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CosplayVideoPlayerScreen(
                          manga: widget.manga,
                          chapterRealUrl: chapterProvider.chapters.isNotEmpty
                              ? chapterProvider.chapters.first.url
                              : null,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
              // Tombol Bookmark Favorit
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isBookmarked ? AppTheme.primaryColor : Colors.white,
                  ),
                ),
                tooltip: isBookmarked ? 'Hapus dari Favorit' : 'Simpan ke Favorit',
                onPressed: () async {
                  await library.toggleBookmark(widget.manga);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBookmarked
                              ? 'Dihapus dari Koleksi Favorit'
                              : 'Disimpan ke Koleksi Favorit!',
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred Background
                  CachedNetworkImage(
                    imageUrl: widget.manga.coverUrlOriginal,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppTheme.cardColor),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(color: Colors.black.withOpacity(0.65)),
                  ),

                  // Center Cover Art & Title
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cover Card
                        Hero(
                          tag: 'manga-cover-${widget.manga.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: widget.manga.coverUrl,
                              width: 110,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title & Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.manga.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (widget.manga.author != null) ...[
                                Text(
                                  widget.manga.author!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.secondaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                children: [
                                  _buildBadge(
                                    widget.manga.status.toUpperCase(),
                                    widget.manga.status.toLowerCase() == 'completed'
                                        ? const Color(0xFF06D6A0)
                                        : AppTheme.primaryColor,
                                  ),
                                  if (widget.manga.year != null) ...[
                                    const SizedBox(width: 6),
                                    _buildBadge(
                                      widget.manga.year.toString(),
                                      Colors.white24,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Body Details (Sinopsis & Chapters)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lanjutkan Membaca Banner jika sudah pernah baca
                  if (history != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.18),
                            AppTheme.secondaryColor.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lanjutkan Membaca',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Chapter ${history.chapterNumber} • Hal ${history.pageNumber}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReaderScreen(
                                    chapter: ChapterModel(
                                      id: history.chapterId,
                                      chapter: history.chapterNumber,
                                      title: history.chapterTitle,
                                      translatedLanguage: 'id',
                                      pagesCount: history.totalPages,
                                      index: history.chapterIndex,
                                    ),
                                    mangaTitle: widget.manga.title,
                                    mangaId: widget.manga.id,
                                    mangaCoverUrl: widget.manga.coverUrl,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text('Lanjut'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 🎬 BANNER TONTON VIDEO COSPLAY (JIKA TERSEDIA)
                  if (hasCosplayOrVideo) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE63946), Color(0xFF7209B7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE63946).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CosplayVideoPlayerScreen(
                                  manga: widget.manga,
                                  chapterRealUrl: chapterProvider.chapters.isNotEmpty
                                      ? chapterProvider.chapters.first.url
                                      : null,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '🎬 Tonton Video Cosplay',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '480p - 1024p',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Set ini memiliki video! Putar dengan pilihan kualitas 480p, 720p, hingga 1024p.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Tags Chips
                  if (widget.manga.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.manga.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Sinopsis
                  Text(
                    'Sinopsis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                    child: Text(
                      widget.manga.description ?? 'Belum ada sinopsis untuk komik ini.',
                      maxLines: _isSynopsisExpanded ? 100 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.6,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header Chapters & Sort Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Chapter (${chapterProvider.chapters.length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          chapterProvider.isAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: AppTheme.primaryColor,
                        ),
                        tooltip: chapterProvider.isAscending ? 'Urutan 1 ke akhir' : 'Urutan akhir ke 1',
                        onPressed: () => chapterProvider.toggleSortOrder(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // List Chapter Items
                  if (chapterProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    )
                  else if (chapterProvider.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              size: 32,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal Memuat Daftar Chapter',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            chapterProvider.errorMessage!.replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              height: 1.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              final mangaProvider = context.read<MangaProvider>();
                              chapterProvider.fetchChapters(
                                widget.manga.id,
                                suwayomiUrl: mangaProvider.suwayomiUrl,
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Coba Lagi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (chapterProvider.chapters.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 32,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum Ada Chapter Tersedia',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tidak ditemukan chapter untuk komik ini dari server Suwayomi.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              height: 1.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: chapterProvider.chapters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ch = chapterProvider.chapters[index];
                        final isLastRead = history != null && history.chapterId == ch.id;

                        return Container(
                          decoration: BoxDecoration(
                            color: isLastRead
                                ? AppTheme.primaryColor.withOpacity(0.08)
                                : AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLastRead
                                  ? AppTheme.primaryColor.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.04),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isLastRead ? AppTheme.primaryColor : Colors.white).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isLastRead ? Icons.bookmark_added_rounded : Icons.chrome_reader_mode_rounded,
                                color: isLastRead ? AppTheme.primaryColor : Colors.white70,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              ch.displayName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isLastRead ? AppTheme.primaryColor : AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${ch.translatedLanguage.toUpperCase()}${ch.scanlationGroup != null ? ' • ${ch.scanlationGroup}' : ''}${isLastRead ? ' (Terakhir Dibaca)' : ''}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReaderScreen(
                                    chapter: ch,
                                    mangaTitle: widget.manga.title,
                                    mangaId: widget.manga.id,
                                    mangaCoverUrl: widget.manga.coverUrl,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color == Colors.white24 ? Colors.white : color,
        ),
      ),
    );
  }

  Widget _buildChapterLangChip(
    BuildContext context,
    ChapterProvider chapterProvider,
    String lang,
    String label,
  ) {
    final isSelected = chapterProvider.chapterLanguage == lang;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        final mangaProvider = context.read<MangaProvider>();
        chapterProvider.changeLanguage(
          widget.manga.id,
          lang,
          suwayomiUrl: mangaProvider.suwayomiUrl,
        );
      },
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.06),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
