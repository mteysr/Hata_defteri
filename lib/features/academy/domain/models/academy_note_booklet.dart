class AcademyNoteBooklet {
  final String title;
  final String category;
  final String description;
  final int pageCount;
  final String assetPrefix;
  final String fileExtension;
  final String? initialSearchQuery;

  const AcademyNoteBooklet({
    required this.title,
    required this.category,
    required this.description,
    required this.pageCount,
    required this.assetPrefix,
    required this.fileExtension,
    this.initialSearchQuery,
  });

  AcademyNoteBooklet copyWith({
    String? initialSearchQuery,
  }) {
    return AcademyNoteBooklet(
      title: title,
      category: category,
      description: description,
      pageCount: pageCount,
      assetPrefix: assetPrefix,
      fileExtension: fileExtension,
      initialSearchQuery: initialSearchQuery ?? this.initialSearchQuery,
    );
  }
}

const List<AcademyNoteBooklet> kAcademyNoteBooklets = [
  AcademyNoteBooklet(
    title: 'Tarih Çıkması Muhtemel Sorular ve Notlar',
    category: 'Tarih',
    description: 'KPSS Tarih sınavında çıkması yüksek olasılıklı nokta atışı soru ve notlar.',
    pageCount: 9,
    assetPrefix: 'assets/notes/tarih/notes_page-',
    fileExtension: 'png',
  ),
  AcademyNoteBooklet(
    title: 'Kampüs Coğrafya Ders Notları',
    category: 'Coğrafya',
    description: 'KPSS Coğrafya sınavı için tüm konuları içeren eksiksiz ünite konu anlatım notları.',
    pageCount: 167,
    assetPrefix: 'assets/notes/cografya/notes_page-',
    fileExtension: 'jpg',
  ),
  AcademyNoteBooklet(
    title: 'Kampüs Vatandaşlık Ders Notları',
    category: 'Vatandaşlık',
    description: 'KPSS Vatandaşlık sınavı için tüm konuları içeren eksiksiz ünite konu anlatım notları.',
    pageCount: 55,
    assetPrefix: 'assets/notes/vatandaslik/notes_page-',
    fileExtension: 'jpg',
  ),
];
