import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const VideoPlayerScreen({super.key, required this.videoUrl, this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // Better Player
  late BetterPlayerController _betterPlayerController;

  // Media Kit
  late final Player _player;
  late final VideoController _videoController;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      _initMediaKit();
    } else {
      _initBetterPlayer();
    }
  }

  void _initBetterPlayer() {
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.videoUrl,
      cacheConfiguration: const BetterPlayerCacheConfiguration(
        useCache: true,
        preCacheSize: 10 * 1024 * 1024,
        maxCacheSize: 200 * 1024 * 1024,
      ),
    );

    _betterPlayerController = BetterPlayerController(
      const BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: true,
      ),
      betterPlayerDataSource: dataSource,
    );
  }

  void _initMediaKit() {
    _player = Player();
    _videoController = VideoController(_player);
    _player.open(Media(widget.videoUrl));
  }

  Future<void> screenshot() async {
    try {
      Uint8List? data;
      if (_isDesktop) {
        data = await _player.screenshot();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screenshot not supported on this platform'),
            ),
          );
        }
        return;
      }

      if (data != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Screenshot Captured'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.memory(data!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take screenshot: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      _player.dispose();
    } else {
      _betterPlayerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Video Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: screenshot,
            tooltip: 'Take Screenshot',
          ),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _isDesktop
              ? Video(controller: _videoController)
              : BetterPlayer(controller: _betterPlayerController),
        ),
      ),
    );
  }
}
