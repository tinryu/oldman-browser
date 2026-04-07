// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk;
import 'package:y_player/y_player.dart';
import '../../models/yt/video.dart';
import '../../providers/youtube_provider.dart';
import '../../widgets/yt/video_card.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late final Player player;
  late final mk.VideoController controller;
  bool _isLoadingStream = false;
  String? _streamError;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      player = Player();
      controller = mk.VideoController(player);
      _loadStream();
    }
  }

  Future<void> _loadStream() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStream = true;
      _streamError = null;
    });

    try {
      final apiService = ref.read(youtubeApiServiceProvider);
      final streamUrl = await apiService.getVideoStreamUrl(widget.video.id);

      if (streamUrl != null) {
        await player.open(Media(streamUrl));
      } else {
        if (mounted)
          setState(() => _streamError = "Failed to extract stream URL");
      }
    } catch (e) {
      if (mounted) setState(() => _streamError = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStream = false);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      player.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsyncValue = ref.watch(videoStatisticsProvider(widget.video.id));
    final relatedAsyncValue = ref.watch(relatedVideosProvider(widget.video));
    final videoUrl = 'https://www.youtube.com/watch?v=${widget.video.id}';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Player Area
          if (Platform.isWindows)
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width * 9 / 16,
              child: Stack(
                children: [
                  mk.Video(controller: controller),
                  if (_isLoadingStream)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                  if (_streamError != null)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          Text(
                            _streamError!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            YPlayer(youtubeUrl: videoUrl, color: Colors.red, autoPlay: true),

          // Video Details Area
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      statsAsyncValue.when(
                        data: (stats) => Text(
                          '${stats?.viewCount ?? 0} views • ${widget.video.publishedAt.split('T').first}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        loading: () => const Text(
                          'Loading views...',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        error: (error, stackTrace) => const Text(
                          'Error loading views',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.video.channelTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const Text(
                                  'Channel Description',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'SUBSCRIBE',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text(
                        'Related Videos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Related Videos List
                relatedAsyncValue.when(
                  data: (videos) => Column(
                    children: videos.map((v) => VideoCard(video: v)).toList(),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                  error: (err, stackTrace) =>
                      Center(child: Text('Error loading related videos: $err')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
