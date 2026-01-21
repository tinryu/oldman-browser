import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:gal/gal.dart';

import '../models/video_item.dart';
import '../widgets/radio_group.dart' hide RadioGroup;
import 'video_player_screen.dart';

class VideoListScreen extends StatefulWidget {
  final List<VideoItem> onlineVideos;
  final Function(List<VideoItem>) onVideosUpdated;

  const VideoListScreen({
    super.key,
    required this.onlineVideos,
    required this.onVideosUpdated,
  });

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final Set<VideoItem> _selectedVideos = {};

  @override
  void initState() {
    super.initState();
  }

  Future<Directory> _getDownloadsDir() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return Directory('${dir?.path}/downloads');
    }
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/downloads');
  }

  Future<bool> _validateM3U8(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      // Basic check for M3U8 content
      return response.data.toString().contains('#EXTM3U');
    } catch (e) {
      return false;
    }
  }

  void _showAddVideoDialog() {
    final bulkController = TextEditingController();
    bool isValidating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add M3U8 Videos'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paste one or more M3U8 URLs.\nFormat: "Title | URL" or just "URL"',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bulkController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Title | URL | Thumbnail\nMy Video | https://example.com/playlist.m3u8 | https://example.com/thumb.jpg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isValidating) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Validating links...'),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isValidating
                      ? null
                      : () async {
                          final input = bulkController.text.trim();
                          if (input.isEmpty) return;

                          setDialogState(() => isValidating = true);

                          final lines = input.split('\n');
                          final List<VideoItem> validItems = [];

                          for (var line in lines) {
                            line = line.trim();
                            if (line.isEmpty) continue;

                            String title;
                            String url;
                            String? thumb;

                            if (line.contains('|')) {
                              final parts = line.split('|');
                              if (parts.length >= 3) {
                                title = parts[0].trim();
                                url = parts[1].trim();
                                thumb = parts[2].trim();
                              } else if (parts.length == 2) {
                                title = parts[0].trim();
                                url = parts[1].trim();
                              } else {
                                url = parts[0].trim();
                                title = url.split('/').last.split('?').first;
                              }
                            } else {
                              url = line;
                              title = url.split('/').last.split('?').first;
                              if (title.isEmpty) title = 'Untitled Video';
                            }

                            if (await _validateM3U8(url)) {
                              validItems.add(
                                VideoItem(
                                  title: title,
                                  url: url,
                                  thumbnailUrl: thumb,
                                ),
                              );
                            }
                          }

                          setDialogState(() => isValidating = false);

                          if (validItems.isNotEmpty) {
                            final newList = List<VideoItem>.from(
                              widget.onlineVideos,
                            );
                            newList.insertAll(0, validItems);
                            widget.onVideosUpdated(newList);
                            if (context.mounted) Navigator.pop(context);
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No valid M3U8 URLs found'),
                              ),
                            );
                          }
                        },
                  child: const Text('Add All'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
        foregroundColor: theme.colorScheme.onSurface,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: InkWell(
            onTap: () {
              setState(() {
                if (_selectedVideos.length == widget.onlineVideos.length &&
                    widget.onlineVideos.isNotEmpty) {
                  _selectedVideos.clear();
                } else {
                  _selectedVideos.addAll(widget.onlineVideos);
                }
              });
            },
            child: Icon(
              _selectedVideos.isEmpty
                  ? Icons.check_box_outline_blank
                  : Icons.check_box,
              color: _selectedVideos.isEmpty
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : theme.colorScheme.primary,
            ),
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
                      ? const Icon(
                          Icons.movie_creation,
                          size: 20,
                          color: Colors.white,
                        )
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
          if (_selectedVideos.isNotEmpty) ...[
            Padding(
              padding: EdgeInsetsGeometry.only(right: 22.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    color: theme.colorScheme.onSurface,
                    icon: const Icon(Icons.download),
                    onPressed: _downloadSelectedSequentially,
                    tooltip: 'Download Selected',
                  ),
                  IconButton(
                    color: theme.colorScheme.error,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      final newList = List<VideoItem>.from(widget.onlineVideos);
                      newList.removeWhere((v) => _selectedVideos.contains(v));
                      widget.onVideosUpdated(newList);
                      setState(() {
                        _selectedVideos.clear();
                      });
                    },
                    tooltip: 'Delete Selected',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAddVideoDialog,
        backgroundColor: theme.colorScheme.onPrimary,
        foregroundColor: theme.colorScheme.onSurface,
        child: const Icon(Icons.add, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: ListView.builder(
        itemCount: widget.onlineVideos.length,
        itemBuilder: (context, index) {
          final video = widget.onlineVideos[index];
          final isSelected = _selectedVideos.contains(video);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Card(
              elevation: 0,
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
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
                          checkColor: theme.colorScheme.onPrimary,
                          activeColor: theme.colorScheme.primary,
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedVideos.add(video);
                              } else {
                                _selectedVideos.remove(video);
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
                                        video.thumbnailUrl!.startsWith('http')
                                        ? NetworkImage(video.thumbnailUrl!)
                                        : FileImage(File(video.thumbnailUrl!))
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
                                  Icons.movie_creation_outlined,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
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
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'HLS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  video.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.play_circle_outline,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          builder: (context) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: VideoPlayerScreen(
                              videoUrl: video.url,
                              title: video.title,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.download_for_offline_outlined,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      onPressed: () =>
                          _startDownloadWithOptions(context, video),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      onPressed: () {
                        final newList = List<VideoItem>.from(
                          widget.onlineVideos,
                        );
                        newList.remove(video);
                        widget.onVideosUpdated(newList);
                        setState(() {
                          _selectedVideos.remove(video);
                        });
                      },
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedVideos.remove(video);
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

  Future<void> _downloadSelectedSequentially() async {
    final videosToDownload = _selectedVideos.toList();
    setState(() {
      _selectedVideos.clear();
    });

    String? lastSelectedQuality;

    for (int i = 0; i < videosToDownload.length; i++) {
      final video = videosToDownload[i];
      debugPrint(
        'Starting sequential download ${i + 1}/${videosToDownload.length}: ${video.title}',
      );

      // We pass a prefix to the dialog to show queue progress
      final result = await _startDownloadWithOptions(
        context,
        video,
        queueProgress: '(${i + 1}/${videosToDownload.length}) ',
        preferredQuality: lastSelectedQuality,
      );

      if (lastSelectedQuality == null && result != null) {
        lastSelectedQuality = result;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All selected downloads completed!')),
      );
    }
  }

  Future<String?> _startDownloadWithOptions(
    BuildContext context,
    VideoItem video, {
    String queueProgress = '',
    String? preferredQuality,
  }) async {
    final theme = Theme.of(context);
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 33) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          if (!context.mounted) return null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission required')),
          );
          return null;
        }
      }
    }

    final progressNotifier = ValueNotifier<double>(0);
    final countNotifier = ValueNotifier<int>(0);
    final statusNotifier = ValueNotifier<String>('Downloading...');
    CancelToken cancelToken = CancelToken();

    String? selected;

    try {
      final dio = Dio();
      final uri = Uri.parse(video.url);

      // Safe origin extraction
      String? origin;
      try {
        if (uri.hasScheme && uri.hasAuthority) {
          origin = uri.origin;
        }
      } catch (_) {}

      dio.options.headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': video.url,
        if (origin != null) 'Origin': origin,
      };

      if (dio.httpClientAdapter is IOHttpClientAdapter) {
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };
      }

      final response = await dio.get(
        video.url,
        options: Options(responseType: ResponseType.plain),
      );
      final masterPlaylist = await HlsPlaylistParser.create().parseString(
        uri,
        response.data,
      );

      if (masterPlaylist is! HlsMasterPlaylist ||
          masterPlaylist.variants.isEmpty) {
        if (!context.mounted) return null;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No variants found')));
        return null;
      }

      // Sort variants by bitrate descending to favor higher quality in auto-selection
      final variants = List.of(masterPlaylist.variants);
      variants.sort(
        (a, b) => (b.format.bitrate ?? 0).compareTo(a.format.bitrate ?? 0),
      );

      final options = variants
          .map(
            (v) =>
                '${v.format.width}x${v.format.height} - ${(v.format.bitrate ?? 0) ~/ 1000} kbps',
          )
          .toList();

      if (preferredQuality != null) {
        if (options.contains(preferredQuality)) {
          selected = preferredQuality;
        } else {
          // Try to fuzzy match resolution
          final prefRes = preferredQuality.split(' - ').first;
          try {
            selected = options.firstWhere((opt) => opt.startsWith(prefRes));
          } catch (_) {
            // No resolution match, fallback to best found (first due to sort)
            if (options.isNotEmpty) selected = options.first;
          }
        }
      }

      if (selected == null) {
        if (!context.mounted) return null;
        selected = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.cardTheme.color,
            title: Text(
              'Select Quality',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: RadioGroup<String>(
                groupValue: selected,
                onChanged: (val) => Navigator.pop(context, val),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) => RadioListTileWrapper<String>(
                    title: Text(options[i]),
                    value: options[i],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (selected == null) return null;

      final selectedVariant = variants[options.indexOf(selected)];

      final downloadsDir = await _getDownloadsDir();
      final videoDir = Directory('${downloadsDir.path}/${video.title}');
      await videoDir.create(recursive: true);

      // Download thumbnail if available
      if (video.thumbnailUrl != null) {
        try {
          final thumbPath = '${videoDir.path}/thumbnail.jpg';
          await dio.download(video.thumbnailUrl!, thumbPath);
        } catch (e) {
          debugPrint('Error downloading thumbnail: $e');
        }
      }

      final masterPath = '${videoDir.path}/master.m3u8';
      await File(masterPath).writeAsString(response.data);

      // Download selected variant playlist
      final variantResponse = await dio.get(
        selectedVariant.url.toString(),
        options: Options(responseType: ResponseType.plain),
      );
      final variantPath = '${videoDir.path}/playlist.m3u8';
      await File(variantPath).writeAsString(variantResponse.data);

      final variantPlaylist = await HlsPlaylistParser.create().parseString(
        Uri.parse(selectedVariant.url.toString()),
        variantResponse.data,
      );
      if (variantPlaylist is! HlsMediaPlaylist) return null;

      final baseUri = Uri.parse(selectedVariant.url.toString());
      final segments = variantPlaylist.segments;
      final total = segments.length;

      // Check for initialization segment (fMP4)
      String? initPath;
      if (segments.isNotEmpty && segments.first.initializationSegment != null) {
        final initSegment = segments.first.initializationSegment!;
        final initUrl = baseUri.resolve(initSegment.url!).toString();
        initPath = '${videoDir.path}/init.mp4';
        await dio.download(initUrl, initPath);
      }

      int downloaded = 0;
      if (!context.mounted) return selected;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ListenableBuilder(
          listenable: Listenable.merge([
            progressNotifier,
            countNotifier,
            statusNotifier,
          ]),
          builder: (context, _) => AlertDialog(
            title: Text(
              statusNotifier.value == 'Downloading...'
                  ? '${queueProgress}Downloading ${video.title}'
                  : '$queueProgress${statusNotifier.value}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (statusNotifier.value == 'Downloading...') ...[
                  LinearProgressIndicator(value: progressNotifier.value),
                  const SizedBox(height: 10),
                  Text('${countNotifier.value} / $total segments'),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  const Text('Merging segments into MP4...'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cancelToken.cancel();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );

      // Parallelize segment downloads (max 5 concurrent)
      const int maxConcurrent = 5;
      for (int i = 0; i < segments.length; i += maxConcurrent) {
        if (cancelToken.isCancelled) throw 'Cancelled';

        final end = (i + maxConcurrent < segments.length)
            ? i + maxConcurrent
            : segments.length;
        final batch = segments.sublist(i, end);

        await Future.wait(
          batch.map((segment) async {
            final segmentUrlString = segment.url;
            if (segmentUrlString == null) return;

            final segmentUrl = baseUri.resolve(segmentUrlString).toString();
            final segmentFile = File(
              '${videoDir.path}/${segmentUrlString.split('/').last}',
            );

            await dio.download(
              segmentUrl,
              segmentFile.path,
              cancelToken: cancelToken,
            );
            downloaded++;

            progressNotifier.value = downloaded / total;
            countNotifier.value = downloaded;
          }),
        );
      }

      if (!context.mounted) return selected;
      statusNotifier.value = 'Merging segments into MP4...';

      final outputPath = '${videoDir.path}/output.mp4';
      final outputFile = File(outputPath);
      final raf = await outputFile.open(mode: FileMode.write);

      try {
        if (initPath != null) {
          final initFile = File(initPath);
          if (await initFile.exists()) {
            final bytes = await initFile.readAsBytes();
            await raf.writeFrom(bytes);
            await initFile.delete();
          }
        }

        for (var segment in segments) {
          final segmentUrlString = segment.url;
          if (segmentUrlString != null) {
            final segmentFileName = segmentUrlString.split('/').last;
            final segmentPath = '${videoDir.path}/$segmentFileName';
            final segmentFile = File(segmentPath);
            if (await segmentFile.exists()) {
              final bytes = await segmentFile.readAsBytes();
              await raf.writeFrom(bytes);
              await segmentFile.delete();
            }
          }
        }
      } finally {
        await raf.close();
      }

      if (context.mounted) {
        statusNotifier.value = 'Exporting to Gallery...';
      }

      await Gal.putVideo(outputPath);

      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${video.title} saved to Gallery successfully!'),
          ),
        );
      }
      return selected;
    } catch (e) {
      if (!context.mounted) return selected;
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (e != 'Cancelled') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
      return selected;
    } finally {
      progressNotifier.dispose();
      countNotifier.dispose();
      statusNotifier.dispose();
    }
  }
}
