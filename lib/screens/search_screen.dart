import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bible_provider.dart';
import '../services/bible_service.dart';
import '../widgets/custom_app_bar.dart';

class SearchResult {
  final String type; // 'bible' or 'commentary'
  final String book;
  final int chapter;
  final int verse;
  final String text;

  SearchResult({
    required this.type,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResult> _results = [];
  bool _searchBible = true;
  bool _searchCommentary = true;
  bool _isLoading = false;

  void _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final service = ref.read(bibleServiceProvider);
    List<SearchResult> allResults = [];

    // Search Bible if enabled
    if (_searchBible) {
      final bibleResults = service.searchBible(query).map((verse) => SearchResult(
        type: 'bible',
        book: verse.book,
        chapter: verse.chapter,
        verse: verse.verse,
        text: verse.text,
      )).toList();
      allResults.addAll(bibleResults);
    }

    // Search Commentary if enabled
    if (_searchCommentary) {
      final commentaryResults = service.searchCommentary(query).map((commentary) => SearchResult(
        type: 'commentary',
        book: commentary.book,
        chapter: commentary.chapter,
        verse: commentary.verse,
        text: commentary.text,
      )).toList();
      allResults.addAll(commentaryResults);
    }

    setState(() {
      _results = allResults;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Search',
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      color: theme.colorScheme.onBackground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search for verses, words, or phrases...',
                      hintStyle: TextStyle(
                        fontFamily: 'Georgia',
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              onPressed: () {
                                _controller.clear();
                                setState(() {
                                  _results = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _search,
                  ),
                ),
                const SizedBox(height: 16),
                // Search Filters
                Text(
                  'Search in:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Bible Filter
                    FilterChip(
                      label: Text(
                        'Bible',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: _searchBible
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      selected: _searchBible,
                      onSelected: (selected) {
                        setState(() {
                          _searchBible = selected;
                        });
                        if (_controller.text.isNotEmpty) {
                          _search(_controller.text);
                        }
                      },
                      backgroundColor: theme.colorScheme.surface,
                      selectedColor: theme.colorScheme.primary,
                      checkmarkColor: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    // Commentary Filter
                    FilterChip(
                      label: Text(
                        'Commentary',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: _searchCommentary
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      selected: _searchCommentary,
                      onSelected: (selected) {
                        setState(() {
                          _searchCommentary = selected;
                        });
                        if (_controller.text.isNotEmpty) {
                          _search(_controller.text);
                        }
                      },
                      backgroundColor: theme.colorScheme.surface,
                      selectedColor: theme.colorScheme.primary,
                      checkmarkColor: theme.colorScheme.onPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Searching...',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty && _controller.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontFamily: 'Georgia',
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try different keywords or check your filters',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Georgia',
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Start searching',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontFamily: 'Georgia',
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter keywords to find verses and commentary',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'Georgia',
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final result = _results[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: result.type == 'bible'
                                              ? theme.colorScheme.primary.withOpacity(0.1)
                                              : theme.colorScheme.secondary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          result.type == 'bible' ? 'Bible' : 'Commentary',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: result.type == 'bible'
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.secondary,
                                            fontFamily: 'Georgia',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${result.book} ${result.chapter}:${result.verse}',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontFamily: 'Georgia',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      result.text,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontFamily: 'Georgia',
                                        height: 1.5,
                                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  onTap: () {
                                    ref.read(selectedBookProvider.notifier).state = result.book;
                                    ref.read(selectedChapterProvider.notifier).state = result.chapter;
                                    ref.read(selectedVerseProvider.notifier).state = result.verse;
                                    ref.read(currentTabProvider.notifier).state = 0; // Switch to Bible tab
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
