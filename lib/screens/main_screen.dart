import 'package:flutter/material.dart';
import 'video_list_screen.dart';
import 'downloaded_videos_screen.dart';
import 'home_screen.dart';
import '../models/video_item.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<VideoItem> onlineVideos = [];
  List<String> contentAlert = [
    'Home is a browser that can capture m3u8 streams.',
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
        },
      ),
      VideoListScreen(
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
            ? SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
        toolbarHeight: 35,
        centerTitle: true,
        title: SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _selectedIndex == 0
                  ? Image.asset('assets/icon/icon.png', scale: 1.0)
                  : _selectedIndex == 1
                  ? Icon(Icons.downloading)
                  : Icon(Icons.sd_card_rounded),
              SizedBox(width: 5),
              Text(
                _selectedIndex == 0
                    ? 'OldManBrowser'
                    : _selectedIndex == 1
                    ? 'Onlines'
                    : 'Downloaded',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  insetPadding: const EdgeInsets.all(10),
                  icon: Row(
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
                  contentTextStyle: TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                theme.colorScheme.surface.withValues(alpha: 0.8),
                theme.colorScheme.surface.withValues(alpha: 0.8),
                theme.colorScheme.onPrimary.withValues(alpha: 0.1),
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
        height: 30,
        child: BottomNavigationBar(
          mouseCursor: SystemMouseCursors.click,
          iconSize: 20,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.onPrimary,
          unselectedItemColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.5,
          ),
          selectedFontSize: 0,
          unselectedFontSize: 0,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.language),
              label: 'Home',
              tooltip: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_download_rounded),
              label: 'Online',
              tooltip: 'Online',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.snippet_folder_rounded),
              label: 'Offline',
              tooltip: 'Offline',
            ),
          ],
        ),
      ),
    );
  }
}
