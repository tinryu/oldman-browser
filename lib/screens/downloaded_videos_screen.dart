import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/video_item.dart';
import 'video_player_screen.dart';

class DownloadedVideosScreen extends StatefulWidget {
  const DownloadedVideosScreen({super.key});

  @override
  State<DownloadedVideosScreen> createState() => _DownloadedVideosScreenState();
}

class _DownloadedVideosScreenState extends State<DownloadedVideosScreen> {
  List<dynamic> _displayItems = []; // Can be VideoItem or Directory
  final Set<VideoItem> _selectedVideos = {};
  bool _isLoading = true;
  Directory? _currentDir;
  Directory? _rootDir;

  @override
  void initState() {
    super.initState();
    _loadDownloadedVideos();
  }

  void refresh() {
    _loadDownloadedVideos();
  }

  Future<Directory> _getDownloadsDir() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return Directory(p.join(dir?.path ?? '', 'downloads'));
    }
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, 'downloads'));
  }

  Future<void> _loadDownloadedVideos() async {
    _rootDir = await _getDownloadsDir();
    if (!await _rootDir!.exists()) {
      await _rootDir!.create(recursive: true);
    }
    _currentDir = _rootDir;
    await _loadCurrentDir();
  }

  Future<void> _loadCurrentDir() async {
    if (_currentDir == null) return;

    if (!await _currentDir!.exists()) {
      debugPrint(
        'Current directory ${_currentDir!.path} not found. Falling back to root.',
      );
      _currentDir = _rootDir;
      if (_currentDir == null) return;
    }

    setState(() {
      _selectedVideos.clear();
      _isLoading = true;
    });
    final List<dynamic> items = [];

    try {
      final List<FileSystemEntity> entities = _currentDir!.listSync();

      for (var entity in entities) {
        if (entity is Directory) {
          // Check if this directory is a video itself
          final masterFile = File('${entity.path}/master.m3u8');
          final mp4File = File('${entity.path}/output.mp4');
          bool isMp4 = await mp4File.exists();
          bool isHls = await masterFile.exists();

          if (isMp4 || isHls) {
            // It's a video
            String? thumbPath;
            final thumbFile = File('${entity.path}/thumbnail.jpg');
            if (await thumbFile.exists()) {
              thumbPath = thumbFile.path;
            }
            items.add(
              VideoItem(
                title: p.basename(entity.path),
                url: isMp4 ? mp4File.path : 'file://${masterFile.path}',
                thumbnailUrl: thumbPath,
              ),
            );
          } else {
            // It's a group folder (or empty folder)
            // Verify not empty or contains valid stuff if we want to be strict,
            // but for now just show as folder
            items.add(entity);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading dir: $e');
    }

    setState(() {
      _displayItems = items;
      _isLoading = false;
    });
  }

  void _navigateToDir(Directory dir) {
    setState(() {
      _currentDir = dir;
    });
    _loadCurrentDir();
  }

  Future<bool> _navigateBack() async {
    if (_currentDir?.path == _rootDir?.path) {
      return true; // Use default back behavior (exit app/screen)
    } else {
      setState(() {
        _currentDir = _currentDir?.parent;
      });
      _loadCurrentDir();
      return false; // Prevent default back
    }
  }

  String _getCurrentBreadcrumb() {
    if (_currentDir == null || _rootDir == null) return 'SD /';
    if (_currentDir!.path == _rootDir!.path) return 'SD /';

    final relativePath = p.relative(_currentDir!.path, from: _rootDir!.path);
    if (relativePath == '.') return 'SD /';

    final parts = p.split(relativePath).where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) return 'SD /';
    return 'SD / ${parts.join(' / ')}';
  }

  Map<String, int> _getItemCounts() {
    int folderCount = 0;
    int videoCount = 0;

    for (var item in _displayItems) {
      if (item is Directory) {
        folderCount++;
      } else if (item is VideoItem) {
        videoCount++;
      }
    }

    return {'folders': folderCount, 'videos': videoCount};
  }

  Future<void> _deleteVideo(VideoItem video) async {
    try {
      String videoDirString;
      if (video.url.startsWith('file://')) {
        // HLS
        final masterFile = File(video.url.replaceFirst('file://', ''));
        videoDirString = masterFile.parent.path;
      } else {
        // MP4
        final mp4File = File(video.url);
        videoDirString = mp4File.parent.path;
      }

      final videoDir = Directory(videoDirString);
      if (await videoDir.exists()) {
        await videoDir.delete(recursive: true);
      }

      // Try to clean up empty parent directory (Group directory)
      // Only delete if it's not the root downloads directory
      final downloadsDir = await _getDownloadsDir();
      final parentDir = videoDir.parent;
      if (parentDir.path != downloadsDir.path) {
        if (await parentDir.exists() && parentDir.listSync().isEmpty) {
          await parentDir.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting ${video.title}: $e');
      rethrow;
    }
  }

  Future<void> _renameItem(dynamic item) async {
    String currentPath;
    String currentName;

    if (item is Directory) {
      currentPath = item.path;
      currentName = p.basename(item.path);
    } else if (item is VideoItem) {
      String videoDirString;
      if (item.url.startsWith('file://')) {
        final masterFile = File(item.url.replaceFirst('file://', ''));
        videoDirString = masterFile.parent.path;
      } else {
        final mp4File = File(item.url);
        videoDirString = mp4File.parent.path;
      }
      currentPath = videoDirString;
      currentName = item.title;
    } else {
      return;
    }

    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == currentName) return;

    try {
      final parentDir = Directory(currentPath).parent;
      final newPath = p.join(parentDir.path, newName);

      if (await Directory(newPath).exists()) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Name already exists')));
        }
        return;
      }

      await Directory(currentPath).rename(newPath);
      await _loadCurrentDir();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error renaming: $e')));
      }
    }
  }

  Future<void> _deleteSelected() async {
    final count = _selectedVideos.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count Video${count > 1 ? 's' : ''}?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int deletedCount = 0;
    try {
      for (final video in _selectedVideos) {
        await _deleteVideo(video);
        deletedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted $deletedCount videos')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during batch delete: $e')),
        );
      }
    } finally {
      await _loadCurrentDir();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
        foregroundColor: theme.colorScheme.onSurface,
        toolbarHeight: 45,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _currentDir?.path == _rootDir?.path
                      ? Icons.cached_rounded
                      : Icons.arrow_back_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () async {
                  if (!await _navigateBack()) {
                    // Start navigated back successfully, stay on screen
                  } else {
                    _loadDownloadedVideos();
                    // At root, let system handle pop (or do nothing if it's the main nav)
                    // If you want home button to do something else when at root, handle here
                  }
                },
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCurrentBreadcrumb(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Builder(
              builder: (context) {
                final counts = _getItemCounts();
                final parts = <String>[];
                if (counts['folders']! > 0) {
                  parts.add(
                    '${counts['folders']} folder${counts['folders']! > 1 ? 's' : ''}',
                  );
                }
                if (counts['videos']! > 0) {
                  parts.add(
                    '${counts['videos']} video${counts['videos']! > 1 ? 's' : ''}',
                  );
                }
                return Text(
                  parts.isEmpty ? 'Empty' : parts.join(', '),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          if (_selectedVideos.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.onPrimary,
              ),
              onPressed: _deleteSelected,
              tooltip: 'Delete Selected',
            ),
        ],
      ),
      // ignore: deprecated_member_use
      body: WillPopScope(
        onWillPop: _navigateBack,
        child: _displayItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Empty Folder',
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadCurrentDir,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount:
                    _displayItems.length +
                    (_getItemCounts()['folders']! > 0 &&
                            _getItemCounts()['videos']! > 0
                        ? 2
                        : 0) +
                    1, // +1 for the Select All button
                itemBuilder: (context, index) {
                  final counts = _getItemCounts();
                  final hasFolders = counts['folders']! > 0;
                  final hasVideos = counts['videos']! > 0;
                  final hasBoth = hasFolders && hasVideos;

                  // 1. Select All Button at index 0
                  if (index == 0) {
                    final videosInFolder = _displayItems
                        .whereType<VideoItem>()
                        .toList();
                    if (videosInFolder.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final isAllSelected =
                        videosInFolder.isNotEmpty &&
                        videosInFolder.every(
                          (v) =>
                              _selectedVideos.any((sv) => sv.title == v.title),
                        );

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              isAllSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 22,
                              color: isAllSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                            onPressed: () {
                              setState(() {
                                if (isAllSelected) {
                                  _selectedVideos.clear();
                                } else {
                                  for (var v in videosInFolder) {
                                    if (!_selectedVideos.any(
                                      (sv) => sv.title == v.title,
                                    )) {
                                      _selectedVideos.add(v);
                                    }
                                  }
                                }
                              });
                            },
                            tooltip: isAllSelected
                                ? 'Deselect All'
                                : 'Select All',
                          ),
                        ],
                      ),
                    );
                  }

                  // Shift index due to Select All button
                  final adjustedIndex = index - 1;

                  // 2. Section headers
                  if (hasBoth) {
                    if (adjustedIndex == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'FOLDERS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            letterSpacing: 1.2,
                          ),
                        ),
                      );
                    }
                    if (adjustedIndex == counts['folders']! + 1) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'VIDEOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            letterSpacing: 1.2,
                          ),
                        ),
                      );
                    }
                  }

                  // Adjust actualIndex for headers
                  final actualIndex = hasBoth
                      ? (adjustedIndex <= counts['folders']!
                            ? adjustedIndex - 1
                            : adjustedIndex - 2)
                      : adjustedIndex;

                  if (actualIndex < 0 || actualIndex >= _displayItems.length) {
                    return const SizedBox.shrink();
                  }

                  final item = _displayItems[actualIndex];

                  if (item is Directory) {
                    final folderName = p.basename(item.path);

                    return Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.onPrimary.withValues(
                                alpha: 0.2,
                              ),
                              theme.colorScheme.onPrimary.withValues(
                                alpha: 0.1,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToDir(item),
                          onLongPress: () => _renameItem(item),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage('assets/icon/icon.png'),
                                      fit: BoxFit.contain,
                                      opacity: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: theme.colorScheme.onPrimary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.folder_copy_rounded,
                                    size: 25,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      folderName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to open',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final video = item as VideoItem;
                  final bool isMp4 = !video.url.toLowerCase().contains('.m3u8');
                  final isSelected = _selectedVideos.any(
                    (v) => v.title == video.title,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: video.thumbnailUrl!.startsWith('http')
                              ? NetworkImage(video.thumbnailUrl!)
                              : FileImage(File(video.thumbnailUrl!)),
                          fit: BoxFit.cover,
                          opacity: 0.5,
                        ),
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.05)
                            : theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        horizontalTitleGap: 20,
                        // contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        leading: SizedBox(
                          width: 100,
                          height: 100,
                          child: Row(
                            children: [
                              // Transform.scale(
                              //   scale: 0.9,
                              //   child: Checkbox(
                              //     value: isSelected,
                              //     activeColor: theme.colorScheme.primary,
                              //     onChanged: (bool? value) {
                              //       setState(() {
                              //         if (value == true) {
                              //           _selectedVideos.add(video);
                              //         } else {
                              //           _selectedVideos.removeWhere(
                              //             (v) => v.title == video.title,
                              //           );
                              //         }
                              //       });
                              //     },
                              //   ),
                              // ),
                              // const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.05),
                                    image: video.thumbnailUrl != null
                                        ? DecorationImage(
                                            image:
                                                video.thumbnailUrl!.startsWith(
                                                  'http',
                                                )
                                                ? NetworkImage(
                                                    video.thumbnailUrl!,
                                                  )
                                                : FileImage(
                                                        File(
                                                          video.thumbnailUrl!,
                                                        ),
                                                      )
                                                      as ImageProvider,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (video.thumbnailUrl == null)
                                        Icon(
                                          Icons.sd_card,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                          size: 30,
                                        ),
                                      Positioned(
                                        bottom: 5,
                                        top: 5,
                                        left: 5,
                                        right: 5,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.play_circle_fill,
                                            size: 25,
                                            color: theme.colorScheme.onPrimary
                                                .withValues(alpha: 0.8),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VideoPlayerScreen(
                                                      videoUrl: video.url,
                                                      title: video.title,
                                                    ),
                                              ),
                                            ).then((_) => _loadCurrentDir());
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.7,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isMp4 ? 'MP4' : 'M3U8',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 6,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              video.title,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.drive_file_rename_outline,
                                size: 20,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              onPressed: () => _renameItem(video),
                              tooltip: 'Rename',
                            ),
                          ],
                        ),
                        subtitle: Text(
                          isMp4 ? 'Format: MP4' : 'Format: HLS (m3u8)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedVideos.removeWhere(
                                (v) => v.title == video.title,
                              );
                            } else {
                              _selectedVideos.add(video);
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
