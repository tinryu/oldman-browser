import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import '../models/categoris.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import 'package:old_man_browser/screens/source_detail_screen.dart'
    show SourceDetailScreen;
import 'animated_movie_title.dart' show AnimatedMovieTitle;

class CategoriMovies extends StatefulWidget {
  final Function(int)? onTabRequested;

  const CategoriMovies({super.key, this.onTabRequested});

  @override
  State<CategoriMovies> createState() => _CategoriMoviesState();
}

class _CategoriMoviesState extends State<CategoriMovies> {
  final _api = ApiService();
  List<Movie> _movies = [];
  Categoris? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    try {
      final response = await _api.fetchMovieCategoryById(
        _selectedCategory!.slug,
        page: 1,
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _movies = _selectedCategory != null
              ? response.items.take(10).toList()
              : [];
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedMovieTitle(
          title: _selectedCategory?.name ?? 'Select Category',
          duration: Duration(seconds: 5),
          onTabRequested: _showCategoriesModal,
          icon: Icons.touch_app_rounded,
        ),
        _movies.isNotEmpty
            ? Expanded(
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
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  void _showCategoriesModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FutureBuilder<List<Categoris>>(
          future: _api.fetchCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No categories found')),
              );
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return ListTile(
                          leading: Icon(Icons.label_rounded, size: 20),
                          title: Text(
                            cat.name,
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                              _isLoading = true;
                            });
                            Navigator.pop(context);
                            _fetchMovies();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MovieListItem extends StatefulWidget {
  final Movie movie;
  final Function(int)? onTabRequested;

  const _MovieListItem({required this.movie, this.onTabRequested});

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
    final height = isExpanded ? 180.0 : 60.0;

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
                        builder: (context) =>
                            SourceDetailScreen(movieId: widget.movie.id),
                      ),
                    );
                    // If a tab index was returned, switch to that tab
                    if (result != null &&
                        result is int &&
                        context.mounted &&
                        widget.onTabRequested != null) {
                      widget.onTabRequested!(result);
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
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.movie.lang.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 4),
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
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.movie.year.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 200,
                        child: Text(
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
