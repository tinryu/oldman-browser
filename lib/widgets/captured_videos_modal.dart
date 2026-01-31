import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/video_item.dart';

class CapturedVideosModal extends StatefulWidget {
  final List<VideoItem> videos;
  final List<VideoItem> onlineVideos;
  final Function(VideoItem) onAdd;
  final Function(VideoItem) onRemove;
  final Function(List<VideoItem>) onVideosUpdated;
  final VoidCallback onClear;
  final Function(int) onTabRequested;

  const CapturedVideosModal({
    super.key,
    required this.videos,
    required this.onlineVideos,
    required this.onAdd,
    required this.onRemove,
    required this.onVideosUpdated,
    required this.onClear,
    required this.onTabRequested,
  });

  @override
  State<CapturedVideosModal> createState() => _CapturedVideosModalState();
}

class _CapturedVideosModalState extends State<CapturedVideosModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Captured Video Streams',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '(${widget.videos.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'items added',
                  icon: Badge(
                    padding: const EdgeInsets.all(2),
                    backgroundColor: Colors.white,
                    offset: const Offset(-21, 4),
                    label: Text(
                      '${widget.onlineVideos.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                  onPressed: () {
                    if (widget.onlineVideos.isNotEmpty) {
                      Navigator.pop(context); // Close the modal
                      widget.onTabRequested(2); // Switch to Onlines tab
                    }
                  },
                ),
                if (widget.videos.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear All',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: widget.onClear,
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.videos.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final video = widget.videos[index];
                final isAdded = widget.onlineVideos.any(
                  (v) => v.url == video.url,
                );
                return ExpandableVideoItem(
                  video: video,
                  initialIsAdded: isAdded,
                  onAdd: () {
                    widget.onAdd(video);
                    setState(() {});
                  },
                  onRemove: () {
                    widget.onRemove(video);
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandableVideoItem extends StatefulWidget {
  final VideoItem video;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool initialIsAdded;

  const ExpandableVideoItem({
    super.key,
    required this.video,
    required this.onAdd,
    required this.onRemove,
    this.initialIsAdded = false,
  });

  @override
  State<ExpandableVideoItem> createState() => _ExpandableVideoItemState();
}

class _ExpandableVideoItemState extends State<ExpandableVideoItem> {
  bool _isExpanded = false;
  late bool _isAdded;

  @override
  void initState() {
    super.initState();
    _isAdded = widget.initialIsAdded;
  }

  // Media Kit
  Player? _player;
  VideoController? _videoController;

  void _initPlayer() {
    if (Platform.isWindows) {
      _player = Player();
      _videoController = VideoController(_player!);
      _player!.setVolume(0); // Mute trial by default
      _player!.open(Media(widget.video.url));
    }
  }

  void _disposePlayer() {
    _player?.dispose();
    _player = null;
    _videoController = null;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: widget.video.thumbnailUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.video.thumbnailUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.movie_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.movie_outlined, color: Colors.grey),
                ),
          title: Text(
            widget.video.title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            widget.video.url,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              _isAdded ? Icons.check_circle : Icons.add_circle,
              color: _isAdded ? Colors.green : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isAdded = !_isAdded;
              });
              if (_isAdded) {
                widget.onAdd();
              } else {
                widget.onRemove();
              }
            },
          ),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _initPlayer();
              } else {
                _disposePlayer();
              }
            });
          },
        ),
        if (_isExpanded)
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _videoController != null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Video(controller: _videoController!),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE TRIAL',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ),
      ],
    );
  }
}
