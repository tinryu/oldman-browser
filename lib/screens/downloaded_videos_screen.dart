import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/video_item.dart';
import '../services/file_manager_service.dart';
import '../widgets/downloaded_videos/select_all_button.dart';
import '../widgets/downloaded_videos/section_header.dart';
import '../widgets/downloaded_videos/folder_card.dart';
import '../widgets/downloaded_videos/downloaded_video_card.dart';
import 'video_player_screen.dart';

class DownloadedVideosScreen extends StatefulWidget {
  const DownloadedVideosScreen({super.key});

  @override
  State<DownloadedVideosScreen> createState() => _DownloadedVideosScreenState();
}

class _DownloadedVideosScreenState extends State<DownloadedVideosScreen> {
  List<dynamic> _displayItems = []; // Can be VideoItem or Directory
  final Set<dynamic> _selectedItems = {};
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

  Future<void> _loadDownloadedVideos() async {
    _rootDir = await FileManagerService.getDownloadsDir();
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
      _selectedItems.clear();
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
          final bool isMp4 = await mp4File.exists();
          final bool isHls = await masterFile.exists();

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
      unawaited(_loadCurrentDir());
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

  void _toggleSelectAll() {
    setState(() {
      final isAllSelected =
          _displayItems.isNotEmpty &&
          _displayItems.every((item) {
            if (item is VideoItem) {
              return _selectedItems.any(
                (si) => si is VideoItem && si.title == item.title,
              );
            } else if (item is Directory) {
              return _selectedItems.any(
                (si) => si is Directory && si.path == item.path,
              );
            }
            return false;
          });

      if (isAllSelected) {
        _selectedItems.clear();
      } else {
        for (var item in _displayItems) {
          bool alreadySelected = false;
          if (item is VideoItem) {
            alreadySelected = _selectedItems.any(
              (si) => si is VideoItem && si.title == item.title,
            );
          } else if (item is Directory) {
            alreadySelected = _selectedItems.any(
              (si) => si is Directory && si.path == item.path,
            );
          }
          if (!alreadySelected) {
            _selectedItems.add(item);
          }
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedItems.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count item${count > 1 ? 's' : ''}?'),
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
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int deletedCount = 0;
    try {
      for (final item in _selectedItems) {
        if (item is VideoItem) {
          await FileManagerService.deleteVideo(item);
        } else if (item is Directory) {
          if (await item.exists()) {
            await item.delete(recursive: true);
          }
        }
        deletedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted $deletedCount items')));
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
      appBar: _buildAppBar(theme),
      // ignore: deprecated_member_use
      body: WillPopScope(
        onWillPop: _navigateBack,
        child: _displayItems.isEmpty
            ? _buildEmptyState(theme)
            : _buildItemList(theme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                  // Navigated back successfully, stay on screen
                } else {
                  unawaited(_loadDownloadedVideos());
                }
              },
            ),
          ],
        ),
      ),
      title: _buildAppBarTitle(theme),
      actions: [
        if (_selectedItems.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.primary),
            onPressed: _deleteSelected,
            tooltip: 'Delete Selected',
          ),
      ],
    );
  }

  Widget _buildAppBarTitle(ThemeData theme) {
    return Column(
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
        const SizedBox(height: 4),
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
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadCurrentDir,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(ThemeData theme) {
    final counts = _getItemCounts();
    final hasFolders = counts['folders']! > 0;
    final hasVideos = counts['videos']! > 0;
    final hasBoth = hasFolders && hasVideos;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _displayItems.length + (hasBoth ? 2 : 0) + 1,
      itemBuilder: (context, index) {
        // 1. Select All Button at index 0
        if (index == 0) {
          return SelectAllButton(
            displayItems: _displayItems,
            selectedItems: _selectedItems,
            onToggleSelectAll: _toggleSelectAll,
            theme: theme,
          );
        }

        // Shift index due to Select All button
        final adjustedIndex = index - 1;

        // 2. Section headers
        if (hasBoth) {
          if (adjustedIndex == 0) {
            return SectionHeader(title: 'FOLDERS', theme: theme);
          }
          if (adjustedIndex == counts['folders']! + 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SectionHeader(title: 'VIDEOS', theme: theme),
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

        // 3. Render folder or video card
        if (item is Directory) {
          return _buildFolderItem(item, theme);
        } else {
          return _buildVideoItem(item as VideoItem, theme);
        }
      },
    );
  }

  Widget _buildFolderItem(Directory folder, ThemeData theme) {
    final isSelected = _selectedItems.any(
      (si) => si is Directory && si.path == folder.path,
    );

    return FolderCard(
      folder: folder,
      isSelected: isSelected,
      hasSelections: _selectedItems.isNotEmpty,
      theme: theme,
      onTap: () {
        if (_selectedItems.isNotEmpty) {
          setState(() {
            if (isSelected) {
              _selectedItems.removeWhere(
                (si) => si is Directory && si.path == folder.path,
              );
            } else {
              _selectedItems.add(folder);
            }
          });
        } else {
          _navigateToDir(folder);
        }
      },
      onLongPress: () {
        if (_selectedItems.isEmpty) {
          setState(() {
            _selectedItems.add(folder);
          });
        } else {
          FileManagerService.renameItem(
            context: context,
            item: folder,
            onSuccess: _loadCurrentDir,
          );
        }
      },
    );
  }

  Widget _buildVideoItem(VideoItem video, ThemeData theme) {
    final isSelected = _selectedItems.any(
      (si) => si is VideoItem && si.title == video.title,
    );

    return DownloadedVideoCard(
      video: video,
      isSelected: isSelected,
      theme: theme,
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedItems.removeWhere(
              (si) => si is VideoItem && si.title == video.title,
            );
          } else {
            _selectedItems.add(video);
          }
        });
      },
      onPlay: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VideoPlayerScreen(videoUrl: video.url, title: video.title),
          ),
        ).then((_) => _loadCurrentDir());
      },
      onRename: () => FileManagerService.renameItem(
        context: context,
        item: video,
        onSuccess: _loadCurrentDir,
      ),
    );
  }
}
