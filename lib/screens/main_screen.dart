import 'package:flutter/material.dart';
import 'video_list_screen.dart';
import 'downloaded_videos_screen.dart';
import 'home_screen.dart';
import 'source_list_screen.dart';
import '../models/video_item.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<VideoListScreenState> _videoListKey = GlobalKey();
  List<VideoItem> onlineVideos = [];
  List<String> contentAlert = [
    'Home is a browser that can capture m3u8 streams.',
    'Sources is a List of videos that can be downloaded.',
    'Online is a List of videos that can be downloaded.',
    'Offline is a List of downloaded videos.',
  ];

  void _addVideo(VideoItem video) {
    setState(() {
      onlineVideos.insert(0, video);
    });
  }

  void _removeVideo(VideoItem video) {
    setState(() {
      onlineVideos.removeWhere((v) => v.url == video.url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onVideoCaptured: _addVideo,
        onVideoRemoved: _removeVideo,
        onVideosUpdated: (newList) {
          setState(() {
            onlineVideos = newList;
          });
        },
        onlineVideos: onlineVideos,
        onTabRequested: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 2) {
            _videoListKey.currentState?.updateClipboardStatus();
          }
        },
      ),
      SourceListScreen(
        onTabRequested: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 2) {
            _videoListKey.currentState?.updateClipboardStatus();
          }
        },
      ),
      VideoListScreen(
        key: _videoListKey,
        onlineVideos: onlineVideos,
        onVideosUpdated: (newList) {
          setState(() {
            onlineVideos = newList;
          });
        },
      ),
      const DownloadedVideosScreen(),
    ];

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _selectedIndex == 0
            ? const SizedBox.shrink()
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
        toolbarHeight: 50,
        centerTitle: true,
        title: SizedBox(
          height: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _selectedIndex == 0
                  ? Image.asset(
                      'assets/icon/icon.png',
                      width: 15,
                      colorBlendMode: BlendMode.color,
                      color: theme.colorScheme.primary,
                    )
                  : _selectedIndex == 1
                  ? Icon(
                      Icons.connected_tv_rounded,
                      color: theme.colorScheme.primary,
                      size: 15,
                    )
                  : _selectedIndex == 2
                  ? Icon(
                      Icons.cloud_download_rounded,
                      color: theme.colorScheme.primary,
                      size: 15,
                    )
                  : Icon(
                      Icons.folder_copy_rounded,
                      color: theme.colorScheme.primary,
                      size: 15,
                    ),
              const SizedBox(height: 2),
              _selectedIndex == 0
                  ? Text(
                      'OM Browser',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : Text(
                      _selectedIndex == 1
                          ? 'Sources'
                          : _selectedIndex == 2
                          ? 'Online'
                          : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  insetPadding: const EdgeInsets.all(10),
                  icon: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 20),
                      SizedBox(width: 5),
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  iconPadding: const EdgeInsets.all(10),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(contentAlert[_selectedIndex])],
                  ),
                  contentTextStyle: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface.withValues(alpha: 0.1),
                theme.colorScheme.surface.withValues(alpha: 0.8),
                theme.colorScheme.surface.withValues(alpha: 0.8),
                theme.colorScheme.surface.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: SizedBox(
        height: 50,
        child: BottomNavigationBar(
          mouseCursor: SystemMouseCursors.click,
          iconSize: 20,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.5,
          ),
          selectedFontSize: 0,
          unselectedFontSize: 0,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            if (index == 2) {
              _videoListKey.currentState?.updateClipboardStatus();
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icon/icon.png',
                width: 18,
                colorBlendMode: BlendMode.color,
                color: theme.colorScheme.surface,
              ),
              activeIcon: Image.asset(
                'assets/icon/icon.png',
                width: 18,
                colorBlendMode: BlendMode.color,
                color: theme.colorScheme.primary,
              ),
              label: 'Home',
              tooltip: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.connected_tv_rounded),
              label: 'Sources',
              tooltip: 'Sources',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.cloud_download_rounded),
              label: 'Online',
              tooltip: 'Online',
            ),

            const BottomNavigationBarItem(
              icon: Icon(Icons.folder_copy_rounded),
              label: 'Offline',
              tooltip: 'Offline',
            ),
          ],
        ),
      ),
    );
  }
}
