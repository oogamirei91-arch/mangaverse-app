class ChapterModel {
  final String id;
  final String chapter;
  final String? title;
  final String? volume;
  final String translatedLanguage;
  final int pagesCount;
  final String? publishAt;
  final String? scanlationGroup;
  final String? mangaId;
  final int? index;
  final bool isRead;
  final bool isBookmarked;
  final String serverType;

  ChapterModel({
    required this.id,
    required this.chapter,
    this.title,
    this.volume,
    this.translatedLanguage = 'id',
    this.pagesCount = 0,
    this.publishAt,
    this.scanlationGroup,
    this.mangaId,
    this.index,
    this.isRead = false,
    this.isBookmarked = false,
    this.serverType = 'suwayomi',
  });

  int get chapterIndex => index ?? int.tryParse(id) ?? 1;

  String get displayName {
    if (title != null && title!.trim().isNotEmpty) {
      if (title!.toLowerCase().startsWith('chapter') || title!.toLowerCase().startsWith('ch.')) {
        return title!;
      }
      return 'Ch. $chapter - $title';
    }
    return 'Chapter $chapter';
  }

  factory ChapterModel.fromSuwayomi(Map<String, dynamic> json, {String? mangaId}) {
    final chId = (json['id'] ?? '').toString();
    final chNum = (json['chapterNumber'] ?? '0').toString();
    final chName = json['name']?.toString() ?? 'Chapter $chNum';
    final scanlator = json['scanlator']?.toString();
    final pageCount = (json['pageCount'] as num?)?.toInt() ?? 0;
    final uploadDate = json['uploadDate'];
    final rawIndex = json['index'];
    final parsedIndex = (rawIndex is num)
        ? rawIndex.toInt()
        : int.tryParse(rawIndex?.toString() ?? '');

    return ChapterModel(
      id: chId,
      chapter: chNum,
      title: chName,
      translatedLanguage: json['lang']?.toString() ?? 'all',
      pagesCount: pageCount > 0 ? pageCount : 0,
      publishAt: uploadDate != null ? uploadDate.toString() : null,
      scanlationGroup: scanlator,
      mangaId: mangaId ?? (json['mangaId']?.toString()),
      index: parsedIndex,
      isRead: json['read'] == true,
      isBookmarked: json['bookmarked'] == true,
      serverType: 'suwayomi',
    );
  }

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel.fromSuwayomi(json);
  }
}
