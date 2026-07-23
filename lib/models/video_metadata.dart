import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Represents metadata for a downloaded video item.
class VideoMetadata {
  final String title;
  final String sourceUrl;
  final DateTime downloadDate;
  final String? quality;
  final String? groupName;
  final int? fileSizeBytes;

  VideoMetadata({
    required this.title,
    required this.sourceUrl,
    required this.downloadDate,
    this.quality,
    this.groupName,
    this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'sourceUrl': sourceUrl,
      'downloadDate': downloadDate.toIso8601String(),
      'quality': quality,
      'groupName': groupName,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      title: json['title'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      downloadDate: json['downloadDate'] != null
          ? DateTime.tryParse(json['downloadDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      quality: json['quality'] as String?,
      groupName: json['groupName'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
    );
  }

  /// Saves the metadata to a JSON file.
  Future<void> saveToFile(File jsonFile) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(toJson());
      await jsonFile.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving metadata to ${jsonFile.path}: $e');
    }
  }

  /// Loads metadata from a JSON file.
  static Future<VideoMetadata?> loadFromFile(File jsonFile) async {
    try {
      if (!await jsonFile.exists()) return null;
      final content = await jsonFile.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return VideoMetadata.fromJson(map);
    } catch (e) {
      debugPrint('Error loading metadata from ${jsonFile.path}: $e');
      return null;
    }
  }
}
