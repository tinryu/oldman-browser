import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/webview_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const VideoPlayerScreen({super.key, required this.videoUrl, this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;

  @override
  void initState() {
    super.initState();
    _initMediaKit();
  }

  void _initMediaKit() {
    _player = Player();
    _videoController = VideoController(_player);
    _player.open(Media(widget.videoUrl));
  }

  void _showSpeedSelector(BuildContext context) async {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(
          renderBox.size.bottomLeft(Offset.zero),
          ancestor: overlay,
        ),
        renderBox.localToGlobal(
          renderBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentRate = _player.state.rate;

    final speed = await showMenu<double>(
      context: context,
      position: position,
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: speeds.map((speed) {
        final isSelected = currentRate == speed;
        return PopupMenuItem<double>(
          value: speed,
          child: Text(
            '${speed}x',
            style: TextStyle(
              color: isSelected ? Colors.greenAccent : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );

    if (speed != null) {
      await _player.setRate(speed);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Video Player',
          style: const TextStyle(color: Colors.white12, fontSize: 10),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        toolbarHeight: 45,
        elevation: 0,
      ),
      body: !WebviewService.isWindows
          ? MaterialVideoControlsTheme(
              normal: MaterialVideoControlsThemeData(
                // Modify theme options:
                seekBarThumbColor: Theme.of(context).primaryColor,
                seekBarPositionColor: Theme.of(context).primaryColor,
                buttonBarButtonSize: 24.0,
                buttonBarButtonColor: Colors.white,
                // Modify top button bar:
                topButtonBar: [
                  const Spacer(),
                  Builder(
                    builder: (context) => MaterialDesktopCustomButton(
                      onPressed: () => _showSpeedSelector(context),
                      icon: const Icon(Icons.speed),
                    ),
                  ),
                ],
                bottomButtonBar: [
                  const MaterialPositionIndicator(),
                  const Spacer(),
                  MaterialDesktopCustomButton(
                    onPressed: () => _player.seek(
                      _player.state.position - const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                  ),
                  const MaterialPlayOrPauseButton(),
                  MaterialDesktopCustomButton(
                    onPressed: () => _player.seek(
                      _player.state.position + const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                  ),
                  const Spacer(),
                  const MaterialFullscreenButton(),
                ],
              ),
              fullscreen: MaterialVideoControlsThemeData(
                topButtonBar: [
                  const Spacer(),
                  Builder(
                    builder: (context) => MaterialDesktopCustomButton(
                      onPressed: () => _showSpeedSelector(context),
                      icon: const Icon(Icons.speed),
                    ),
                  ),
                ],
                bottomButtonBar: [
                  const MaterialPositionIndicator(),
                  const Spacer(),
                  MaterialDesktopCustomButton(
                    onPressed: () => _player.seek(
                      _player.state.position - const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                  ),
                  const MaterialPlayOrPauseButton(),
                  MaterialDesktopCustomButton(
                    onPressed: () => _player.seek(
                      _player.state.position + const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                  ),
                  const Spacer(),
                  const MaterialFullscreenButton(),
                ],
              ),
              child: Scaffold(body: Video(controller: _videoController)),
            )
          : MaterialDesktopVideoControlsTheme(
              normal: MaterialDesktopVideoControlsThemeData(
                // Modify theme options:
                seekBarThumbColor: Theme.of(context).primaryColor,
                seekBarPositionColor: Theme.of(context).primaryColor,
                buttonBarButtonSize: 24.0,
                buttonBarButtonColor: Colors.white,
                // Modify top button bar:
                topButtonBar: [
                  const Spacer(),
                  Builder(
                    builder: (context) => MaterialDesktopCustomButton(
                      onPressed: () => _showSpeedSelector(context),
                      icon: const Icon(Icons.speed),
                    ),
                  ),
                ],
                bottomButtonBar: <Widget>[
                  const MaterialDesktopVolumeButton(),
                  const MaterialDesktopPositionIndicator(),
                  const Spacer(),
                  MaterialDesktopCustomButton(
                    onPressed: () => _player.seek(
                      _player.state.position - const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                  ),
                  const MaterialDesktopPlayOrPauseButton(),
                  MaterialDesktopCustomButton(
                    onPressed: () => _player.seek(
                      _player.state.position + const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                  ),
                  const Spacer(),
                  const MaterialDesktopFullscreenButton(),
                ],
              ),
              fullscreen: MaterialDesktopVideoControlsThemeData(
                topButtonBar: [
                  const Spacer(),
                  Builder(
                    builder: (context) => MaterialDesktopCustomButton(
                      onPressed: () => _showSpeedSelector(context),
                      icon: const Icon(Icons.speed),
                    ),
                  ),
                ],
                bottomButtonBar: [
                  const MaterialDesktopVolumeButton(),
                  const MaterialDesktopPositionIndicator(),
                  const Spacer(),
                  MaterialDesktopCustomButton(
                    onPressed: () => _player.seek(
                      _player.state.position - const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                  ),
                  const MaterialDesktopPlayOrPauseButton(),
                  MaterialDesktopCustomButton(
                    onPressed: () => _player.seek(
                      _player.state.position + const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                  ),
                  const Spacer(),
                  const MaterialDesktopFullscreenButton(),
                ],
              ),
              child: Scaffold(body: Video(controller: _videoController)),
            ),
    );
  }
}
