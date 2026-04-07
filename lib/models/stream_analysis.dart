/// Represents a single detected media stream found during analysis.
class DetectedStream {
  final String url;
  final String type; // 'HLS', 'DASH', 'Progressive', 'MSE', 'WebRTC', etc.
  final String format; // 'm3u8', 'mpd', 'mp4', 'webm', etc.
  final String? contentType;
  final String? resolution;
  final String source; // 'network', 'dom', 'mse', 'service_worker'

  const DetectedStream({
    required this.url,
    required this.type,
    required this.format,
    this.contentType,
    this.resolution,
    this.source = 'network',
  });

  factory DetectedStream.fromJson(Map<String, dynamic> json) {
    return DetectedStream(
      url: json['url'] ?? '',
      type: json['type'] ?? 'Unknown',
      format: json['format'] ?? 'unknown',
      contentType: json['contentType'],
      resolution: json['resolution'],
      source: json['source'] ?? 'network',
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type,
        'format': format,
        'contentType': contentType,
        'resolution': resolution,
        'source': source,
      };
}

/// The full analysis report for a URL.
class StreamAnalysisReport {
  final String url;
  final String pageTitle;
  final DateTime analyzedAt;
  final Duration analysisDuration;
  final List<DetectedStream> streams;
  final bool usesHLS;
  final bool usesDASH;
  final bool usesProgressiveMP4;
  final bool usesMSE;
  final bool usesWebRTC;
  final bool usesDRM;
  final bool usesServiceWorker;
  final Map<String, int> techSummary; // e.g. {'HLS': 3, 'DASH': 1}
  final List<String> detectedCDNs;
  final String? playerLibrary; // 'hls.js', 'dash.js', 'video.js', 'shaka', etc.

  const StreamAnalysisReport({
    required this.url,
    required this.pageTitle,
    required this.analyzedAt,
    required this.analysisDuration,
    required this.streams,
    required this.usesHLS,
    required this.usesDASH,
    required this.usesProgressiveMP4,
    required this.usesMSE,
    required this.usesWebRTC,
    required this.usesDRM,
    required this.usesServiceWorker,
    required this.techSummary,
    required this.detectedCDNs,
    this.playerLibrary,
  });

  factory StreamAnalysisReport.fromJson(Map<String, dynamic> json) {
    return StreamAnalysisReport(
      url: json['url'] ?? '',
      pageTitle: json['pageTitle'] ?? '',
      analyzedAt: DateTime.now(),
      analysisDuration: Duration(
        milliseconds: json['analysisDurationMs'] ?? 0,
      ),
      streams: (json['streams'] as List<dynamic>?)
              ?.map(
                (s) => DetectedStream.fromJson(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
      usesHLS: json['usesHLS'] ?? false,
      usesDASH: json['usesDASH'] ?? false,
      usesProgressiveMP4: json['usesProgressiveMP4'] ?? false,
      usesMSE: json['usesMSE'] ?? false,
      usesWebRTC: json['usesWebRTC'] ?? false,
      usesDRM: json['usesDRM'] ?? false,
      usesServiceWorker: json['usesServiceWorker'] ?? false,
      techSummary: Map<String, int>.from(json['techSummary'] ?? {}),
      detectedCDNs: List<String>.from(json['detectedCDNs'] ?? []),
      playerLibrary: json['playerLibrary'],
    );
  }

  String get primaryTech {
    if (usesHLS) return 'HLS (HTTP Live Streaming)';
    if (usesDASH) return 'DASH (Dynamic Adaptive Streaming)';
    if (usesProgressiveMP4) return 'Progressive Download';
    if (usesMSE) return 'Media Source Extensions';
    if (usesWebRTC) return 'WebRTC';
    return 'Unknown';
  }

  int get totalStreams => streams.length;
}
