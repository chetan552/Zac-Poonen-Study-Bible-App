import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible.dart';
import '../models/commentary.dart';
import '../services/bible_service.dart';

final bibleServiceProvider = Provider<BibleService>((ref) => BibleService());

final booksProvider = FutureProvider<List<Book>>((ref) async {
  final service = ref.watch(bibleServiceProvider);
  await service.loadData();
  return service.getBooks();
});

final chaptersProvider = FutureProvider<List<int>>((ref) {
  final book = ref.watch(selectedBookProvider);
  final books = ref.watch(booksProvider);
  return books.maybeWhen(
    data: (data) {
      if (book == null) return [];
      final selectedBook = data.firstWhere((b) => b.name == book, orElse: () => Book(name: '', chaptersCount: 0));
      if (selectedBook.name.isEmpty) return [];
      return List.generate(selectedBook.chaptersCount, (i) => i + 1);
    },
    orElse: () => [],
  );
});

final selectedBookProvider = StateProvider<String?>((ref) => 'Genesis');
final selectedChapterProvider = StateProvider<int?>((ref) => 1);
final selectedVerseProvider = StateProvider<int?>((ref) => 1);

// Provider to load last read position
final lastReadPositionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.watch(bibleServiceProvider);
  return await service.loadLastReadLocation();
});

// Provider to initialize default position
final initialPositionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final lastPosition = await ref.watch(lastReadPositionProvider.future);
  if (lastPosition != null) {
    return lastPosition;
  } else {
    // Return default position
    return {
      'book': 'Genesis',
      'chapter': 1,
      'verse': 1,
    };
  }
});

final versesProvider = FutureProvider<List<Verse>>((ref) {
  final book = ref.watch(selectedBookProvider);
  final chapter = ref.watch(selectedChapterProvider);
  // Ensure books are loaded first (which calls loadData)
  final booksAsync = ref.watch(booksProvider);

  return booksAsync.maybeWhen(
    data: (_) {
      if (book == null || chapter == null) return Future.value([]);
      final service = ref.watch(bibleServiceProvider);
      return Future.value(service.getVerses(book, chapter));
    },
    orElse: () => Future.value([]),
  );
});

final verseNumbersProvider = FutureProvider<List<int>>((ref) {
  final verses = ref.watch(versesProvider);
  return verses.maybeWhen(
    data: (data) => data.map((v) => v.verse).toList(),
    orElse: () => [],
  );
});

final selectedVerseTextProvider = FutureProvider<String?>((ref) {
  final book = ref.watch(selectedBookProvider);
  final chapter = ref.watch(selectedChapterProvider);
  final verse = ref.watch(selectedVerseProvider);
  // Ensure books are loaded first
  final booksAsync = ref.watch(booksProvider);

  return booksAsync.maybeWhen(
    data: (_) {
      if (book == null || chapter == null || verse == null) return Future.value(null);
      final service = ref.watch(bibleServiceProvider);
      final verses = service.getVerses(book, chapter);
      try {
        final selectedVerse = verses.firstWhere((v) => v.verse == verse);
        return Future.value(selectedVerse.text);
      } catch (e) {
        return Future.value(null);
      }
    },
    orElse: () => Future.value(null),
  );
});

final commentaryProvider = FutureProvider<Commentary?>((ref) {
  final book = ref.watch(selectedBookProvider);
  final chapter = ref.watch(selectedChapterProvider);
  final verse = ref.watch(selectedVerseProvider);
  // Ensure books are loaded first
  final booksAsync = ref.watch(booksProvider);

  return booksAsync.maybeWhen(
    data: (_) {
      if (book == null || chapter == null || verse == null) return Future.value(null);
      final service = ref.watch(bibleServiceProvider);
      return service.getCommentary(book, chapter, verse);
    },
    orElse: () => Future.value(null),
  );
});

final currentTabProvider = StateProvider<int>((ref) => 0);

// Full screen mode provider
final isFullScreenProvider = StateProvider<bool>((ref) => false);

// Theme provider for managing light/dark mode
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      final useSystemTheme = prefs.getBool('use_system_theme') ?? true;

      if (useSystemTheme) {
        state = ThemeMode.system;
      } else {
        state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (e) {
      // Keep system theme as default
      print('Error loading theme preference: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = themeMode;
    await _saveThemePreference(themeMode);
  }

  Future<void> _saveThemePreference(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (themeMode == ThemeMode.system) {
        await prefs.setBool('use_system_theme', true);
      } else {
        await prefs.setBool('use_system_theme', false);
        await prefs.setBool('is_dark_mode', themeMode == ThemeMode.dark);
      }
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }
}
