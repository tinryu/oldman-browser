import 'package:flutter/material.dart';

class SpeedDial extends StatefulWidget {
  final List<Map<String, String>> bookmarks;
  final Function(String) onUrlSelected;

  const SpeedDial({
    super.key,
    required this.bookmarks,
    required this.onUrlSelected,
  });

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.bookmarks.isEmpty) {
      return Container(
        color: theme.colorScheme.surface.withValues(alpha: 0.98),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmarks_outlined, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                'No bookmarks yet',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Add bookmarks to see them here',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    const int itemsPerPage = 8; // 2 rows of 4
    final int pageCount = (widget.bookmarks.length / itemsPerPage).ceil();

    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.98),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 240, // Slightly more height for the grid content
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: pageCount,
                  itemBuilder: (context, pageIndex) {
                    final int startIndex = pageIndex * itemsPerPage;
                    final int endIndex =
                        (startIndex + itemsPerPage) < widget.bookmarks.length
                        ? (startIndex + itemsPerPage)
                        : widget.bookmarks.length;
                    final List<Map<String, String>> pageItems = widget.bookmarks
                        .sublist(startIndex, endIndex);

                    return Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: pageItems.map((bookmark) {
                            final url = bookmark['url'] ?? '';
                            final title = bookmark['title'] ?? 'Unknown';
                            // Basic favicon fetcher
                            final uri = Uri.tryParse(url);
                            final faviconUrl = uri != null
                                ? 'https://www.google.com/s2/favicons?sz=64&domain_url=${uri.host}'
                                : '';

                            return GestureDetector(
                              onTap: () => widget.onUrlSelected(url),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.98),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: faviconUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                faviconUrl,
                                                width: 32,
                                                height: 32,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.public,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                      size: 32,
                                                    ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.public,
                                              color:
                                                  theme.colorScheme.onSurface,
                                              size: 32,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (pageCount > 1) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pageCount, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
