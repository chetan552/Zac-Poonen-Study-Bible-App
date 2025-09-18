import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bible_provider.dart';
import '../providers/database_provider.dart';
import '../models/bookmark.dart';
import '../models/note.dart';
import '../widgets/custom_app_bar.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Notes',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOptions(context),
            tooltip: 'Add New',
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    context,
                    'Bookmarks',
                    0,
                    _tabController.index == 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    context,
                    'Notes',
                    1,
                    _tabController.index == 1,
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookmarksTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String title, int index, bool isSelected) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.index = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksTab() {
    final theme = Theme.of(context);

    return FutureBuilder<List<Bookmark>>(
      future: ref.read(databaseServiceProvider).getBookmarks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading bookmarks...',
                  style: TextStyle(fontFamily: 'Georgia'),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading bookmarks',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        }
        final bookmarks = snapshot.data ?? [];
        if (bookmarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No bookmarks yet',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Georgia',
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the bookmark icon on verses to save them',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Georgia',
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  '${bookmark.book} ${bookmark.chapter}:${bookmark.verse}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: bookmark.note != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          bookmark.note!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Georgia',
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : null,
                trailing: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () => _showBookmarkOptions(context, bookmark),
                ),
                onTap: () {
                  ref.read(selectedBookProvider.notifier).state = bookmark.book;
                  ref.read(selectedChapterProvider.notifier).state = bookmark.chapter;
                  ref.read(selectedVerseProvider.notifier).state = bookmark.verse;
                  ref.read(currentTabProvider.notifier).state = 0;
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotesTab() {
    final theme = Theme.of(context);

    return FutureBuilder<List<Note>>(
      future: ref.read(databaseServiceProvider).getNotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading notes...',
                  style: TextStyle(fontFamily: 'Georgia'),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading notes',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        }
        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notes yet',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Georgia',
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Long press on verses to add notes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Georgia',
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.note,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
                title: Text(
                  '${note.book} ${note.chapter}:${note.verse}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    note.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Georgia',
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () => _showNoteOptionsDialog(context, note),
                ),
                onTap: () {
                  ref.read(selectedBookProvider.notifier).state = note.book;
                  ref.read(selectedChapterProvider.notifier).state = note.chapter;
                  ref.read(selectedVerseProvider.notifier).state = note.verse;
                  ref.read(currentTabProvider.notifier).state = 0;
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteBookmarkDialog(BuildContext context, Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark'),
        content: const Text('Are you sure you want to delete this bookmark?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(databaseServiceProvider).deleteBookmark(bookmark.id!);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark deleted')),
              );
              setState(() {}); // Refresh
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNoteOptionsDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Edit'),
              onTap: () => _editNote(context, note),
            ),
            ListTile(
              title: const Text('Delete'),
              onTap: () => _deleteNote(context, note),
            ),
          ],
        ),
      ),
    );
  }

  void _editNote(BuildContext context, Note note) {
    Navigator.of(context).pop();
    final controller = TextEditingController(text: note.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(databaseServiceProvider).updateNote(note.id!, controller.text);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note updated')),
              );
              setState(() {});
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(BuildContext context, Note note) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Note',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        content: Text(
          'Are you sure you want to delete this note?',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(databaseServiceProvider).deleteNote(note.id!);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note deleted')),
              );
              setState(() {});
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    final theme = Theme.of(context);

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
              'Add New',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAddOptionButton(
                  context,
                  Icons.bookmark_add,
                  'Bookmark',
                  'Save current verse',
                  () => _quickBookmark(context),
                ),
                _buildAddOptionButton(
                  context,
                  Icons.note_add,
                  'Note',
                  'Add to current verse',
                  () => _quickNote(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOptionButton(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onPressed();
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'Georgia',
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _quickBookmark(BuildContext context) {
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
          'Quick Bookmark',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$selectedBook $selectedChapter:$selectedVerse',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Optional note',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
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
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _quickNote(BuildContext context) {
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
          'Quick Note',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$selectedBook $selectedChapter:$selectedVerse',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter your note',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
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
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showBookmarkOptions(BuildContext context, Bookmark bookmark) {
    final theme = Theme.of(context);

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
              'Bookmark Options',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                Icons.edit,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Edit Note',
                style: TextStyle(fontFamily: 'Georgia'),
              ),
              onTap: () => _editBookmarkNote(context, bookmark),
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete Bookmark',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () => _deleteBookmark(context, bookmark),
            ),
          ],
        ),
      ),
    );
  }

  void _editBookmarkNote(BuildContext context, Bookmark bookmark) {
    Navigator.of(context).pop();
    final controller = TextEditingController(text: bookmark.note ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Bookmark Note',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Bookmark note',
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
              await ref.read(databaseServiceProvider).updateBookmarkNote(
                bookmark.id!,
                controller.text.isEmpty ? null : controller.text,
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark updated')),
              );
              setState(() {});
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteBookmark(BuildContext context, Bookmark bookmark) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Bookmark',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        content: Text(
          'Are you sure you want to delete this bookmark?',
          style: TextStyle(fontFamily: 'Georgia'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(databaseServiceProvider).deleteBookmark(bookmark.id!);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark deleted')),
              );
              setState(() {});
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
