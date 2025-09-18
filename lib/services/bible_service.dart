import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/bible.dart';
import '../models/commentary.dart';

class BibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  List<Book> _books = [];
  List<Verse> _verses = [];
  List<Commentary> _commentaries = [];

  // Book abbreviation to full name mapping
  static const Map<String, String> _bookAbbreviations = {
    'GEN': 'Genesis',
    'EXO': 'Exodus',
    'LEV': 'Leviticus',
    'NUM': 'Numbers',
    'DEU': 'Deuteronomy',
    'JOS': 'Joshua',
    'JDG': 'Judges',
    'RUT': 'Ruth',
    '1SA': '1 Samuel',
    '2SA': '2 Samuel',
    '1KI': '1 Kings',
    '2KI': '2 Kings',
    '1CH': '1 Chronicles',
    '2CH': '2 Chronicles',
    'EZR': 'Ezra',
    'NEH': 'Nehemiah',
    'EST': 'Esther',
    'JOB': 'Job',
    'PSA': 'Psalms',
    'PRO': 'Proverbs',
    'ECC': 'Ecclesiastes',
    'SNG': 'Song of Solomon',
    'ISA': 'Isaiah',
    'JER': 'Jeremiah',
    'LAM': 'Lamentations',
    'EZK': 'Ezekiel',
    'DAN': 'Daniel',
    'HOS': 'Hosea',
    'JOL': 'Joel',
    'AMO': 'Amos',
    'OBA': 'Obadiah',
    'JON': 'Jonah',
    'MIC': 'Micah',
    'NAM': 'Nahum',
    'HAB': 'Habakkuk',
    'ZEP': 'Zephaniah',
    'HAG': 'Haggai',
    'ZEC': 'Zechariah',
    'MAL': 'Malachi',
    'MAT': 'Matthew',
    'MRK': 'Mark',
    'LUK': 'Luke',
    'JHN': 'John',
    'ACT': 'Acts',
    'ROM': 'Romans',
    '1CO': '1 Corinthians',
    '2CO': '2 Corinthians',
    'GAL': 'Galatians',
    'EPH': 'Ephesians',
    'PHP': 'Philippians',
    'COL': 'Colossians',
    '1TH': '1 Thessalonians',
    '2TH': '2 Thessalonians',
    '1TI': '1 Timothy',
    '2TI': '2 Timothy',
    'TIT': 'Titus',
    'PHM': 'Philemon',
    'HEB': 'Hebrews',
    'JAS': 'James',
    '1PE': '1 Peter',
    '2PE': '2 Peter',
    '1JN': '1 John',
    '2JN': '2 John',
    '3JN': '3 John',
    'JUD': 'Jude',
    'REV': 'Revelation',
  };

  Future<void> loadData() async {
    if (_books.isNotEmpty) return;

    // Load Bible from NASB2020.json
    final bibleString = await rootBundle.loadString('assets/NASB2020.json');
    final bibleData = json.decode(bibleString) as Map<String, dynamic>;

    // Convert NASB2020 format to our model format
    _books = [];
    _verses = [];

    bibleData.forEach((bookAbbrev, chaptersData) {
      final fullBookName = _bookAbbreviations[bookAbbrev] ?? bookAbbrev;
      final chaptersMap = chaptersData as Map<String, dynamic>;
      final chapterCount = chaptersMap.length;

      // Create Book
      _books.add(Book(
        name: fullBookName,
        chaptersCount: chapterCount,
      ));

      // Create Verses for this book
      chaptersMap.forEach((chapterStr, versesList) {
        final chapter = int.parse(chapterStr);
        final verses = versesList as List<dynamic>;

        for (int i = 0; i < verses.length; i++) {
          _verses.add(Verse(
            book: fullBookName,
            chapter: chapter,
            verse: i + 1, // Verses are 1-indexed
            text: verses[i] as String,
          ));
        }
      });
    });

    // Load Commentary from assets
    final commentaryString = await rootBundle.loadString('assets/commentary.json');
    final commentaryData = json.decode(commentaryString) as List;
    _commentaries = commentaryData.map((c) => Commentary.fromJson(c)).toList();

    // Load additional commentaries from saved file
    await _loadSavedCommentaries();
  }

  List<Book> getBooks() {
    return _books;
  }

  List<Verse> getVerses(String book, int chapter) {
    return _verses.where((v) => v.book == book && v.chapter == chapter).toList();
  }

  Future<Commentary?> getCommentary(String book, int chapter, int verse) async {
    // First check if commentary already exists
    try {
      final existing = _commentaries.firstWhere(
        (c) => c.book == book && c.chapter == chapter && c.verse == verse,
      );
      return existing;
    } catch (e) {
      // No existing commentary, generate one
      try {
        final verseText = getVerseText(book, chapter, verse);
        if (verseText == null) return null;

        final generatedCommentary = await _generateGPTCommentary(book, chapter, verse, verseText);
        if (generatedCommentary != null) {
          // Add to in-memory list
          _commentaries.add(generatedCommentary);
          // Save to file
          await _saveCommentaryToFile(generatedCommentary);
          return generatedCommentary;
        }
      } catch (e) {
        print('Error generating commentary: $e');
      }
      return null;
    }
  }

  List<Verse> searchBible(String query) {
    return _verses.where((v) => v.text.toLowerCase().contains(query.toLowerCase())).toList();
  }

  List<Commentary> searchCommentary(String query) {
    return _commentaries.where((c) => c.text.toLowerCase().contains(query.toLowerCase())).toList();
  }

  String? getVerseText(String book, int chapter, int verse) {
    try {
      final verseObj = _verses.firstWhere(
        (v) => v.book == book && v.chapter == chapter && v.verse == verse,
      );
      return verseObj.text;
    } catch (e) {
      return null;
    }
  }

  Future<Commentary?> _generateGPTCommentary(String book, int chapter, int verse, String verseText) async {
    try {
      // Get API key from environment variables
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('Error: OPENAI_API_KEY not found in environment variables');
        return null;
      }
      const apiUrl = 'https://api.openai.com/v1/chat/completions';

      final prompt = 'According to Zac Poonen, what does $book $chapter:$verse mean? The verse text is: "$verseText"';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.0, // Zero temperature for consistent results
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final generatedText = data['choices'][0]['message']['content'] as String;

        return Commentary(
          book: book,
          chapter: chapter,
          verse: verse,
          text: 'Zac Poonen commentary: $generatedText',
        );
      } else {
        print('GPT API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling GPT API: $e');
      return null;
    }
  }

  // Save last read location
  Future<void> saveLastReadLocation(String book, int chapter, int verse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_book', book);
      await prefs.setInt('last_chapter', chapter);
      await prefs.setInt('last_verse', verse);
    } catch (e) {
      print('Error saving last read location: $e');
    }
  }

  // Load last read location
  Future<Map<String, dynamic>?> loadLastReadLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final book = prefs.getString('last_book');
      final chapter = prefs.getInt('last_chapter');
      final verse = prefs.getInt('last_verse');

      if (book != null && chapter != null && verse != null) {
        return {
          'book': book,
          'chapter': chapter,
          'verse': verse,
        };
      }
      return null;
    } catch (e) {
      print('Error loading last read location: $e');
      return null;
    }
  }

  Future<void> _loadSavedCommentaries() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/commentary.json';
      final file = File(filePath);

      if (await file.exists()) {
        final content = await file.readAsString();
        final savedCommentaries = json.decode(content) as List;
        final commentaries = savedCommentaries.map((c) => Commentary.fromJson(c)).toList();
        _commentaries.addAll(commentaries);
      }
    } catch (e) {
      print('Error loading saved commentaries: $e');
    }
  }

  Future<void> _saveCommentaryToFile(Commentary commentary) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/commentary.json';

      // Read existing commentary file or create new one
      List<Map<String, dynamic>> commentaryList = [];
      final file = File(filePath);

      if (await file.exists()) {
        final existingContent = await file.readAsString();
        commentaryList = List<Map<String, dynamic>>.from(json.decode(existingContent));
      }

      // Add new commentary
      commentaryList.add(commentary.toJson());

      // Write back to file
      await file.writeAsString(json.encode(commentaryList));
    } catch (e) {
      print('Error saving commentary to file: $e');
    }
  }
}
