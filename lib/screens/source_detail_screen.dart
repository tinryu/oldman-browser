import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/episode.dart';
import '../../models/movie.dart';
import '../../services/api_service.dart';
import 'video_player_screen.dart';

class SourceDetailScreen extends StatefulWidget {
  final String movieId;
  const SourceDetailScreen({super.key, required this.movieId});

  @override
  State<SourceDetailScreen> createState() => _SourceDetailScreenState();
}

class _SourceDetailScreenState extends State<SourceDetailScreen> {
  final _api = ApiService();
  late Future<Movie> _future;
  var isExpanded = false;
  @override
  void initState() {
    super.initState();
    _future = _api.fetchMovieById(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Movie>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onBack: () => Navigator.of(context).maybePop(),
              onRetry: () =>
                  setState(() => _future = _api.fetchMovieById(widget.movieId)),
            );
          }
          final movie = snap.data;
          if (movie == null) {
            return _ErrorState(
              message: 'Movie not found.',
              onBack: () => Navigator.of(context).maybePop(),
              onRetry: () =>
                  setState(() => _future = _api.fetchMovieById(widget.movieId)),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.7),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(30),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Text(
                      movie.description,
                      maxLines: 7,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                expandedHeight: 300,
                collapsedHeight: 250,
                pinned: true,
                title: Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroPoster(url: movie.posterUrl),
                  expandedTitleScale: 1.5,
                  collapseMode: CollapseMode.parallax,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (movie.episodes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'Episodes',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy All',
                              onPressed: () => onCopyAll(movie.episodes),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cloud_download),
                              tooltip: 'Go to Online page',
                              onPressed: () {
                                // Pop and return the tab index to switch to
                                Navigator.of(context).pop(2);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _EpisodePicker(
                          movie: movie,
                          onCopy: (url, label) async {
                            await Clipboard.setData(
                              ClipboardData(text: '$label | $url'),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                closeIconColor: Colors.black,
                                showCloseIcon: true,
                                content: Text(
                                  'Copied $label | $url to clipboard',
                                ),
                              ),
                            );
                          },
                          onPlay: (url, label) {
                            showGeneralDialog(
                              barrierColor: Colors.grey.withValues(alpha: 0.6),
                              context: context,
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: VideoPlayerScreen(
                                          videoUrl: url,
                                          title: label,
                                        ),
                                      ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void onCopyAll(List<EpisodeServer> episodes) {
    final text = episodes
        .expand((server) => server.serverData)
        .map((ep) {
          final label = ep.name.trim().isEmpty
              ? (ep.slug.isEmpty ? 'Episode' : ep.slug)
              : ep.name;
          return '$label | ${ep.linkM3u8}';
        })
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        closeIconColor: Colors.black,
        showCloseIcon: true,
        content: const Text('Copied all episodes to clipboard'),
      ),
    );
  }
}

class _HeroPoster extends StatelessWidget {
  final String url;
  const _HeroPoster({required this.url});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            image: url.trim().isEmpty
                ? null
                : DecorationImage(
                    opacity: 0.5,
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      scheme.onSurface.withValues(alpha: 0.1),
                      BlendMode.darken,
                    ),
                  ),
          ),
          child: url.trim().isEmpty
              ? const Center(child: Icon(Icons.movie, size: 56))
              : null,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodePicker extends StatefulWidget {
  final Movie movie;
  final Function(String, String) onCopy;
  final Function(String, String) onPlay;
  const _EpisodePicker({
    required this.movie,
    required this.onCopy,
    required this.onPlay,
  });

  @override
  State<_EpisodePicker> createState() => _EpisodePickerState();
}

class _EpisodePickerState extends State<_EpisodePicker> {
  int _serverIndex = 0;

  @override
  Widget build(BuildContext context) {
    final servers = widget.movie.episodes;
    if (servers.isEmpty) return const SizedBox.shrink();

    _serverIndex = _serverIndex.clamp(0, servers.length - 1);
    final server = servers[_serverIndex];
    final sources = server.serverData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (servers.length > 1)
          DropdownButtonFormField<int>(
            initialValue: _serverIndex,
            decoration: const InputDecoration(
              labelText: 'Server',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var i = 0; i < servers.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    servers[i].serverName.isEmpty
                        ? 'Server ${i + 1}'
                        : servers[i].serverName,
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _serverIndex = v);
            },
          ),
        if (servers.length > 1) const SizedBox(height: 16),
        for (final ep in sources)
          _EpisodeSourceCard(
            serverName: server.serverName,
            ep: ep,
            onCopy: widget.onCopy,
            onPlay: widget.onPlay,
          ),
      ],
    );
  }
}

class _EpisodeSourceCard extends StatelessWidget {
  final String serverName;
  final EpisodeSource ep;
  final Function(String, String) onCopy;
  final Function(String, String) onPlay;

  const _EpisodeSourceCard({
    required this.serverName,
    required this.ep,
    required this.onCopy,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final label = ep.name.trim().isEmpty
        ? (ep.slug.isEmpty ? 'Episode' : ep.slug)
        : ep.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpansionTile(
            minTileHeight: 20,
            iconColor: Colors.black,
            textColor: Colors.black,
            collapsedIconColor: Colors.white,
            backgroundColor: Colors.grey.shade100,
            collapsedBackgroundColor: Colors.grey.shade800,
            title: Text(
              '$serverName | $label',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: [
              if (ep.linkM3u8.isNotEmpty)
                _LinkTile(
                  type: 'M3U8',
                  url: ep.linkM3u8,
                  onCopy: () => onCopy(ep.linkM3u8, label),
                  onPlay: () => onPlay(ep.linkM3u8, label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String type;
  final String url;
  final VoidCallback onCopy;
  final VoidCallback onPlay;

  const _LinkTile({
    required this.type,
    required this.url,
    required this.onCopy,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      textColor: Colors.black,
      dense: true,
      horizontalTitleGap: 5,
      leading: IconButton(icon: const Icon(Icons.copy), onPressed: onCopy),
      title: Text(
        type,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: Text(
        url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.play_circle_outline),
        onPressed: onPlay,
      ),
    );
  }
}
