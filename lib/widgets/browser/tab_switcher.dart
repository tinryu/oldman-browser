import 'package:flutter/material.dart';
import '../../models/browser_tab.dart';

class TabSwitcher extends StatelessWidget {
  final List<BrowserTab> tabs;
  final int currentTabIndex;
  final Function(int) onTabSelected;
  final Function(int) onTabClosed;
  final VoidCallback onAddNewTab;
  final Function({required bool isIncognito}) onAddCustomTab;
  final VoidCallback onClearAll;
  final VoidCallback onToggle;
  final TextEditingController searchController;

  const TabSwitcher({
    super.key,
    required this.tabs,
    required this.currentTabIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onAddNewTab,
    required this.onAddCustomTab,
    required this.onClearAll,
    required this.onToggle,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTabs = tabs.where((tab) {
      final searchQuery = searchController.text.toLowerCase();
      return tab.title.toLowerCase().contains(searchQuery) ||
          tab.url.toLowerCase().contains(searchQuery);
    }).toList();

    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.98),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tabs.length.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.tab,
                          color: theme.colorScheme.onSurface,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    color: theme.colorScheme.onSurface,
                    onPressed: onClearAll,
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: searchController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search your tabs',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.05,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // New Tab Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNewTabButton(
                  context: context,
                  label: "New Tab",
                  icon: Icons.tab_rounded,
                  color: theme.colorScheme.primary,
                  onPressed: onAddNewTab,
                ),
                const SizedBox(width: 12),
                _buildNewTabButton(
                  context: context,
                  label: "Incognito",
                  icon: Icons.shield_moon_outlined,
                  color: Colors.purple,
                  onPressed: () => onAddCustomTab(isIncognito: true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tabs Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width < 800
                      ? 2
                      : 4,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredTabs.length,
                itemBuilder: (context, index) {
                  final tab = filteredTabs[index];
                  final tabIndex = tabs.indexOf(tab);
                  final isActive = tabIndex == currentTabIndex;

                  return _TabCard(
                    tab: tab,
                    isActive: isActive,
                    index: index,
                    onTap: () => onTabSelected(tabIndex),
                    onClose: () => onTabClosed(tabIndex),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTabButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 160,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabCard extends StatelessWidget {
  final BrowserTab tab;
  final bool isActive;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabCard({
    required this.tab,
    required this.isActive,
    required this.index,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: tab.isIncognito
                ? (theme.brightness == Brightness.dark
                      ? const Color(0xFF2B2B2B)
                      : Colors.purple.shade50)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? (tab.isIncognito
                        ? Colors.purpleAccent
                        : theme.colorScheme.primary)
                  : theme.dividerColor.withValues(alpha: 0.1),
              width: isActive ? 3 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color:
                          (tab.isIncognito
                                  ? Colors.purpleAccent
                                  : theme.colorScheme.primary)
                              .withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: tab.isIncognito
                            ? Colors.purple
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        tab.isIncognito
                            ? Icons.shield_moon_outlined
                            : Icons.webhook_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tab.title.isEmpty ? 'New tab' : tab.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Body (Preview)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      tab.isIncognito
                          ? Icons.shield_moon_outlined
                          : Icons.tab_outlined,
                      size: 32,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
