import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/video_item.dart';

/// Service class to handle file operations for downloaded videos
/// A service class that handles file operations for downloaded videos, including deletion and renaming.
class FileManagerService {
  /// Returns the appropriate downloads directory based on the platform.
  static Future<Directory> getDownloadsDir() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return Directory(p.join(dir?.path ?? '', 'downloads'));
    }
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, 'downloads'));
  }

  /// Deletes a video file and its associated directory.
  static Future<void> deleteVideo(final VideoItem video) async {
    try {
      final String videoDirString;
      if (video.url.startsWith('file://')) {
        // HLS
        final masterFile = File(video.url.replaceFirst('file://', ''));
        videoDirString = masterFile.parent.path;
      } else {
        // MP4
        final mp4File = File(video.url);
        videoDirString = mp4File.parent.path;
      }

      final videoDir = Directory(videoDirString);
      if (await videoDir.exists()) {
        await videoDir.delete(recursive: true);
      }

      // Try to clean up empty parent directory (Group directory)
      final downloadsDir = await getDownloadsDir();
      final parentDir = videoDir.parent;
      if (parentDir.path != downloadsDir.path) {
        if (await parentDir.exists() && parentDir.listSync().isEmpty) {
          await parentDir.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting ${video.title}: $e');
      rethrow;
    }
  }

  /// Renames a video directory or a general directory.
  static Future<void> renameItem({
    required final BuildContext context,
    required final dynamic item,
    required final VoidCallback onSuccess,
  }) async {
    final String currentPath;
    final String currentName;

    if (item is Directory) {
      currentPath = item.path;
      currentName = p.basename(item.path);
    } else if (item is VideoItem) {
      final String videoDirString;
      if (item.url.startsWith('file://')) {
        final masterFile = File(item.url.replaceFirst('file://', ''));
        videoDirString = masterFile.parent.path;
      } else {
        final mp4File = File(item.url);
        videoDirString = mp4File.parent.path;
      }
      currentPath = videoDirString;
      currentName = item.title;
    } else {
      return;
    }

    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == currentName) return;

    try {
      final parentDir = Directory(currentPath).parent;
      final newPath = p.join(parentDir.path, newName);

      if (await Directory(newPath).exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Name already exists')));
        }
        return;
      }

      await Directory(currentPath).rename(newPath);
      onSuccess();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error renaming: $e')));
      }
    }
  }
}
