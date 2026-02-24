import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:gal/gal.dart';
import '../models/video_item.dart';

class DownloadSelection {
  final String quality;
  final String? groupName;
  DownloadSelection(this.quality, this.groupName);
}

/// A service class that handles the downloading and processing of HLS video streams.
class DownloadService {
  static final Dio _dio = Dio();

  /// Returns the appropriate downloads directory based on the platform.
  static Future<Directory> getDownloadsDir() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return Directory('${dir?.path}/downloads');
    }
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, 'downloads'));
  }

  /// Sanitizes a folder name by removing illegal characters.
  static String sanitizeFolderName(final String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  /// Validates if a given URL points to a valid M3U8 manifest.
  static Future<bool> validateM3U8(final String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      return response.data.toString().contains('#EXTM3U');
    } catch (e) {
      return false;
    }
  }

  /// Downloads an HLS video stream, merges segments, and optionally captures a thumbnail.
  ///
  /// Returns a [DownloadSelection] object if the download was initiated, or null if cancelled.
  static Future<DownloadSelection?> downloadHLSVideo({
    required final BuildContext context,
    required final VideoItem video,
    required final String? selected,
    required final String? groupName,
    required final Duration thumbnailSeekPosition,
    required final ValueNotifier<double> progressNotifier,
    required final ValueNotifier<int> countNotifier,
    required final ValueNotifier<String> statusNotifier,
    required final ValueNotifier<int> totalNotifier,
    required final CancelToken cancelToken,
    final bool showSuccessSnackBar = true,
    final String queueProgress = '',
    final Future<String?> Function(
      String,
      String, {
      required Duration thumbnailSeekPosition,
    })?
    onCaptureThumbnail,
  }) async {
    try {
      statusNotifier.value = 'Analyzing manifest...';
      final uri = Uri.parse(video.url);

      // Safe origin extraction
      String? origin;
      try {
        if (uri.hasScheme && uri.hasAuthority) {
          origin = uri.origin;
        }
      } catch (_) {}

      _dio.options.headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': video.url,
        if (origin != null) 'Origin': origin,
      };

      // SSL bypass for some hosts
      // ignore: deprecated_member_use
      if (_dio.httpClientAdapter is IOHttpClientAdapter) {
        // ignore: deprecated_member_use
        (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };
      }

      final response = await _dio.get(
        video.url,
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 404) {
        throw 'Video not found (404)';
      }

      final manifest = await HlsPlaylistParser.create().parseString(
        uri,
        response.data.toString(),
      );

      List<Segment> segments = [];
      Uri baseUri = uri;

      if (manifest is HlsMasterPlaylist) {
        if (manifest.variants.isEmpty) throw 'No variants found';

        // Sort variants by bitrate descending
        final variants = List.of(manifest.variants);
        variants.sort(
          (a, b) => (b.format.bitrate ?? 0).compareTo(a.format.bitrate ?? 0),
        );

        final options = variants
            .map(
              (v) =>
                  '${v.format.width}x${v.format.height} - ${(v.format.bitrate ?? 0) ~/ 1000} kbps',
            )
            .toList();

        int selectedIndex = 0;
        if (selected != null) {
          selectedIndex = options.indexOf(selected);
          if (selectedIndex == -1) selectedIndex = 0;
        }

        final selectedVariant = variants[selectedIndex];
        final variantUri = uri.resolve(selectedVariant.url.toString());
        baseUri = variantUri;

        final variantResponse = await _dio.get(
          variantUri.toString(),
          options: Options(responseType: ResponseType.plain),
        );
        final variantManifest = await HlsPlaylistParser.create().parseString(
          variantUri,
          variantResponse.data.toString(),
        );

        if (variantManifest is HlsMediaPlaylist) {
          segments = variantManifest.segments;
        }
      } else if (manifest is HlsMediaPlaylist) {
        segments = manifest.segments;
      }

      if (segments.isEmpty) throw 'No video segments found';

      final downloadsDir = await getDownloadsDir();
      final sanitizedTitle = sanitizeFolderName(video.title);
      final sanitizedGroup = groupName != null
          ? sanitizeFolderName(groupName)
          : null;

      final String path = sanitizedGroup != null
          ? p.join(downloadsDir.path, sanitizedGroup, sanitizedTitle)
          : p.join(downloadsDir.path, sanitizedTitle);

      final videoDir = Directory(path);
      if (!await videoDir.exists()) await videoDir.create(recursive: true);

      final total = segments.length;
      totalNotifier.value = total;
      final thumbPath = p.join(videoDir.path, 'thumbnail.jpg');
      final outputPath = p.join(videoDir.path, 'output.mp4');

      // Check for initialization segment (fMP4)
      String? initPath;
      if (segments.isNotEmpty && segments.first.initializationSegment != null) {
        final initSegment = segments.first.initializationSegment!;
        final initUrl = baseUri.resolve(initSegment.url.toString()).toString();
        initPath = p.join(videoDir.path, 'init.mp4');
        await _dio.download(initUrl, initPath, cancelToken: cancelToken);
      }

      int downloaded = 0;
      final config = DownloadSelection(selected ?? 'auto', groupName);

      statusNotifier.value = 'Downloading...';

      // Download segments in parallel (max 5 concurrent)
      const int maxConcurrent = 5;
      for (int i = 0; i < segments.length; i += maxConcurrent) {
        if (cancelToken.isCancelled) throw 'Cancelled';

        final end = (i + maxConcurrent < segments.length)
            ? i + maxConcurrent
            : segments.length;
        final batch = segments.sublist(i, end);

        await Future.wait(
          batch.map((segment) async {
            final segmentUrlString = segment.url;
            if (segmentUrlString == null) return;

            final segmentUrl = baseUri.resolve(segmentUrlString).toString();
            final segmentFileName = segmentUrlString
                .split('/')
                .last
                .split('?')
                .first;
            final segmentFile = File(p.join(videoDir.path, segmentFileName));

            int retries = 3;
            bool success = false;
            dynamic lastError;

            while (retries > 0 && !success) {
              if (cancelToken.isCancelled) throw 'Cancelled';
              try {
                await _dio.download(
                  segmentUrl,
                  segmentFile.path,
                  cancelToken: cancelToken,
                );
                if (await segmentFile.exists() &&
                    await segmentFile.length() > 0) {
                  success = true;
                } else {
                  retries--;
                  if (retries > 0) {
                    await Future.delayed(const Duration(seconds: 1));
                  }
                }
              } catch (e) {
                lastError = e;
                retries--;
                if (retries > 0 && !cancelToken.isCancelled) {
                  await Future.delayed(const Duration(seconds: 1));
                }
              }
            }

            if (!success) {
              throw 'Failed to download segment $segmentFileName: $lastError';
            }

            downloaded++;
            progressNotifier.value = downloaded / total;
            countNotifier.value = downloaded;
          }),
        );
      }

      statusNotifier.value = 'Merging segments into MP4...';
      final outputFile = File(outputPath);
      final raf = await outputFile.open(mode: FileMode.write);

      try {
        if (initPath != null) {
          final initFile = File(initPath);
          if (await initFile.exists()) {
            final bytes = await initFile.readAsBytes();
            await raf.writeFrom(bytes);
            await initFile.delete();
          }
        }

        for (final segment in segments) {
          final segmentUrlString = segment.url;
          if (segmentUrlString != null) {
            final segmentFileName = segmentUrlString
                .split('/')
                .last
                .split('?')
                .first;
            final segmentPath = p.join(videoDir.path, segmentFileName);
            final segmentFile = File(segmentPath);
            if (await segmentFile.exists()) {
              final bytes = await segmentFile.readAsBytes();
              await raf.writeFrom(bytes);
              await segmentFile.delete();
            }
          }
        }
      } finally {
        await raf.close();
      }

      // Capture thumbnail if callback provided
      if (!await File(thumbPath).exists() && onCaptureThumbnail != null) {
        statusNotifier.value = 'Capturing thumbnail...';
        await onCaptureThumbnail(
          outputPath,
          thumbPath,
          thumbnailSeekPosition: thumbnailSeekPosition,
        );
      }

      statusNotifier.value = 'Exporting to Gallery...';
      // ignore: undefined_identifier
      await Gal.putVideo(outputPath, album: groupName);

      return config;
    } catch (e) {
      if (e == 'Cancelled') rethrow;
      rethrow;
    }
  }
}
