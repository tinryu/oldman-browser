import 'package:flutter/material.dart';
import 'stream_analyzer_screen.dart';
import 'youtube/home_screen.dart';

class ToolListScreen extends StatelessWidget {
  const ToolListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tools = [
      _ToolItem(
        title: 'Stream Analyzer',
        description:
            'Detect streaming tech of any website — HLS, DASH, MSE, DRM, player libraries, CDNs and more.',
        icon: Icons.analytics_rounded,
        gradient: [Colors.deepPurple, Colors.purpleAccent],
        tags: ['HLS', 'DASH', 'DRM', 'MSE'],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StreamAnalyzerScreen()),
        ),
      ),
      _ToolItem(
        title: 'Youtube API',
        description: 'Watch like app youtube',
        icon: Icons.podcasts,
        gradient: [Colors.red, Colors.redAccent],
        tags: ['Google-API', 'Youtube', 'Data-API-V3'],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return _buildToolCard(tool, theme, isDark);
        },
      ),
    );
  }

  Widget _buildToolCard(_ToolItem tool, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: tool.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tool.gradient[0].withAlpha(isDark ? 30 : 15),
              tool.gradient[1].withAlpha(isDark ? 15 : 8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tool.gradient[0].withAlpha(isDark ? 50 : 30),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tool.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: tool.gradient[0].withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(tool.icon, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withAlpha(130),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tool.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tool.gradient[0].withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: tool.gradient[0].withAlpha(40),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: tool.gradient[0].withAlpha(200),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withAlpha(60),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<String> tags;
  final VoidCallback onTap;

  _ToolItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.tags,
    required this.onTap,
  });
}
