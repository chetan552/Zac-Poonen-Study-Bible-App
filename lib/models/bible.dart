class Book {
  final String name;
  final int chaptersCount;

  Book({required this.name, required this.chaptersCount});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      name: json['name'],
      chaptersCount: json['chapters'],
    );
  }
}

class Verse {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  Verse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
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
