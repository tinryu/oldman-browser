import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/video_item.dart';

class OnlineVideoCard extends StatelessWidget {
  final VideoItem video;
  final bool isSelected;
  final Function(bool?) onSelectedChanged;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onPlay;

  const OnlineVideoCard({
    super.key,
    required this.video,
    required this.isSelected,
    required this.onSelectedChanged,
    required this.onDownload,
    required this.onDelete,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    checkColor: theme.colorScheme.primary,
                    activeColor: theme.colorScheme.primary,
                    value: isSelected,
                    onChanged: onSelectedChanged,
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                onPressed: onPlay,
              ),
              IconButton(
                icon: Icon(
                  Icons.download_for_offline_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                onPressed: onDownload,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          onTap: () => onSelectedChanged(!isSelected),
        ),
      ),
    );
  }
}
