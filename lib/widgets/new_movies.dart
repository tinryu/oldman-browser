import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:old_man_browser/screens/source_detail_screen.dart'
    show SourceDetailScreen;
import '../models/movie.dart';
import '../services/api_service.dart';

class NewMovies extends StatefulWidget {
  final Function(int) onTabRequested;
  const NewMovies({super.key, required this.onTabRequested});

  @override
  State<NewMovies> createState() => _NewMoviesState();
}

class _NewMoviesState extends State<NewMovies> {
  final _api = ApiService();
  List<Movie> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    try {
      final response = await _api.fetchMovies(page: 1, limit: 10);
      if (mounted) {
        setState(() {
          _movies = response.items.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          debugPrint(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            'Latest Movies',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _movies.length,
            itemBuilder: (context, index) {
              final movie = _movies[index];
              return _MovieListItem(
                movie: movie,
                onTabRequested: widget.onTabRequested,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MovieListItem extends StatefulWidget {
  final Movie movie;
  final Function(int) onTabRequested;

  const _MovieListItem({required this.movie, required this.onTabRequested});

  @override
  State<_MovieListItem> createState() => _MovieListItemState();
}

class _MovieListItemState extends State<_MovieListItem> {
  bool _isHovered = false;
  bool _isTouching = false;

  @override
  Widget build(BuildContext context) {
    // Base height 70, expanded height 110
    final isExpanded = _isHovered || _isTouching;
    final height = isExpanded ? 120.0 : 60.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _isTouching = true),
        onPointerUp: (_) => setState(() => _isTouching = false),
        onPointerCancel: (_) => setState(() => _isTouching = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: height,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: isExpanded ? Colors.white : Colors.redAccent,
                  blurRadius: 2.0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SourceDetailScreen(
                          movieId: widget.movie.id,
                          onTabRequested: widget.onTabRequested,
                        ),
                      ),
                    );
                    // If a tab index was returned, switch to that tab
                    if (result != null && result is int && context.mounted) {
                      widget.onTabRequested(result);
                    }
                  },
                  child: CachedNetworkImage(
                    imageUrl: widget.movie.posterUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                    color: Colors.black.withValues(alpha: 0.5),
                    colorBlendMode: BlendMode.darken,
                    progressIndicatorBuilder: (context, url, progress) =>
                        Center(
                          child: CircularProgressIndicator(
                            value: progress.progress,
                            strokeWidth: 2,
                            color: Colors.white30,
                          ),
                        ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white30),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Badge(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    backgroundColor: Colors.yellow.withValues(alpha: 0.5),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.movie.lang.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          widget.movie.type == "series"
                              ? Icons.tv_rounded
                              : Icons.movie_outlined,
                          color: Colors.black,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Badge(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: Colors.transparent,
                    label: Text(
                      widget.movie.year.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
