import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/video_item.dart';

class DownloadedVideoCard extends StatelessWidget {
  final VideoItem video;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onRename;
  final ThemeData theme;

  const DownloadedVideoCard({
    super.key,
    required this.video,
    required this.isSelected,
    required this.onTap,
    required this.onPlay,
    required this.onRename,
    required this.theme,
  });

  bool get _isMp4 => !video.url.toLowerCase().contains('.m3u8');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Container(
        decoration: BoxDecoration(
          image: video.thumbnailUrl != null
              ? DecorationImage(
                  image: video.thumbnailUrl!.startsWith('http')
                      ? NetworkImage(video.thumbnailUrl!)
                      : FileImage(File(video.thumbnailUrl!)) as ImageProvider,
                  fit: BoxFit.cover,
                  opacity: 0.5,
                )
              : null,
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          horizontalTitleGap: 20,
          leading: SizedBox(
            width: 100,
            height: 100,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                      image: video.thumbnailUrl != null
                          ? DecorationImage(
                              image: video.thumbnailUrl!.startsWith('http')
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
                            Icons.sd_card,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
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
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            onPressed: onPlay,
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
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _isMp4 ? 'MP4' : 'M3U8',
                              style: const TextStyle(
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                onPressed: onRename,
                tooltip: 'Rename',
              ),
            ],
          ),
          subtitle: Text(
            _isMp4 ? 'Format: MP4' : 'Format: HLS (m3u8)',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
