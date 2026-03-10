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
                    if (history.isEmpty) return;
                    history.clear();
                    StorageService.saveHistory(history);
                  },
                  onRemoveEntry: (index) {
                    history.removeAt(index);
                    StorageService.saveHistory(history);
                  },
                ),
                onTabRequested: onTabRequested,
                onClearAllData: onClearAllData,
                onShowCapturedVideos: () => showCapturedVideosModal(
                  context: context,
                  detectedVideos: detectedVideos,
                  onlineVideos: onlineVideos,
                  onVideoCaptured: onVideoCaptured,
                  onVideoRemoved: onVideoRemoved,
                  onVideosUpdated: onVideosUpdated,
                  onTabRequested: onTabRequested,
                  onClear: () {
                    if (detectedVideos.isNotEmpty) {
                      detectedVideos.clear();
                    }
                  },
                ),
                detectedVideosCount: detectedVideos.length,
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
    required VoidCallback onClearAllData,
    required VoidCallback onShowCapturedVideos,
    required int detectedVideosCount,
  }) {
    final items = [
      MenuBottomItem(Icons.star, "Favorites", Colors.white, () {
        Navigator.pop(context);
        onShowBookmarks();
      }),
      MenuBottomItem(Icons.download, "Downloads", Colors.white, () {
        Navigator.pop(context);
        onTabRequested(3);
      }),
      MenuBottomItem(Icons.extension, "Extensions", Colors.white, () {
        Navigator.pop(context);
        onShowCapturedVideos();
      }, badgeCount: detectedVideosCount),

      MenuBottomItem(
        Icons.remove_moderator_outlined,
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
      MenuBottomItem(Icons.history, "History", Colors.white, () {
        Navigator.pop(context);
        onShowHistory();
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items
                .take(3)
                .map((item) => _buildMenuItem(item))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items
                .skip(3)
                .map((item) => _buildMenuItem(item))
                .toList(),
          ),
        ],
      ),
    );
  }

  static Widget _buildMenuItem(MenuBottomItem item) {
    return Expanded(
      child: InkWell(
        onTap: item.onActions,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                label: item.badgeCount != null
                    ? Text(item.badgeCount.toString())
                    : null,
                isLabelVisible: item.badgeCount != null && item.badgeCount! > 0,
                child: Icon(item.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
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
