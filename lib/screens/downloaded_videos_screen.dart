import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_item.dart';
import 'video_player_screen.dart';

class DownloadedVideosScreen extends StatefulWidget {
  const DownloadedVideosScreen({super.key});

  @override
  State<DownloadedVideosScreen> createState() => _DownloadedVideosScreenState();
}

class _DownloadedVideosScreenState extends State<DownloadedVideosScreen> {
  List<VideoItem> downloadedVideos = [];
  final Set<VideoItem> _selectedVideos = {};
  bool _isLoading = true;

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
      return Directory('${dir?.path}/downloads');
    }
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/downloads');
  }

  Future<void> _loadDownloadedVideos() async {
    setState(() => _isLoading = true);
    final downloadsDir = await _getDownloadsDir();
    if (!await downloadsDir.exists()) {
      setState(() {
        downloadedVideos = [];
        _isLoading = false;
        _selectedVideos.clear();
      });
      return;
    }

    final List<VideoItem> loaded = [];
    try {
      final List<FileSystemEntity> folders = downloadsDir.listSync();
      for (var folder in folders) {
        if (folder is Directory) {
          final masterFile = File('${folder.path}/master.m3u8');
          final mp4File = File('${folder.path}/output.mp4');

          bool isMp4 = await mp4File.exists();
          bool isHls = await masterFile.exists();

          if (isMp4 || isHls) {
            String? thumbPath;
            final thumbFile = File('${folder.path}/thumbnail.jpg');
            if (await thumbFile.exists()) {
              thumbPath = thumbFile.path;
            }

            loaded.add(
              VideoItem(
                title: folder.path.split(Platform.pathSeparator).last,
                url: isMp4 ? mp4File.path : 'file://${masterFile.path}',
                thumbnailUrl: thumbPath,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading downloads: $e');
    }

    setState(() {
      downloadedVideos = loaded;
      // Remove any selected items that are no longer present
      _selectedVideos.removeWhere(
        (selected) => !loaded.any((item) => item.title == selected.title),
      );
      _isLoading = false;
    });
  }

  Future<void> _deleteVideo(VideoItem video) async {
    try {
      final downloadsDir = await _getDownloadsDir();
      final videoDir = Directory('${downloadsDir.path}/${video.title}');
      if (await videoDir.exists()) {
        await videoDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting ${video.title}: $e');
      rethrow;
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
      await _loadDownloadedVideos();
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedVideos.length == downloadedVideos.length &&
          downloadedVideos.isNotEmpty) {
        _selectedVideos.clear();
      } else {
        _selectedVideos.addAll(downloadedVideos);
      }
    });
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(
              (_selectedVideos.isNotEmpty &&
                      _selectedVideos.length == downloadedVideos.length)
                  ? Icons.check_box
                  : _selectedVideos.isNotEmpty
                  ? Icons.indeterminate_check_box
                  : Icons.check_box_outline_blank,
              color: _selectedVideos.isNotEmpty
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            onPressed: downloadedVideos.isEmpty ? null : _toggleSelectAll,
            tooltip: 'Select All',
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 30,
                width: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                      theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  boxShadow: _selectedVideos.isNotEmpty
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Center(
                  child: _selectedVideos.isEmpty
                      ? const Icon(Icons.folder, size: 20, color: Colors.white)
                      : TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedVideos.clear();
                            });
                          },
                          child: Text(
                            '${_selectedVideos.length}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_selectedVideos.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: _deleteSelected,
              tooltip: 'Delete Selected',
            ),
        ],
      ),
      body: downloadedVideos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_for_offline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No downloaded videos yet.',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadDownloadedVideos,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Space for nav bar
              itemCount: downloadedVideos.length,
              itemBuilder: (context, index) {
                final video = downloadedVideos[index];
                final bool isMp4 = !video.url.toLowerCase().contains('.m3u8');
                final isSelected = _selectedVideos.any(
                  (v) => v.title == video.title,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Card(
                    elevation: 0,
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.05)
                        : theme.cardTheme.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: SizedBox(
                        width: 100,
                        height: 60,
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 0.9,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: theme.colorScheme.primary,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedVideos.add(video);
                                    } else {
                                      _selectedVideos.removeWhere(
                                        (v) => v.title == video.title,
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.05,
                                  ),
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
                                                      File(video.thumbnailUrl!),
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
                                      bottom: 4,
                                      right: 10,
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
                      title: Text(
                        video.title,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      trailing: IconButton(
                        icon: Icon(
                          Icons.play_circle_fill,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                videoUrl: video.url,
                                title: video.title,
                              ),
                            ),
                          ).then((_) => _loadDownloadedVideos());
                        },
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
    );
  }
}
