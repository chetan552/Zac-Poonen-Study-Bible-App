class Note {
  final int? id;
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final DateTime createdAt;

  Note({
    this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      book: json['book'],
      chapter: json['chapter'],
      verse: json['verse'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
