class ChapterPagesModel {
  final String baseUrl;
  final String hash;
  final List<String> data;
  final List<String> dataSaver;

  ChapterPagesModel({
    required this.baseUrl,
    required this.hash,
    required this.data,
    required this.dataSaver,
  });

  /// Daftar URL gambar lengkap untuk dibaca di Reader
  List<String> getPageUrls({bool isDataSaver = false}) {
    final list = isDataSaver ? dataSaver : data;
    final qualityFolder = isDataSaver ? 'data-saver' : 'data';
    return list.map((fileName) => '$baseUrl/$qualityFolder/$hash/$fileName').toList();
  }

  factory ChapterPagesModel.fromJson(Map<String, dynamic> json) {
    final baseUrl = json['baseUrl'] as String;
    final chapter = json['chapter'] as Map<String, dynamic>;
    final hash = chapter['hash'] as String;
    final data = (chapter['data'] as List<dynamic>).map((e) => e.toString()).toList();
    final dataSaver = (chapter['dataSaver'] as List<dynamic>).map((e) => e.toString()).toList();

    return ChapterPagesModel(
      baseUrl: baseUrl,
      hash: hash,
      data: data,
      dataSaver: dataSaver,
    );
  }
}
