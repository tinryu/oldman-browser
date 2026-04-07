import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stream_analysis.dart';
import '../services/stream_analysis_service.dart';

class StreamAnalyzerScreen extends StatefulWidget {
  const StreamAnalyzerScreen({super.key});

  @override
  State<StreamAnalyzerScreen> createState() => _StreamAnalyzerScreenState();
}

class _StreamAnalyzerScreenState extends State<StreamAnalyzerScreen>
    with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  StreamAnalysisReport? _report;
  bool _isAnalyzing = false;
  String _statusMessage = 'Enter a URL to analyze';
  double _progress = 0.0;
  DateTime? _analysisStartTime;
  Timer? _progressTimer;
  Timer? _statusPollTimer;

  bool? _isServerReady;
  bool _isCheckingServer = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkServerStatus();
    // Poll every 10 seconds to keep status updated
    _statusPollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkServerStatus());
  }

  Future<void> _checkServerStatus() async {
    if (_isAnalyzing || _isCheckingServer) return;
    
    setState(() => _isCheckingServer = true);
    try {
      final isReady = await StreamAnalysisService.pingServer();
      if (mounted) {
        setState(() {
          _isServerReady = isReady;
          _isCheckingServer = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isServerReady = false;
          _isCheckingServer = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _progressTimer?.cancel();
    _statusPollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    String finalUrl = url;
    if (!url.startsWith('http')) {
      finalUrl = 'https://$url';
    }

    setState(() {
      _isAnalyzing = true;
      _report = null;
      _progress = 0.0;
      _statusMessage = 'Connecting to external analyzer...';
      _analysisStartTime = DateTime.now();
    });

    unawaited(_pulseController.repeat(reverse: true));

    // Start faking progress
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isAnalyzing) {
        timer.cancel();
        return;
      }
      if (mounted) {
        setState(() {
          _progress = (_progress + 0.02).clamp(0.0, 0.95);
        });
      }
    });

    try {
      final reportData = await StreamAnalysisService.analyzeUrl(finalUrl);
      
      if (mounted) {
        final duration = _analysisStartTime != null
            ? DateTime.now().difference(_analysisStartTime!)
            : Duration.zero;
            
        final Map<String, dynamic> data = reportData['data'] is Map<String, dynamic> 
            ? reportData['data'] 
            : Map<String, dynamic>.from(reportData['data']);
            
        data['analysisDurationMs'] = duration.inMilliseconds;
        
        setState(() {
          _isAnalyzing = false;
          _progress = 1.0;
          _report = StreamAnalysisReport.fromJson(data);
          
          if (_report!.streams.isEmpty) {
            _statusMessage = 'Analysis complete. No streams detected.';
          } else {
            _statusMessage = 'Analysis complete. Found ${_report!.streams.length} stream(s).';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _progress = 0.0;
          _statusMessage = 'Analysis failed. $e';
        });
      }
    } finally {
      if (mounted) {
        _pulseController.stop();
        unawaited(_pulseController.forward());
        _progressTimer?.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_rounded,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Stream Analyzer',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          _buildServerStatusWidget(theme, isDark),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // URL Input Bar
          _buildUrlInputBar(theme, isDark),

          // Progress Indicator
          if (_isAnalyzing)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: theme.colorScheme.surface,
              color: theme.colorScheme.primary,
              minHeight: 2,
            ),

          // Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_isAnalyzing)
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.greenAccent.shade400,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withAlpha(100),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Report Content
          Expanded(
            child: _report != null
                ? _buildReport(theme, isDark)
                : _buildEmptyState(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildServerStatusWidget(ThemeData theme, bool isDark) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (_isServerReady == null) {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline_rounded;
      statusText = 'Checking...';
    } else if (_isServerReady!) {
      statusColor = Colors.greenAccent.shade400;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Node Online';
    } else {
      statusColor = Colors.redAccent.shade400;
      statusIcon = Icons.error_outline_rounded;
      statusText = 'Node Offline';
    }

    return Tooltip(
      message: 'Analyzer Server Status',
      child: GestureDetector(
        onTap: _checkServerStatus,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withAlpha(60)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCheckingServer)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                )
              else
                Icon(statusIcon, size: 12, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlInputBar(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(10)
            : Colors.black.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(15)
              : Colors.black.withAlpha(15),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.link_rounded,
            size: 16,
            color: theme.colorScheme.primary.withAlpha(180),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _urlController,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Enter URL to analyze (e.g. https://example.com)',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(80),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _startAnalysis(),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _isAnalyzing ? null : _startAnalysis,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isAnalyzing
                        ? [Colors.grey, Colors.grey.shade700]
                        : [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withAlpha(200),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAnalyzing
                          ? Icons.hourglass_top_rounded
                          : Icons.search_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isAnalyzing ? 'Scanning...' : 'Analyze',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.radar_rounded,
            size: 64,
            color: theme.colorScheme.primary.withAlpha(60),
          ),
          const SizedBox(height: 16),
          Text(
            'Stream Technology Scanner',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detects HLS, DASH, MSE, DRM, WebRTC,\nplayer libraries, CDNs, and more',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withAlpha(100),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // Quick test URLs
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickUrl('YouTube', 'https://www.youtube.com', theme),
              _buildQuickUrl(
                  'Vimeo', 'https://vimeo.com/channels/staffpicks', theme),
              _buildQuickUrl(
                  'Dailymotion', 'https://www.dailymotion.com', theme),
              _buildQuickUrl(
                  'Twitch', 'https://www.twitch.tv', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickUrl(String label, String url, ThemeData theme) {
    return ActionChip(
      avatar: Icon(Icons.open_in_new_rounded,
          size: 12, color: theme.colorScheme.primary),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        _urlController.text = url;
        _startAnalysis();
      },
      backgroundColor: theme.colorScheme.primary.withAlpha(20),
      side: BorderSide(color: theme.colorScheme.primary.withAlpha(40)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildReport(ThemeData theme, bool isDark) {
    final report = _report!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview Card
        _buildOverviewCard(report, theme, isDark),
        const SizedBox(height: 12),

        // Technologies Detected
        _buildTechDetectionCard(report, theme, isDark),
        const SizedBox(height: 12),

        // Player Library
        if (report.playerLibrary != null) ...[
          _buildInfoCard(
            icon: Icons.play_circle_outline_rounded,
            title: 'Player Library',
            value: report.playerLibrary!,
            color: Colors.blue,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
        ],

        // CDNs
        if (report.detectedCDNs.isNotEmpty) ...[
          _buildCDNCard(report, theme, isDark),
          const SizedBox(height: 12),
        ],

        // Streams List
        if (report.streams.isNotEmpty) ...[
          _buildStreamsCard(report, theme, isDark),
        ],
      ],
    );
  }

  Widget _buildOverviewCard(
      StreamAnalysisReport report, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.primary.withAlpha(25),
                  theme.colorScheme.primary.withAlpha(10),
                ]
              : [
                  theme.colorScheme.primary.withAlpha(15),
                  theme.colorScheme.primary.withAlpha(5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.summarize_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Report',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (report.pageTitle.isNotEmpty)
                      Text(
                        report.pageTitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withAlpha(130),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatChip(
                'Primary',
                report.primaryTech,
                Icons.stream_rounded,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip(
                'Streams',
                report.totalStreams.toString(),
                Icons.playlist_play_rounded,
                theme,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                'Duration',
                '${report.analysisDuration.inSeconds}s',
                Icons.timer_outlined,
                theme,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                'CDNs',
                report.detectedCDNs.length.toString(),
                Icons.dns_rounded,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      String label, String value, IconData icon, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.onSurface.withAlpha(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechDetectionCard(
      StreamAnalysisReport report, ThemeData theme, bool isDark) {
    final techs = [
      _TechItem('HLS', 'HTTP Live Streaming', Icons.live_tv_rounded,
          report.usesHLS, Colors.orange),
      _TechItem('DASH', 'Dynamic Adaptive Streaming', Icons.speed_rounded,
          report.usesDASH, Colors.blue),
      _TechItem('Progressive', 'Direct Download', Icons.download_rounded,
          report.usesProgressiveMP4, Colors.green),
      _TechItem('MSE', 'Media Source Extensions', Icons.extension_rounded,
          report.usesMSE, Colors.purple),
      _TechItem('WebRTC', 'Real-Time Communication', Icons.videocam_rounded,
          report.usesWebRTC, Colors.teal),
      _TechItem('DRM', 'Digital Rights Management', Icons.lock_rounded,
          report.usesDRM, Colors.red),
      _TechItem('SW', 'Service Worker', Icons.engineering_rounded,
          report.usesServiceWorker, Colors.amber),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(6)
            : Colors.black.withAlpha(4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(10)
              : Colors.black.withAlpha(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded,
                  size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Technology Detection',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: techs.map((t) => _buildTechBadge(t, theme)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTechBadge(_TechItem tech, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tech.detected
            ? tech.color.withAlpha(25)
            : theme.colorScheme.onSurface.withAlpha(5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tech.detected
              ? tech.color.withAlpha(80)
              : theme.colorScheme.onSurface.withAlpha(15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tech.detected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: tech.detected
                ? tech.color
                : theme.colorScheme.onSurface.withAlpha(60),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tech.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tech.detected
                      ? tech.color
                      : theme.colorScheme.onSurface.withAlpha(100),
                ),
              ),
              Text(
                tech.description,
                style: TextStyle(
                  fontSize: 8,
                  color: theme.colorScheme.onSurface.withAlpha(80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(6)
            : Colors.black.withAlpha(4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(10)
              : Colors.black.withAlpha(10),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCDNCard(
      StreamAnalysisReport report, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(6)
            : Colors.black.withAlpha(4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(10)
              : Colors.black.withAlpha(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns_rounded,
                  size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Content Delivery Networks',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: report.detectedCDNs.map((cdn) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.cyan.withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.cyan.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_outlined,
                        size: 12, color: Colors.cyan.shade300),
                    const SizedBox(width: 4),
                    Text(
                      cdn,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.cyan.shade200,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamsCard(
      StreamAnalysisReport report, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(6)
            : Colors.black.withAlpha(4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(10)
              : Colors.black.withAlpha(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.playlist_play_rounded,
                  size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Detected Streams (${report.streams.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...report.streams.asMap().entries.map((entry) {
            final idx = entry.key;
            final stream = entry.value;
            return _buildStreamItem(idx, stream, theme, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildStreamItem(
      int index, DetectedStream stream, ThemeData theme, bool isDark) {
    Color typeColor;
    switch (stream.type) {
      case 'HLS':
        typeColor = Colors.orange;
        break;
      case 'DASH':
        typeColor = Colors.blue;
        break;
      case 'Progressive':
        typeColor = Colors.green;
        break;
      default:
        typeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(5)
            : Colors.black.withAlpha(3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: typeColor.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stream.type,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '.${stream.format}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stream.source,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withAlpha(60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            stream.url,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface.withAlpha(160),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _TechItem {
  final String name;
  final String description;
  final IconData icon;
  final bool detected;
  final Color color;

  _TechItem(this.name, this.description, this.icon, this.detected, this.color);
}
