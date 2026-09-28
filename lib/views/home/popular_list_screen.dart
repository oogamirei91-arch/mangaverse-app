import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/manga_model.dart';
import '../../providers/manga_provider.dart';
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
  final SuwayomiService _suwayomiService = SuwayomiService();
  final ScrollController _scrollController = ScrollController();

  List<MangaModel> _mangaList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;

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
      _page = 1;
      _hasMore = true;
      _mangaList.clear();
    }

    setState(() => _isLoading = true);

    try {
      final mangaProvider = context.read<MangaProvider>();
      List<MangaModel> newItems = [];

      if (mangaProvider.suwayomiSourceId != null) {
        newItems = await _suwayomiService.getPopularManga(
          mangaProvider.suwayomiUrl,
          mangaProvider.suwayomiSourceId!,
          page: _page,
        );
      }

      setState(() {
        if (newItems.isEmpty) {
          _hasMore = false;
        } else {
          _mangaList.addAll(newItems);
          _page++;
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _getTitle() {
    final mangaProvider = context.read<MangaProvider>();
    return '🔥 Populer (${mangaProvider.suwayomiSourceName ?? 'Suwayomi'})';
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
        child: _mangaList.isEmpty && _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _mangaList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_stories_rounded, size: 54, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada data komik populer.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _mangaList.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _mangaList.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
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
