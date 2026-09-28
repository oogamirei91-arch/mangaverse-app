import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/manga_model.dart';
import '../../providers/manga_provider.dart';
import '../../services/mangadex_service.dart';
import '../../services/suwayomi_service.dart';
import '../../widgets/manga_card.dart';

class PopularListScreen extends StatefulWidget {
  final String comicType;
  final String language;

  const PopularListScreen({
    super.key,
    required this.comicType,
    required this.language,
  });

  @override
  State<PopularListScreen> createState() => _PopularListScreenState();
}

class _PopularListScreenState extends State<PopularListScreen> {
  final MangaDexService _service = MangaDexService();
  final SuwayomiService _suwayomiService = SuwayomiService();
  final ScrollController _scrollController = ScrollController();

  List<MangaModel> _mangaList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 24;

  @override
  void initState() {
    super.initState();
    _fetchPopularManga();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400 &&
          !_isLoading &&
          _hasMore) {
        _fetchPopularManga();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPopularManga({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _offset = 0;
      _hasMore = true;
      _mangaList.clear();
    }

    setState(() => _isLoading = true);

    try {
      final mangaProvider = context.read<MangaProvider>();
      List<MangaModel> newItems;

      if (mangaProvider.isSuwayomiActive && mangaProvider.suwayomiSourceId != null) {
        final page = (_offset ~/ _limit) + 1;
        newItems = await _suwayomiService.getPopularManga(
          mangaProvider.suwayomiUrl,
          mangaProvider.suwayomiSourceId!,
          page: page,
        );
      } else {
        final lang = widget.language == 'all' ? null : widget.language;
        newItems = await _service.getPopularManga(
          limit: _limit,
          offset: _offset,
          language: lang,
          comicType: widget.comicType,
          contentRatings: mangaProvider.currentContentRatings,
        );
      }

      setState(() {
        if (newItems.length < _limit) {
          _hasMore = false;
        }
        _mangaList.addAll(newItems);
        _offset += newItems.length;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _getTitle() {
    final mangaProvider = context.read<MangaProvider>();
    if (mangaProvider.isSuwayomiActive) {
      return '🔥 Populer (${mangaProvider.suwayomiSourceName ?? 'Suwayomi'})';
    }
    switch (widget.comicType) {
      case 'manhwa':
        return '🔥 Manhwa Terpopuler';
      case 'manga':
        return '🔥 Manga Terpopuler';
      case 'manhua':
        return '🔥 Manhua Terpopuler';
      default:
        return '🔥 Komik Paling Populer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          _getTitle(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchPopularManga(refresh: true),
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.surfaceColor,
        child: _mangaList.isEmpty && _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _mangaList.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada komik populer ditemukan.',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: _mangaList.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _mangaList.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }
                      return MangaCard(manga: _mangaList[index]);
                    },
                  ),
      ),
    );
  }
}
