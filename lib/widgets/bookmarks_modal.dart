import 'package:flutter/material.dart';

class BookmarksModal extends StatelessWidget {
  final List<Map<String, String>> bookmarks;
  final String currentUrl;
  final Function(String) onUrlSelected;
  final VoidCallback onAddBookmark;
  final Function(String) onRemoveBookmark;

  const BookmarksModal({
    super.key,
    required this.bookmarks,
    required this.currentUrl,
    required this.onUrlSelected,
    required this.onAddBookmark,
    required this.onRemoveBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.bookmarks, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Bookmarks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onAddBookmark,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Current'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: bookmarks.isEmpty
                ? const Center(
                    child: Text(
                      'No bookmarks yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: bookmarks.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      final url = bookmark['url'] ?? '';
                      final title = bookmark['title'] ?? url;
                      final isCurrent = url == currentUrl;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Text(
                            title.isNotEmpty ? title[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            color: isCurrent ? Colors.blueAccent : Colors.white,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          url,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => onRemoveBookmark(url),
                        ),
                        onTap: () => onUrlSelected(url),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
