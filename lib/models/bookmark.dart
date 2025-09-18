class Bookmark {
  final int? id;
  final String book;
  final int chapter;
  final int verse;
  final String? note;
  final DateTime createdAt;

  Bookmark({
    this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      book: json['book'],
      chapter: json['chapter'],
      verse: json['verse'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
