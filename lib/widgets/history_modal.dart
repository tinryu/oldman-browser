import 'package:flutter/material.dart';

class HistoryModal extends StatelessWidget {
  final List<Map<String, String>> history;
  final Function(String) onUrlSelected;
  final VoidCallback onClearHistory;
  final Function(int) onRemoveEntry;

  const HistoryModal({
    super.key,
    required this.history,
    required this.onUrlSelected,
    required this.onClearHistory,
    required this.onRemoveEntry,
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
                const Icon(Icons.history, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Browsing History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (history.isNotEmpty)
                  TextButton.icon(
                    onPressed: onClearHistory,
                    icon: const Icon(
                      Icons.delete_sweep,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Clear All',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      'No history yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: history.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      final url = entry['url'] ?? '';
                      final title = entry['title'] ?? 'Unknown';

                      return ListTile(
                        leading: const Icon(
                          Icons.public,
                          color: Colors.grey,
                          size: 20,
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () => onRemoveEntry(index),
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
