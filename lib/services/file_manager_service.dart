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

  /// Deletes a video file and its associated files or directory.
  static Future<void> deleteVideo(final VideoItem video) async {
    try {
      if (video.url.startsWith('file://')) {
        // HLS
        final masterFile = File(video.url.replaceFirst('file://', ''));
        final videoDir = masterFile.parent;
        if (await videoDir.exists()) await videoDir.delete(recursive: true);
        await _cleanEmptyParentDir(videoDir.parent);
      } else {
        final mp4File = File(video.url);
        final parentDir = mp4File.parent;

        final isLegacyDir = p.basename(parentDir.path) == video.title &&
            (await File(p.join(parentDir.path, 'output.mp4')).exists() ||
                await File(p.join(parentDir.path, 'master.m3u8')).exists());

        if (isLegacyDir) {
          if (await parentDir.exists()) await parentDir.delete(recursive: true);
          await _cleanEmptyParentDir(parentDir.parent);
        } else {
          if (await mp4File.exists()) {
            await mp4File.delete();
          }
          final thumbFile = File('${p.withoutExtension(mp4File.path)}.jpg');
          if (await thumbFile.exists()) {
            await thumbFile.delete();
          }
          final jsonFile = File('${p.withoutExtension(mp4File.path)}.json');
          if (await jsonFile.exists()) {
            await jsonFile.delete();
          }
          await _cleanEmptyParentDir(parentDir);
        }
      }
    } catch (e) {
      debugPrint('Error deleting ${video.title}: $e');
      rethrow;
    }
  }

  static Future<void> _cleanEmptyParentDir(Directory parentDir) async {
    final downloadsDir = await getDownloadsDir();
    if (parentDir.path != downloadsDir.path) {
      if (await parentDir.exists() && parentDir.listSync().isEmpty) {
        await parentDir.delete();
      }
    }
  }

  /// Renames a video file, video directory, or a general directory.
  static Future<void> renameItem({
    required final BuildContext context,
    required final dynamic item,
    required final VoidCallback onSuccess,
  }) async {
    final String currentName;
    final bool isDirectFile;

    if (item is Directory) {
      currentName = p.basename(item.path);
      isDirectFile = false;
    } else if (item is VideoItem) {
      if (item.url.startsWith('file://')) {
        currentName = item.title;
        isDirectFile = false;
      } else {
        final mp4File = File(item.url);
        final parentDir = mp4File.parent;
        if (p.basename(parentDir.path) == item.title &&
            (await File(p.join(parentDir.path, 'output.mp4')).exists() ||
                await File(p.join(parentDir.path, 'master.m3u8')).exists())) {
          isDirectFile = false;
          currentName = item.title;
        } else {
          isDirectFile = true;
          currentName = p.basenameWithoutExtension(item.url);
        }
      }
    } else {
      return;
    }

    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      // ignore: use_build_context_synchronously
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

    if (!context.mounted) return;
    if (newName == null || newName.isEmpty || newName == currentName) return;

    try {
      if (isDirectFile && item is VideoItem) {
        final mp4File = File(item.url);
        final parentPath = mp4File.parent.path;
        final targetMp4 = File(p.join(parentPath, '$newName.mp4'));
        final thumbFile = File('${p.withoutExtension(mp4File.path)}.jpg');
        final targetThumb = File(p.join(parentPath, '$newName.jpg'));
        final jsonFile = File('${p.withoutExtension(mp4File.path)}.json');
        final targetJson = File(p.join(parentPath, '$newName.json'));

        if (await targetMp4.exists()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Name already exists')),
            );
          }
          return;
        }

        await mp4File.rename(targetMp4.path);
        if (await thumbFile.exists()) {
          await thumbFile.rename(targetThumb.path);
        }
        if (await jsonFile.exists()) {
          await jsonFile.rename(targetJson.path);
        }
      } else {
        final String currentPath = item is Directory
            ? item.path
            : (item.url.startsWith('file://')
                ? File(item.url.replaceFirst('file://', '')).parent.path
                : File(item.url).parent.path);

        final parentDir = Directory(currentPath).parent;
        final newPath = p.join(parentDir.path, newName);

        if (await Directory(newPath).exists()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Name already exists')),
            );
          }
          return;
        }

        final oldFolderName = p.basename(currentPath);
        await Directory(currentPath).rename(newPath);

        final oldNamedMp4 = File(p.join(newPath, '$oldFolderName.mp4'));
        final legacyMp4 = File(p.join(newPath, 'output.mp4'));
        final targetMp4Path = p.join(newPath, '$newName.mp4');

        if (await oldNamedMp4.exists()) {
          await oldNamedMp4.rename(targetMp4Path);
        } else if (await legacyMp4.exists()) {
          await legacyMp4.rename(targetMp4Path);
        }

        final oldNamedJson = File(p.join(newPath, '$oldFolderName.json'));
        final targetJsonPath = p.join(newPath, '$newName.json');
        if (await oldNamedJson.exists()) {
          await oldNamedJson.rename(targetJsonPath);
        }
      }

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
