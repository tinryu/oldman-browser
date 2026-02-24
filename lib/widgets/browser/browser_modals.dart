import 'package:flutter/material.dart';
import '../../models/video_item.dart';
import '../../models/menu_bottom_item.dart';
import '../../services/storage_service.dart';
import '../history_modal.dart';
import '../bookmarks_modal.dart';
import '../captured_videos_modal.dart';
import '../../screens/settings_screen.dart';

class BrowserModals {
  static void showSettingsModal({
    required BuildContext context,
    required bool isDesktopMode,
    required VoidCallback onGoHome,
    required Function({bool isIncognito}) onAddNewTab,
    required VoidCallback onClearAllData,
    required List<Map<String, String>> bookmarks,
    required List<Map<String, String>> history,
    required List<VideoItem> detectedVideos,
    required List<VideoItem> onlineVideos,
    required Function(VideoItem) onVideoCaptured,
    required Function(VideoItem) onVideoRemoved,
    required Function(List<VideoItem>) onVideosUpdated,
    required Function(int) onTabRequested,
    required Function(String) onUrlSelected,
    required String currentUrl,
    required VoidCallback onAddBookmark,
    required Function(String) onRemoveBookmark,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(28),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildSingleMenuItem(
                context: context,
                onShowBookmarks: () => showBookmarksModal(
                  context: context,
                  bookmarks: bookmarks,
                  currentUrl: currentUrl,
                  onUrlSelected: onUrlSelected,
                  onAddBookmark: onAddBookmark,
                  onRemoveBookmark: onRemoveBookmark,
                ),
                onShowHistory: () => showHistoryModal(
                  context: context,
                  history: history,
                  onUrlSelected: onUrlSelected,
                  onClearHistory: () {
                    history.clear();
                    StorageService.saveHistory(history);
                  },
                  onRemoveEntry: (index) {
                    history.removeAt(index);
                    StorageService.saveHistory(history);
                  },
                ),
                onTabRequested: onTabRequested,
              ),
              const Divider(),
              _buildGridMenu(
                context: context,
                isDesktopMode: isDesktopMode,
                onGoHome: onGoHome,
                onAddNewTab: onAddNewTab,
                onClearAllData: onClearAllData,
                onShowCapturedVideos: () => showCapturedVideosModal(
                  context: context,
                  detectedVideos: detectedVideos,
                  onlineVideos: onlineVideos,
                  onVideoCaptured: onVideoCaptured,
                  onVideoRemoved: onVideoRemoved,
                  onVideosUpdated: onVideosUpdated,
                  onTabRequested: onTabRequested,
                  onClear: () => detectedVideos.clear(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSingleMenuItem({
    required BuildContext context,
    required VoidCallback onShowBookmarks,
    required VoidCallback onShowHistory,
    required Function(int) onTabRequested,
  }) {
    final items = [
      MenuBottomItem(Icons.star, "Favorites", Colors.white, () {
        Navigator.pop(context);
        onShowBookmarks();
      }),
      MenuBottomItem(Icons.history, "History", Colors.white, () {
        Navigator.pop(context);
        onShowHistory();
      }),
      MenuBottomItem(Icons.download, "Downloads", Colors.white, () {
        Navigator.pop(context);
        onTabRequested(3);
      }),
      MenuBottomItem(Icons.settings, "Settings", Colors.white, () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      }),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map(
              (item) => InkWell(
                onTap: item.onActions,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: Colors.white, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  static Widget _buildGridMenu({
    required BuildContext context,
    required bool isDesktopMode,
    required VoidCallback onGoHome,
    required Function({bool isIncognito}) onAddNewTab,
    required VoidCallback onClearAllData,
    required VoidCallback onShowCapturedVideos,
  }) {
    final items = [
      MenuBottomItem(Icons.home, "Home", Colors.white, () {
        Navigator.pop(context);
        onGoHome();
      }),
      MenuBottomItem(Icons.security, "InPrivate Tab", Colors.white, () {
        Navigator.pop(context);
        onAddNewTab(isIncognito: true);
      }),
      MenuBottomItem(
        Icons.cleaning_services,
        "Delete data",
        Colors.redAccent,
        () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Delete data"),
              content: const Text("Are you sure you want to delete all data?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    onClearAllData();
                    Navigator.pop(context);
                  },
                  child: const Text("Delete"),
                ),
              ],
            ),
          );
        },
      ),
      MenuBottomItem(Icons.extension, "Extensions", Colors.white, () {
        Navigator.pop(context);
        onShowCapturedVideos();
      }),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: MediaQuery.of(context).size.width > 500 ? 1.7 : 1.1,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: item.onActions,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 26),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: item.color, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void showHistoryModal({
    required BuildContext context,
    required List<Map<String, String>> history,
    required Function(String) onUrlSelected,
    required VoidCallback onClearHistory,
    required Function(int) onRemoveEntry,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => HistoryModal(
          history: history,
          onUrlSelected: (url) {
            Navigator.pop(context);
            onUrlSelected(url);
          },
          onClearHistory: () {
            onClearHistory();
            setStateModal(() {});
          },
          onRemoveEntry: (index) {
            onRemoveEntry(index);
            setStateModal(() {});
          },
        ),
      ),
    );
  }

  static void showCapturedVideosModal({
    required BuildContext context,
    required List<VideoItem> detectedVideos,
    required List<VideoItem> onlineVideos,
    required Function(VideoItem) onVideoCaptured,
    required Function(VideoItem) onVideoRemoved,
    required Function(List<VideoItem>) onVideosUpdated,
    required VoidCallback onClear,
    required Function(int) onTabRequested,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CapturedVideosModal(
        videos: detectedVideos,
        onlineVideos: onlineVideos,
        onAdd: onVideoCaptured,
        onRemove: onVideoRemoved,
        onVideosUpdated: onVideosUpdated,
        onClear: () {
          onClear();
          Navigator.pop(context);
        },
        onTabRequested: onTabRequested,
      ),
    );
  }

  static void showBookmarksModal({
    required BuildContext context,
    required List<Map<String, String>> bookmarks,
    required String currentUrl,
    required Function(String) onUrlSelected,
    required VoidCallback onAddBookmark,
    required Function(String) onRemoveBookmark,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => BookmarksModal(
          bookmarks: bookmarks,
          currentUrl: currentUrl,
          onUrlSelected: (url) {
            Navigator.pop(context);
            onUrlSelected(url);
          },
          onAddBookmark: () async {
            onAddBookmark();
            setStateModal(() {});
          },
          onRemoveBookmark: (url) {
            onRemoveBookmark(url);
            setStateModal(() {});
          },
        ),
      ),
    );
  }
}
