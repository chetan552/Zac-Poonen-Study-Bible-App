class Commentary {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  Commentary({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory Commentary.fromJson(Map<String, dynamic> json) {
    return Commentary(
      book: json['book'],
      chapter: json['chapter'],
      verse: json['verse'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
    };
  }
}
