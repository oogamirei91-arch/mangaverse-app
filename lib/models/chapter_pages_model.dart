class ChapterPagesModel {
  final String baseUrl;
  final List<String> pageUrls;

  ChapterPagesModel({
    required this.baseUrl,
    required this.pageUrls,
  });

  /// Daftar URL gambar lengkap untuk dibaca di Reader
  List<String> getPageUrls({bool isDataSaver = false}) {
    return pageUrls;
  }

  factory ChapterPagesModel.fromUrls({
    required String baseUrl,
    required List<String> urls,
  }) {
    return ChapterPagesModel(
      baseUrl: baseUrl,
      pageUrls: urls,
    );
  }
}
