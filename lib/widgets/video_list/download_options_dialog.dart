import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class DownloadOptionsDialog extends StatefulWidget {
  final List<String> options;
  final VideoController videoController;
  final TextEditingController groupNameController;
  final String? preferredQuality;

  const DownloadOptionsDialog({
    super.key,
    required this.options,
    required this.videoController,
    required this.groupNameController,
    this.preferredQuality,
  });

  @override
  State<DownloadOptionsDialog> createState() => _DownloadOptionsDialogState();
}

class _DownloadOptionsDialogState extends State<DownloadOptionsDialog> {
  late String? _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected =
        widget.preferredQuality ??
        (widget.options.isNotEmpty ? widget.options.first : null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  'Download Options',
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
            const SizedBox(height: 15),
            TextField(
              controller: widget.groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name (Album)',
                hintText: 'Optional',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.black,
                    child: Video(controller: widget.videoController),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Select Quality:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.options.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final isSel = _tempSelected == option;
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: TextStyle(
                        color: isSel ? theme.colorScheme.primary : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: isSel
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _tempSelected = option;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _tempSelected),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Download'),
            ),
          ],
        ),
      ),
    );
  }
}
