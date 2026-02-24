import 'package:flutter/material.dart';
import '../../models/video_item.dart';

class DownloadProgressDialog extends StatelessWidget {
  final VideoItem video;
  final ValueNotifier<double> progressNotifier;
  final ValueNotifier<int> countNotifier;
  final ValueNotifier<String> statusNotifier;
  final ValueNotifier<int> totalNotifier;
  final String queueProgress;
  final VoidCallback onCancel;

  const DownloadProgressDialog({
    super.key,
    required this.video,
    required this.progressNotifier,
    required this.countNotifier,
    required this.statusNotifier,
    required this.totalNotifier,
    this.queueProgress = '',
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        progressNotifier,
        countNotifier,
        statusNotifier,
        totalNotifier,
      ]),
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      statusNotifier.value == 'Downloading...'
                          ? '${queueProgress}Downloading'
                          : '$queueProgress${statusNotifier.value}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${(progressNotifier.value * 100).toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                video.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (statusNotifier.value == 'Downloading...') ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressNotifier.value,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${countNotifier.value} / ${totalNotifier.value} segments',
                  style: theme.textTheme.bodySmall,
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(statusNotifier.value),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: theme.colorScheme.error),
                    foregroundColor: theme.colorScheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel Download'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
