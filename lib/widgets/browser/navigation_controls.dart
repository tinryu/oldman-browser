import 'package:flutter/material.dart';

class BrowserNavigationControls extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onAddTab;
  final VoidCallback onToggleTabSwitcher;
  final VoidCallback onMenu;
  final int tabCount;
  final int detectedVideosCount;
  final bool isIncognito;

  const BrowserNavigationControls({
    super.key,
    required this.onHome,
    required this.onBack,
    required this.onForward,
    required this.onAddTab,
    required this.onToggleTabSwitcher,
    required this.onMenu,
    required this.tabCount,
    this.detectedVideosCount = 0,
    this.isIncognito = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      color: theme.colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            color: theme.colorScheme.onSurface,
            icon: const Icon(Icons.home, size: 24),
            onPressed: onHome,
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: onBack,
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            icon: const Icon(Icons.arrow_forward, size: 24),
            onPressed: onForward,
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            icon: const Icon(Icons.add, size: 24),
            onPressed: onAddTab,
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isIncognito
                        ? Colors.purple.withValues(alpha: 0.2)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isIncognito
                          ? Colors.purple
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    tabCount.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: onToggleTabSwitcher,
            tooltip: 'Tab Switcher',
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: 'Menu',
            icon: Badge(
              padding: const EdgeInsets.all(2),
              offset: const Offset(10, -6),
              label: Text(
                detectedVideosCount.toString(),
                style: TextStyle(
                  color: detectedVideosCount == 0
                      ? Colors.transparent
                      : Colors.white,
                ),
              ),
              backgroundColor: detectedVideosCount == 0
                  ? Colors.transparent
                  : Colors.redAccent,
              child: Icon(
                Icons.menu,
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
            ),
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }
}
