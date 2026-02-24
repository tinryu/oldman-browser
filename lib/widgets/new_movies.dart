import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import 'animated_movie_title.dart' show AnimatedMovieTitle;
import '../screens/movie_list_screen.dart';
import 'movie_list_item.dart';

class NewMovies extends StatefulWidget {
  final Function(int)? onTabRequested;

  const NewMovies({super.key, this.onTabRequested});

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
        AnimatedMovieTitle(
          title: 'Latest Movies',
          duration: const Duration(seconds: 5),
          onTabRequested: () {},
          onIconTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieListScreen(
                  title: 'Latest Movies',
                  onTabRequested: widget.onTabRequested,
                ),
              ),
            );
          },
          icon: Icons.arrow_forward_ios_rounded,
        ),
        Expanded(
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
        ),
      ],
    );
  }
}
