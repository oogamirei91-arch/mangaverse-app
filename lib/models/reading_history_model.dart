class ReadingHistoryModel {
  final String mangaId;
  final String mangaTitle;
  final String coverUrl;
  final String chapterId;
  final String chapterNumber;
  final String? chapterTitle;
  final int pageNumber;
  final int totalPages;
  final DateTime lastReadAt;

  ReadingHistoryModel({
    required this.mangaId,
    required this.mangaTitle,
    required this.coverUrl,
    required this.chapterId,
    required this.chapterNumber,
    this.chapterTitle,
    required this.pageNumber,
    required this.totalPages,
    required this.lastReadAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'mangaId': mangaId,
      'mangaTitle': mangaTitle,
      'coverUrl': coverUrl,
      'chapterId': chapterId,
      'chapterNumber': chapterNumber,
      'chapterTitle': chapterTitle,
      'pageNumber': pageNumber,
      'totalPages': totalPages,
      'lastReadAt': lastReadAt.toIso8601String(),
    };
  }

  factory ReadingHistoryModel.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryModel(
      mangaId: json['mangaId'] as String,
      mangaTitle: json['mangaTitle'] as String,
      coverUrl: json['coverUrl'] as String,
      chapterId: json['chapterId'] as String,
      chapterNumber: json['chapterNumber'] as String,
      chapterTitle: json['chapterTitle'] as String?,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      lastReadAt: DateTime.tryParse(json['lastReadAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
