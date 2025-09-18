import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bible_provider.dart';
import '../providers/database_provider.dart';
import '../models/bookmark.dart';
import '../models/note.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/verse_card.dart';
import '../widgets/custom_dropdown.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return AlertDialog(
      title: Text(
        'Settings',
        style: TextStyle(fontFamily: 'Georgia'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class BibleReaderScreen extends ConsumerStatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _expandedVerse;
  int? _selectedVerse;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToVerse(int verse) {
    // Assuming each verse card has height ~120, adjust as needed
    final index = verse - 1;
    _scrollController.animateTo(
      index * 120.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final chaptersAsync = ref.watch(chaptersProvider);
    final versesAsync = ref.watch(versesProvider);
    final verseNumbersAsync = ref.watch(verseNumbersProvider);
    final selectedBook = ref.watch(selectedBookProvider);
    final selectedChapter = ref.watch(selectedChapterProvider);
    final selectedVerse = ref.watch(selectedVerseProvider);
    final isFullScreen = ref.watch(isFullScreenProvider);

    // Load saved position if available (for returning users)
    ref.listen(initialPositionProvider, (previous, next) {
      next?.when(
        data: (position) {
          // Only update if different from current defaults
          if (position['book'] != 'Genesis' || position['chapter'] != 1 || position['verse'] != 1) {
            ref.read(selectedBookProvider.notifier).state = position['book'];
            ref.read(selectedChapterProvider.notifier).state = position['chapter'];
            ref.read(selectedVerseProvider.notifier).state = position['verse'];
          }
        },
        error: (error, stack) => print('Error loading saved position: $error'),
        loading: () {},
      );
    });

    ref.listen(selectedVerseProvider, (previous, next) {
      if (next != null) {
        setState(() {
          _selectedVerse = next;
        });
        // Save the current reading position
        _saveCurrentPosition();
      }
    });

    return Scaffold(
      appBar: isFullScreen ? null : CustomAppBar(
        title: selectedBook != null && selectedChapter != null
            ? '$selectedBook $selectedChapter'
            : 'Bible Reader',
        actions: [
          IconButton(
            icon: Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: () => ref.read(isFullScreenProvider.notifier).state = !isFullScreen,
            tooltip: isFullScreen ? 'Exit Full Screen' : 'Enter Full Screen',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => _showQuickActions(context),
            tooltip: 'Quick Actions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Bar with Dropdowns - Hidden in full screen
          if (!isFullScreen) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Book Dropdown
                Expanded(
                  flex: 3,
                  child: booksAsync.when(
                    data: (books) => CustomDropdown<String>(
                      hint: 'Select Book',
                      value: selectedBook,
                      label: 'Book',
                      items: books.map((book) {
                        return DropdownMenuItem<String>(
                          value: book.name,
                          child: Text(
                            book.name,
                            style: const TextStyle(fontFamily: 'Georgia'),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        ref.read(selectedBookProvider.notifier).state = value;
                        ref.read(selectedChapterProvider.notifier).state = 1;
                        ref.read(selectedVerseProvider.notifier).state = 1;
                        setState(() {
                          _selectedVerse = 1;
                        });
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const Text('Error'),
                  ),
                ),
                const SizedBox(width: 12),
                // Chapter Dropdown
                Expanded(
                  flex: 2,
                  child: selectedBook != null
                      ? chaptersAsync.when(
                          data: (chapters) => chapters.isNotEmpty
                              ? CustomDropdown<int>(
                                  hint: '',
                                  value: selectedChapter,
                                  label: 'Chapter',
                                  items: chapters.map((chapter) {
                                    return DropdownMenuItem<int>(
                                      value: chapter,
                                      child: Text(
                                        chapter.toString(),
                                        style: const TextStyle(fontFamily: 'Georgia'),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    ref.read(selectedChapterProvider.notifier).state = value;
                                    ref.read(selectedVerseProvider.notifier).state = null;
                                    setState(() {
                                      _selectedVerse = null;
                                    });
                                  },
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: const Text(
                                    'No chapters',
                                    style: TextStyle(
                                      fontFamily: 'Georgia',
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => const Text('Error'),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: const Text(
                            'Select book',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Verse Dropdown
                Expanded(
                  flex: 2,
                  child: selectedBook != null && selectedChapter != null
                      ? verseNumbersAsync.when(
                          data: (verseNumbers) => verseNumbers.isNotEmpty
                              ? CustomDropdown<int>(
                                  hint: '',
                                  value: selectedVerse,
                                  label: 'Verse',
                                  items: verseNumbers.map((verse) {
                                    return DropdownMenuItem<int>(
                                      value: verse,
                                      child: Text(
                                        verse.toString(),
                                        style: const TextStyle(fontFamily: 'Georgia'),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    ref.read(selectedVerseProvider.notifier).state = value;
                                    setState(() {
                                      _selectedVerse = value;
                                    });
                                    // Scroll to selected verse when using dropdown
                                    if (value != null) {
                                      _scrollToVerse(value);
                                    }
                                  },
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: const Text(
                                    'No verses',
                                    style: TextStyle(
                                      fontFamily: 'Georgia',
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => const Text('Error'),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: const Text(
                            'Select chapter',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Verses List - Takes full screen in full screen mode
          Expanded(
            child: GestureDetector(
              onTap: isFullScreen ? () => ref.read(isFullScreenProvider.notifier).state = false : null,
              child: versesAsync.when(
                data: (verses) => ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: isFullScreen ? 24 : 8, // More padding in full screen
                  ),
                  itemCount: verses.length,
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    final isExpanded = _expandedVerse == verse.verse;
                    final isSelected = _selectedVerse == verse.verse;

                    return VerseCard(
                      verseNumber: verse.verse,
                      verseText: verse.text,
                      isSelected: isSelected,
                      isHighlighted: isExpanded,
                      isLoading: isExpanded ? _isCommentaryLoading() : false,
                      commentary: isExpanded ? _getCommentaryForExpandedVerse() : null,
                      onTap: () {
                        setState(() {
                          _expandedVerse = isExpanded ? null : verse.verse;
                          _selectedVerse = verse.verse;
                        });
                        // Update the selected verse provider to trigger commentary fetch
                        ref.read(selectedVerseProvider.notifier).state = verse.verse;
                      },
                      onLongPress: () => _showOptionsDialog(context, verse),
                    );
                  },
                ),
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading verses...',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading verses',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getCommentaryForExpandedVerse() {
    final commentaryAsync = ref.watch(commentaryProvider);
    return commentaryAsync.maybeWhen(
      data: (commentary) => commentary?.text,
      orElse: () => null,
    );
  }

  bool _isCommentaryLoading() {
    final commentaryAsync = ref.watch(commentaryProvider);
    return commentaryAsync.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
  }

  void _saveCurrentPosition() {
    final selectedBook = ref.read(selectedBookProvider);
    final selectedChapter = ref.read(selectedChapterProvider);
    final selectedVerse = ref.read(selectedVerseProvider);

    if (selectedBook != null && selectedChapter != null && selectedVerse != null) {
      final service = ref.read(bibleServiceProvider);
      service.saveLastReadLocation(selectedBook, selectedChapter, selectedVerse);
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  context,
                  Icons.bookmark_add,
                  'Add Bookmark',
                  () => _showAddBookmarkDialog(context),
                ),
                _buildQuickActionButton(
                  context,
                  Icons.note_add,
                  'Add Note',
                  () => _showAddNoteDialog(context),
                ),
                _buildQuickActionButton(
                  context,
                  Icons.share,
                  'Share',
                  () => _shareCurrentVerse(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              Navigator.of(context).pop();
              onPressed();
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showAddBookmarkDialog(BuildContext context) {
    final selectedBook = ref.read(selectedBookProvider);
    final selectedChapter = ref.read(selectedChapterProvider);
    final selectedVerse = ref.read(selectedVerseProvider);

    if (selectedBook == null || selectedChapter == null || selectedVerse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a verse first')),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Bookmark',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Optional note',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final bookmark = Bookmark(
                book: selectedBook,
                chapter: selectedChapter,
                verse: selectedVerse,
                note: controller.text.isEmpty ? null : controller.text,
              );
              await ref.read(databaseServiceProvider).addBookmark(bookmark);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final selectedBook = ref.read(selectedBookProvider);
    final selectedChapter = ref.read(selectedChapterProvider);
    final selectedVerse = ref.read(selectedVerseProvider);

    if (selectedBook == null || selectedChapter == null || selectedVerse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a verse first')),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Note',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your note',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final note = Note(
                book: selectedBook,
                chapter: selectedChapter,
                verse: selectedVerse,
                text: controller.text,
              );
              await ref.read(databaseServiceProvider).addNote(note);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _shareCurrentVerse(BuildContext context) {
    final selectedBook = ref.read(selectedBookProvider);
    final selectedChapter = ref.read(selectedChapterProvider);
    final selectedVerse = ref.read(selectedVerseProvider);

    if (selectedBook == null || selectedChapter == null || selectedVerse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a verse first')),
      );
      return;
    }

    // For now, just show a snackbar. In a real app, you'd use the share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing: $selectedBook $selectedChapter:$selectedVerse')),
    );
  }

  void _showOptionsDialog(BuildContext context, dynamic verse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Verse Options',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_add),
              title: const Text('Bookmark'),
              onTap: () => _addBookmark(context, verse),
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Add Note'),
              onTap: () => _addNote(context, verse),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => _shareVerse(context, verse),
            ),
          ],
        ),
      ),
    );
  }

  void _addBookmark(BuildContext context, dynamic verse) {
    Navigator.of(context).pop();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bookmark'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Optional note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final bookmark = Bookmark(
                book: verse.book,
                chapter: verse.chapter,
                verse: verse.verse,
                note: controller.text.isEmpty ? null : controller.text,
              );
              await ref.read(databaseServiceProvider).addBookmark(bookmark);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _shareVerse(BuildContext context, dynamic verse) {
    Navigator.of(context).pop();
    // For now, just show a snackbar. In a real app, you'd use the share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing: ${verse.book} ${verse.chapter}:${verse.verse}')),
    );
  }

  void _addNote(BuildContext context, dynamic verse) {
    Navigator.of(context).pop();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Note text'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final note = Note(
                book: verse.book,
                chapter: verse.chapter,
                verse: verse.verse,
                text: controller.text,
              );
              await ref.read(databaseServiceProvider).addNote(note);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
