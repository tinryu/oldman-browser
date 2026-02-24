import 'package:flutter/material.dart';

class AddressBar extends StatelessWidget {
  final TextEditingController textController;
  final Function(String) onSubmitted;
  final VoidCallback onReload;
  final VoidCallback onBookmark;
  final double loadingProgress;
  final bool isIncognito;
  final bool isInitialized;

  const AddressBar({
    super.key,
    required this.textController,
    required this.onSubmitted,
    required this.onReload,
    required this.onBookmark,
    required this.loadingProgress,
    this.isIncognito = false,
    this.isInitialized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loadingProgress > 0 && loadingProgress < 1)
          LinearProgressIndicator(
            value: loadingProgress,
            minHeight: 2,
            backgroundColor: Colors.transparent,
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    controller: textController,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search or enter URL',
                      hintStyle: const TextStyle(fontSize: 14),
                      isDense: true,
                      contentPadding: const EdgeInsets.only(left: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isIncognito
                          ? Colors.purple.withValues(alpha: 0.15)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      prefixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isIncognito ? Icons.security : Icons.bookmarks,
                          size: 18,
                          color: isIncognito ? Colors.purple : null,
                        ),
                        onPressed: onBookmark,
                      ),
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: onReload,
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    onSubmitted: onSubmitted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
