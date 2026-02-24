import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A service class that handles persistent storage of bookmarks and history.
class StorageService {
  static Future<File> get _bookmarksFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/bookmarks.json');
  }

  static Future<File> get _historyFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/history.json');
  }

  /// Loads the list of bookmarks from the local file system.
  static Future<List<Map<String, String>>> loadBookmarks() async {
    try {
      final file = await _bookmarksFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> json = jsonDecode(content);
        return json.map((final e) => Map<String, String>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
    return const [];
  }

  /// Saves the list of bookmarks to the local file system.
  static Future<void> saveBookmarks(
    final List<Map<String, String>> bookmarks,
  ) async {
    try {
      final file = await _bookmarksFile;
      await file.writeAsString(jsonEncode(bookmarks));
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  /// Loads the browsing history from the local file system.
  static Future<List<Map<String, String>>> loadHistory() async {
    try {
      final file = await _historyFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> json = jsonDecode(content);
        return json.map((final e) => Map<String, String>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
    return const [];
  }

  /// Saves the browsing history to the local file system.
  static Future<void> saveHistory(
    final List<Map<String, String>> history,
  ) async {
    try {
      final file = await _historyFile;
      await file.writeAsString(jsonEncode(history));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  /// Clears all bookmarks and history from the local file system.
  static Future<void> clearAllStorage() async {
    try {
      final bFile = await _bookmarksFile;
      if (await bFile.exists()) await bFile.delete();
      final hFile = await _historyFile;
      if (await hFile.exists()) await hFile.delete();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }
}
