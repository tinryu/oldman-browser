import 'package:flutter/material.dart';
import '../models/categoris.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import 'animated_movie_title.dart' show AnimatedMovieTitle;
import '../screens/movie_list_screen.dart';
import 'movie_list_item.dart';

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
      if (_selectedCategory == null) {
        if (mounted) {
          setState(() {
            _movies = [];
            _isLoading = false;
          });
        }
        return;
      }
      final response = await _api.fetchMovieCategoryById(
        _selectedCategory!.slug,
        page: 1,
        limit: 10,
      );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedMovieTitle(
          title: _selectedCategory?.name ?? 'Select Category',
          duration: const Duration(seconds: 5),
          onTabRequested: _showCategoriesModal,
          onIconTap: () {
            if (_selectedCategory != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieListScreen(
                    title: _selectedCategory!.name,
                    categorySlug: _selectedCategory!.slug,
                    onTabRequested: widget.onTabRequested,
                  ),
                ),
              );
            } else {
              _showCategoriesModal();
            }
          },
          icon: _selectedCategory != null
              ? Icons.arrow_forward_ios_rounded
              : Icons.touch_app_rounded,
        ),
        _movies.isNotEmpty
            ? Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _movies.length,
                  itemBuilder: (context, index) {
                    final movie = _movies[index];
                    return MovieListItem(
                      movie: movie,
                      onTabRequested: widget.onTabRequested,
                    );
                  },
                ),
              )
            : const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No movies found\nTry Selecting another Category',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
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
                          leading: const Icon(Icons.label_rounded, size: 20),
                          title: Text(
                            cat.name,
                            style: const TextStyle(fontSize: 16),
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
