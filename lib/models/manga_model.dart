class MangaModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final int? year;
  final List<String> tags;
  final String? author;
  final String? directCoverUrl;
  final String? sourceId;
  final String? coverFileName;
  final String? realUrl;

  MangaModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.year,
    this.tags = const [],
    this.author,
    this.directCoverUrl,
    this.sourceId,
    this.coverFileName,
    this.realUrl,
  });

  String get url => realUrl ?? '';
  String? get source => sourceId;
  String get serverType => 'suwayomi';

  /// URL Cover thumbnail untuk card dan list
  String get coverUrl {
    if (directCoverUrl != null && directCoverUrl!.isNotEmpty) {
      return directCoverUrl!;
    }
    if (coverFileName != null && coverFileName!.isNotEmpty) {
      return coverFileName!;
    }
    return 'https://via.placeholder.com/256x360.png?text=No+Cover';
  }

  /// Cover HQ untuk halaman detail
  String get coverUrlOriginal {
    return coverUrl;
  }

  factory MangaModel.fromSuwayomi(Map<String, dynamic> json, String serverUrl, {String? defaultSourceId}) {
    final mangaId = (json['id'] ?? '').toString();
    final title = json['title']?.toString() ?? 'Tanpa Judul';
    final desc = json['description']?.toString();
    final statusRaw = json['status']?.toString().toLowerCase() ?? 'ongoing';
    final thumb = json['thumbnailUrl']?.toString();
    final sourceId = (json['sourceId'] ?? defaultSourceId)?.toString();

    String? fullCover;
    if (thumb != null && thumb.isNotEmpty) {
      if (thumb.startsWith('http://') || thumb.startsWith('https://')) {
        fullCover = thumb;
      } else {
        final cleanBase = serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl;
        final cleanThumb = thumb.startsWith('/') ? thumb : '/$thumb';
        fullCover = '$cleanBase$cleanThumb';
      }
    }

    final genreList = json['genre'] as List<dynamic>? ?? [];
    final tags = genreList.map((g) => g.toString()).toList();
    final author = json['author']?.toString() ?? json['artist']?.toString();
    final realUrl = json['realUrl']?.toString() ?? json['url']?.toString();

    return MangaModel(
      id: mangaId,
      title: title,
      description: desc,
      status: statusRaw,
      tags: tags,
      author: author,
      directCoverUrl: fullCover,
      coverFileName: fullCover,
      sourceId: sourceId,
      realUrl: realUrl,
    );
  }

  factory MangaModel.fromJson(Map<String, dynamic> json) {
    return MangaModel.fromSuwayomi(json, '');
  }
}
