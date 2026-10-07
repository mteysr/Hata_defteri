import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/academy_note_booklet.dart';

class AcademyNotesViewerScreen extends StatefulWidget {
  final AcademyNoteBooklet booklet;

  const AcademyNotesViewerScreen({super.key, required this.booklet});

  @override
  State<AcademyNotesViewerScreen> createState() => _AcademyNotesViewerScreenState();
}

class _AcademyNotesViewerScreenState extends State<AcademyNotesViewerScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  
  // Search state
  List<Map<String, dynamic>> _searchIndex = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSearchIndex().then((_) {
      if (widget.booklet.initialSearchQuery != null) {
        setState(() {
          _isSearching = true;
          _searchController.text = widget.booklet.initialSearchQuery!;
        });
        _performSearch(widget.booklet.initialSearchQuery!);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchIndex() async {
    try {
      final dirPath = widget.booklet.assetPrefix.substring(0, widget.booklet.assetPrefix.lastIndexOf('/') + 1);
      final String categoryKey = widget.booklet.category == 'Coğrafya'
          ? 'cografya'
          : (widget.booklet.category == 'Vatandaşlık' ? 'vatandaslik' : 'tarih');
      final jsonStr = await rootBundle.loadString('${dirPath}${categoryKey}_notes_index.json');
      final List<dynamic> jsonList = json.decode(jsonStr);
      setState(() {
        _searchIndex = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      debugPrint('Error loading search index: $e');
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _goToPage(int page) {
    if (page >= 0 && page < widget.booklet.pageCount) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();

    for (var item in _searchIndex) {
      final fullText = (item['fullText'] as String).toLowerCase();
      
      // Simple Turkish localization character replacement for better search matches
      final cleanFullText = _normalizeString(fullText);
      final cleanQuery = _normalizeString(lowerQuery);

      if (cleanFullText.contains(cleanQuery)) {
        final index = cleanFullText.indexOf(cleanQuery);
        final start = (index - 30).clamp(0, fullText.length);
        final end = (index + cleanQuery.length + 50).clamp(0, fullText.length);
        var snippet = fullText.substring(start, end).replaceAll('\n', ' ');
        if (start > 0) snippet = '...' + snippet;
        if (end < fullText.length) snippet = snippet + '...';

        results.add({
          'pageNumber': item['pageNumber'] as int,
          'snippet': snippet,
        });
      }
    }

    setState(() {
      _searchResults = results;
    });
  }

  String _normalizeString(String str) {
    return str
        .replaceAll('i̇', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i');
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchResults = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        iconTheme: const IconThemeData(color: Colors.white),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Notlarda ara (örn: Amasya, Sivas)...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                onChanged: _performSearch,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.booklet.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_currentPage + 1} / ${widget.booklet.pageCount} Sayfa',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main PDF PageView reader
          PageView.builder(
            controller: _pageController,
            itemCount: widget.booklet.pageCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final String pageStr = widget.booklet.category != 'Tarih'
                  ? (index + 1).toString().padLeft(3, '0')
                  : (index + 1).toString();
              final String assetPath = '${widget.booklet.assetPrefix}$pageStr.${widget.booklet.fileExtension}';

              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sayfa görseli yüklenemedi.\n($assetPath)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // Search results overlay
          if (_isSearching && _searchController.text.trim().isNotEmpty)
            Container(
              color: Colors.black.withOpacity(0.9),
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        'Aramanızla eşleşen sonuç bulunamadı.',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        final res = _searchResults[index];
                        return ListTile(
                          title: Text(
                            'Sayfa ${res['pageNumber']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              res['snippet'],
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                          onTap: () {
                            _goToPage(res['pageNumber'] - 1);
                            _toggleSearch(); // Close search view and show selected page
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                    ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page indicator slider
              Row(
                children: [
                  const Text(
                    '1',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: theme.colorScheme.primary,
                        overlayColor: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                      child: Slider(
                        min: 0,
                        max: (widget.booklet.pageCount - 1).toDouble(),
                        value: _currentPage.toDouble(),
                        divisions: widget.booklet.pageCount > 1
                            ? widget.booklet.pageCount - 1
                            : 1,
                        onChanged: (val) {
                          _goToPage(val.toInt());
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${widget.booklet.pageCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              // Navigation Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: _currentPage > 0
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                  ),
                  Text(
                    'Sayfa ${_currentPage + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onPressed: _currentPage < widget.booklet.pageCount - 1
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
