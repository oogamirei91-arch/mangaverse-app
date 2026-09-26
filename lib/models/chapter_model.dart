class ChapterModel {
  final String id;
  final String chapter;
  final String? title;
  final String? volume;
  final String translatedLanguage;
  final int pagesCount;
  final String? publishAt;
  final String? scanlationGroup;

  ChapterModel({
    required this.id,
    required this.chapter,
    this.title,
    this.volume,
    required this.translatedLanguage,
    required this.pagesCount,
    this.publishAt,
    this.scanlationGroup,
  });

  String get displayName {
    String name = 'Chapter $chapter';
    if (title != null && title!.trim().isNotEmpty) {
      name += ' - $title';
    }
    return name;
  }

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};

    String? groupName;
    final relationships = json['relationships'] as List<dynamic>? ?? [];
    for (var rel in relationships) {
      if (rel['type'] == 'scanlation_group') {
        final relAttr = rel['attributes'] as Map<String, dynamic>?;
        if (relAttr != null && relAttr.containsKey('name')) {
          groupName = relAttr['name']?.toString();
        }
      }
    }

    return ChapterModel(
      id: json['id'] as String,
      chapter: attributes['chapter']?.toString() ?? '0',
      title: attributes['title']?.toString(),
      volume: attributes['volume']?.toString(),
      translatedLanguage: attributes['translatedLanguage']?.toString() ?? 'id',
      pagesCount: (attributes['pages'] as num?)?.toInt() ?? 0,
      publishAt: attributes['publishAt']?.toString(),
      scanlationGroup: groupName,
    );
  }
}
