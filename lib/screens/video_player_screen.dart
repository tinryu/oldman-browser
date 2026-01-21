import 'dart:io';
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
      appBar: widget.title != null ? AppBar(title: Text(widget.title!)) : null,
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
