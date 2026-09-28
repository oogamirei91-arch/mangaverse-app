class MangaModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final int? year;
  final String? coverFileName;
  final List<String> tags;
  final String? author;

  final String? directCoverUrl;
  final String serverType; // 'mangadex' | 'suwayomi'
  final String? sourceId;

  MangaModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.year,
    this.coverFileName,
    this.tags = const [],
    this.author,
    this.directCoverUrl,
    this.serverType = 'mangadex',
    this.sourceId,
  });

  /// Generate URL Cover
  String get coverUrl {
    if (directCoverUrl != null && directCoverUrl!.isNotEmpty) {
      return directCoverUrl!;
    }
    if (coverFileName == null || coverFileName!.isEmpty) {
      return 'https://via.placeholder.com/256x360.png?text=No+Cover';
    }
    // Menggunakan thumbnail 256px agar hemat memori dan cepat dimuat
    return 'https://uploads.mangadex.org/covers/$id/$coverFileName.256.jpg';
  }

  /// Cover HQ untuk halaman detail
  String get coverUrlOriginal {
    if (directCoverUrl != null && directCoverUrl!.isNotEmpty) {
      return directCoverUrl!;
    }
    if (coverFileName == null || coverFileName!.isEmpty) {
      return 'https://via.placeholder.com/512x720.png?text=No+Cover';
    }
    return 'https://uploads.mangadex.org/covers/$id/$coverFileName.512.jpg';
  }

  factory MangaModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    
    // 1. Ekstraksi Judul (Utamakan EN, ID, JA-RO, atau judul pertama yang ada)
    final titleMap = attributes['title'] as Map<String, dynamic>? ?? {};
    String parsedTitle = titleMap['en'] ??
        titleMap['id'] ??
        titleMap['ja-ro'] ??
        titleMap['ja'] ??
        (titleMap.isNotEmpty ? titleMap.values.first.toString() : 'Tanpa Judul');

    // 2. Ekstraksi Sinopsis
    final descMap = attributes['description'] as Map<String, dynamic>? ?? {};
    String? parsedDesc = descMap['id'] ?? descMap['en'] ?? (descMap.isNotEmpty ? descMap.values.first.toString() : null);

    // 3. Ekstraksi Tags/Genre
    final tagList = attributes['tags'] as List<dynamic>? ?? [];
    List<String> parsedTags = [];
    for (var tag in tagList) {
      final tagAttr = tag['attributes'] as Map<String, dynamic>? ?? {};
      final tagNameMap = tagAttr['name'] as Map<String, dynamic>? ?? {};
      if (tagNameMap.containsKey('en')) {
        parsedTags.add(tagNameMap['en'].toString());
      }
    }

    // 4. Ekstraksi Cover File Name & Author dari relationships jika ada
    String? coverFile;
    String? authorName;
    final relationships = json['relationships'] as List<dynamic>? ?? [];
    for (var rel in relationships) {
      if (rel['type'] == 'cover_art') {
        final relAttr = rel['attributes'] as Map<String, dynamic>?;
        if (relAttr != null && relAttr.containsKey('fileName')) {
          coverFile = relAttr['fileName']?.toString();
        }
      } else if (rel['type'] == 'author' || rel['type'] == 'artist') {
        final relAttr = rel['attributes'] as Map<String, dynamic>?;
        if (relAttr != null && relAttr.containsKey('name')) {
          authorName = relAttr['name']?.toString();
        }
      }
    }

    return MangaModel(
      id: json['id'] as String,
      title: parsedTitle,
      description: parsedDesc,
      status: attributes['status']?.toString() ?? 'unknown',
      year: attributes['year'] as int?,
      coverFileName: coverFile,
      tags: parsedTags,
      author: authorName,
    );
  }
}
