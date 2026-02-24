import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../models/video_item.dart';
import 'package:old_man_browser/widgets/video_list/online_video_card.dart';
import 'package:old_man_browser/widgets/video_list/download_options_dialog.dart';
import 'package:old_man_browser/widgets/video_list/download_progress_dialog.dart';
import 'package:old_man_browser/services/download_service.dart';
import 'video_player_screen.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:async';

class VideoListScreen extends StatefulWidget {
  final List<VideoItem> onlineVideos;
  final Function(List<VideoItem>) onVideosUpdated;

  const VideoListScreen({
    super.key,
    required this.onlineVideos,
    required this.onVideosUpdated,
  });

  @override
  State<VideoListScreen> createState() => VideoListScreenState();
}

class VideoListScreenState extends State<VideoListScreen>
    with WidgetsBindingObserver {
  final Set<VideoItem> _selectedVideos = {};
  bool _mediaKitInitialized = false;
  late final Player _player;
  late final VideoController _videoController;
  bool _hasValidClipboard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    updateClipboardStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      updateClipboardStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateClipboardStatus();
  }

  @override
  void dispose() {
    if (_mediaKitInitialized) {
      _player.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initMediaKit() {
    if (!_mediaKitInitialized) {
      _player = Player();
      _videoController = VideoController(_player);
      _mediaKitInitialized = true;
    }
  }

  Future<void> updateClipboardStatus() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;

      bool hasValidData = false;
      if (text != null && text.trim().isNotEmpty) {
        // Only trigger if it contains http or looks like a link to avoid being too intrusive
        if (text.contains('http') || text.contains('.m3u8')) {
          hasValidData = true;
        }
      }

      if (mounted && _hasValidClipboard != hasValidData) {
        setState(() {
          _hasValidClipboard = hasValidData;
        });
      }
    } catch (e) {
      debugPrint('Error checking clipboard: $e');
    }
  }

  Future<String?> _captureVideoThumbnail(
    String videoPath,
    String outputPath, {
    required Duration thumbnailSeekPosition,
  }) async {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (isDesktop) {
      debugPrint('MediaKit: Capturing thumbnail from $videoPath');
      _initMediaKit();
      try {
        await _player.open(Media(videoPath), play: false);

        // Wait for the player to be ready and have video dimensions
        await _player.stream.width
            .firstWhere((w) => w != null && w > 0)
            .timeout(const Duration(seconds: 5), onTimeout: () => 0);

        // Seek a bit into the video to avoid early black frames
        await _player.seek(thumbnailSeekPosition);

        // Give the decoder a moment to settle after the seek
        await Future.delayed(const Duration(milliseconds: 1000));

        final Uint8List? screenshot = await _player.screenshot();
        if (screenshot != null) {
          await File(outputPath).writeAsBytes(screenshot);
          debugPrint('MediaKit: Thumbnail saved to $outputPath');
          return outputPath;
        }
      } catch (e) {
        debugPrint('MediaKit capture failed: $e');
      } finally {
        // Don't dispose the player here as it's shared
        await _player.pause();
      }
      return null;
    } else {
      // Fallback to FFmpeg (only for mobile platforms)
      try {
        debugPrint('FFmpeg: Capturing thumbnail from $videoPath');
        final ss =
            '${thumbnailSeekPosition.inHours.toString().padLeft(2, '0')}:${(thumbnailSeekPosition.inMinutes % 60).toString().padLeft(2, '0')}:${(thumbnailSeekPosition.inSeconds % 60).toString().padLeft(2, '0')}';
        final cmd = '-y -ss $ss -i "$videoPath" -frames:v 1 "$outputPath"';
        final session = await FFmpegKit.execute(cmd);
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          if (await File(outputPath).exists()) {
            debugPrint('FFmpeg: Thumbnail captured successfully.');
            return outputPath;
          }
        }
        return null;
      } catch (e) {
        debugPrint('Error in  : $e');
        return null;
      }
    }
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

  void _showAddVideoDialog({String? initialText}) {
    final bulkController = TextEditingController(text: initialText);
    bool isValidating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add M3U8 Videos',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Text(
                      ' Paste one or more M3U8 URLs.',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 10,
                      ),
                      controller: bulkController,
                      maxLines: 3,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            'Title | URL | Thumbnail\nMy Video | https://example.com/playlist.m3u8',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: _hasValidClipboard
                              ? Icon(
                                  Icons.content_paste_go,
                                  color: theme.colorScheme.primary,
                                )
                              : Icon(
                                  Icons.content_paste_off,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                ),
                          onPressed: () async {
                            final data = await Clipboard.getData(
                              Clipboard.kTextPlain,
                            );
                            if (data?.text != null) {
                              bulkController.text = data!.text!;
                            }
                          },
                        ),
                      ),
                    ),
                    if (isValidating) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(),
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Validating links...',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                                    title = url
                                        .split('/')
                                        .last
                                        .split('?')
                                        .first;
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
                                unawaited(
                                  Clipboard.setData(
                                    const ClipboardData(text: ''),
                                  ),
                                );
                                _hasValidClipboard = false;
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No valid M3U8 URLs found'),
                                  ),
                                );
                              }
                            },
                      child: Text(
                        'Add All',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        toolbarHeight: 45,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedVideos.isNotEmpty
                          ? theme.colorScheme.primary.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.1),
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
              padding: const EdgeInsets.only(right: 22.0),
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
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                icon: Icon(
                  _hasValidClipboard
                      ? Icons.content_paste_go_rounded
                      : Icons.add,
                ),
                iconSize: 20,
                color: theme.colorScheme.primary,
                onPressed: () => _showAddVideoDialog(),
                tooltip: 'Add Video',
              ),
            ),
          ],
        ],
      ),
      body: ListView.builder(
        itemCount: widget.onlineVideos.length,
        itemBuilder: (context, index) {
          final video = widget.onlineVideos[index];
          final isSelected = _selectedVideos.contains(video);

          return OnlineVideoCard(
            video: video,
            isSelected: isSelected,
            onSelectedChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedVideos.add(video);
                } else {
                  _selectedVideos.remove(video);
                }
              });
            },
            onDownload: () => _startDownloadWithOptions(context, video),
            onDelete: () {
              final newList = List<VideoItem>.from(widget.onlineVideos);
              newList.remove(video);
              widget.onVideosUpdated(newList);
              setState(() {
                _selectedVideos.remove(video);
              });
            },
            onPlay: () {
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

    DownloadSelection? lastSelection;

    for (int i = 0; i < videosToDownload.length; i++) {
      if (!mounted) break;
      final video = videosToDownload[i];
      debugPrint(
        'Starting sequential download ${i + 1}/${videosToDownload.length}: ${video.title}',
      );

      // We pass a prefix to the dialog to show queue progress
      final result = await _startDownloadWithOptions(
        context,
        video,
        queueProgress: '(${i + 1}/${videosToDownload.length}) ',
        preferredQuality: lastSelection?.quality,
        preferredGroupName: lastSelection?.groupName,
        showSuccessSnackBar:
            false, // Don't show individual alerts for batch downloads
      );

      if (lastSelection == null && result != null) {
        lastSelection = result;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All selected downloads completed!')),
      );
    }
  }

  Future<DownloadSelection?> _startDownloadWithOptions(
    BuildContext context,
    VideoItem video, {
    String queueProgress = '',
    String? preferredQuality,
    String? preferredGroupName,
    bool showSuccessSnackBar = true,
  }) async {
    // final theme = Theme.of(context);
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 33) {
        final status = await Permission.storage.request();
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
    final totalNotifier = ValueNotifier<int>(0);
    final statusNotifier = ValueNotifier<String>('Downloading...');
    final cancelToken = CancelToken();

    String? selected;
    String? groupName;
    Duration thumbnailSeekPosition = const Duration(seconds: 5);

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

      final groupNameController = TextEditingController(
        text: preferredGroupName ?? '',
      );

      if (selected == null) {
        if (!context.mounted) return null;
        _initMediaKit();
        await _player.open(Media(video.url), play: false);
        await Future.delayed(const Duration(seconds: 1));

        if (!context.mounted) return null;

        selected = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DownloadOptionsDialog(
            options: options,
            videoController: _videoController,
            groupNameController: groupNameController,
            preferredQuality: preferredQuality,
          ),
        );
        // Important: Capture position AFTER the bottom sheet is closed but BEFORE pausing/reopening
        // This allows the user to seek in the preview and have that spot as their thumbnail.
        thumbnailSeekPosition = _player.state.position;
        await _player.pause();
      }

      groupName = groupNameController.text.trim().isNotEmpty
          ? groupNameController.text.trim()
          : null;

      if (selected == null) return null;

      if (!context.mounted) return DownloadSelection(selected, groupName);

      unawaited(
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (context) => DownloadProgressDialog(
            video: video,
            progressNotifier: progressNotifier,
            countNotifier: countNotifier,
            statusNotifier: statusNotifier,
            totalNotifier: totalNotifier,
            queueProgress: queueProgress,
            onCancel: () {
              cancelToken.cancel();
              Navigator.pop(context);
            },
          ),
        ),
      );

      final result = await DownloadService.downloadHLSVideo(
        context: context,
        video: video,
        selected: selected,
        groupName: groupName,
        thumbnailSeekPosition: thumbnailSeekPosition,
        progressNotifier: progressNotifier,
        countNotifier: countNotifier,
        statusNotifier: statusNotifier,
        totalNotifier: totalNotifier,
        cancelToken: cancelToken,
        showSuccessSnackBar: false, // Handle success snackbar here
        onCaptureThumbnail:
            (path, thumbPath, {required thumbnailSeekPosition}) =>
                _captureVideoThumbnail(
                  path,
                  thumbPath,
                  thumbnailSeekPosition: thumbnailSeekPosition,
                ),
      );

      if (context.mounted && result != null) {
        Navigator.pop(context); // Close progress dialog
        if (showSuccessSnackBar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${video.title} saved to Gallery successfully!'),
            ),
          );
        }
      }

      return result;
    } catch (e) {
      if (!context.mounted) {
        return selected != null ? DownloadSelection(selected, groupName) : null;
      }
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (e != 'Cancelled') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
      return selected != null ? DownloadSelection(selected, groupName) : null;
    } finally {
      progressNotifier.dispose();
      countNotifier.dispose();
      statusNotifier.dispose();
      totalNotifier.dispose();
    }
  }
}
