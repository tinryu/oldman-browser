import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../models/video_item.dart';
import '../../models/video_metadata.dart';

class VideoInfoModal extends StatefulWidget {
  final VideoItem video;

  const VideoInfoModal({super.key, required this.video});

  static Future<void> show(BuildContext context, VideoItem video) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoInfoModal(video: video),
    );
  }

  @override
  State<VideoInfoModal> createState() => _VideoInfoModalState();
}

class _VideoInfoModalState extends State<VideoInfoModal> {
  VideoMetadata? _metadata;
  bool _isLoading = true;
  int? _fileSizeBytes;
  DateTime? _fileModifiedDate;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final videoPath = widget.video.url.startsWith('file://')
        ? widget.video.url.replaceFirst('file://', '')
        : widget.video.url;

    final mp4File = File(videoPath);
    String jsonPath;
    if (widget.video.url.startsWith('file://')) {
      jsonPath = p.join(mp4File.parent.path, '${widget.video.title}.json');
    } else {
      jsonPath = '${p.withoutExtension(videoPath)}.json';
    }

    final jsonFile = File(jsonPath);
    VideoMetadata? meta;
    if (await jsonFile.exists()) {
      meta = await VideoMetadata.loadFromFile(jsonFile);
    }

    int? size;
    DateTime? modified;
    if (await mp4File.exists()) {
      try {
        final stat = await mp4File.stat();
        size = stat.size;
        modified = stat.modified;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _metadata = meta;
        _fileSizeBytes = meta?.fileSizeBytes ?? size;
        _fileModifiedDate = meta?.downloadDate ?? modified;
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoPath = widget.video.url.startsWith('file://')
        ? widget.video.url.replaceFirst('file://', '')
        : widget.video.url;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle & Header
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Video Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Thumbnail preview if available
                  if (widget.video.thumbnailUrl != null)
                    Container(
                      height: 160,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black,
                        image: DecorationImage(
                          image: FileImage(File(widget.video.thumbnailUrl!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Title Card
                  _buildInfoRow(
                    context: context,
                    icon: Icons.title,
                    label: 'Title',
                    value: _metadata?.title ?? widget.video.title,
                  ),
                  const SizedBox(height: 14),

                  // Source URL (if available)
                  if (_metadata?.sourceUrl != null &&
                      _metadata!.sourceUrl.isNotEmpty) ...[
                    _buildInfoRow(
                      context: context,
                      icon: Icons.link,
                      label: 'Source URL',
                      value: _metadata!.sourceUrl,
                      onCopy: () => _copyToClipboard(
                        _metadata!.sourceUrl,
                        'Source URL',
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Quality / Resolution
                  if (_metadata?.quality != null) ...[
                    _buildInfoRow(
                      context: context,
                      icon: Icons.high_quality,
                      label: 'Quality / Resolution',
                      value: _metadata!.quality!,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Group Name (if available)
                  if (_metadata?.groupName != null) ...[
                    _buildInfoRow(
                      context: context,
                      icon: Icons.folder,
                      label: 'Group',
                      value: _metadata!.groupName!,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // File Size
                  if (_fileSizeBytes != null) ...[
                    _buildInfoRow(
                      context: context,
                      icon: Icons.data_usage,
                      label: 'File Size',
                      value: _formatFileSize(_fileSizeBytes!),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Download Date
                  if (_fileModifiedDate != null) ...[
                    _buildInfoRow(
                      context: context,
                      icon: Icons.calendar_today,
                      label: 'Download Date',
                      value: _formatDate(_fileModifiedDate!),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Local File Path
                  _buildInfoRow(
                    context: context,
                    icon: Icons.folder_special_outlined,
                    label: 'File Path',
                    value: videoPath,
                    onCopy: () => _copyToClipboard(videoPath, 'File path'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Copy',
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
