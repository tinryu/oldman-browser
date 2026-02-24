import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../widgets/movie_list_item.dart';

class MovieListScreen extends StatefulWidget {
  final String title;
  final String? categorySlug;
  final Function(int)? onTabRequested;

  const MovieListScreen({
    super.key,
    required this.title,
    this.categorySlug,
    this.onTabRequested,
  });

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final ApiService _api = ApiService();
  final List<Movie> _movies = [];
  bool _isLoading = false;
  bool _isMoreLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isMoreLoading &&
        _hasMore) {
      _fetchMoreMovies();
    }
  }

  Future<void> _fetchMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      MovieResponse response;
      if (widget.categorySlug != null) {
        response = await _api.fetchMovieCategoryById(
          widget.categorySlug!,
          page: 1,
          limit: 24,
        );
      } else {
        response = await _api.fetchMovies(page: 1, limit: 20);
      }

      if (mounted) {
        setState(() {
          _movies.clear();
          _movies.addAll(response.items);
          _currentPage = 1;
          _hasMore = !response.hasReachedMax;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreMovies() async {
    setState(() {
      _isMoreLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      MovieResponse response;
      if (widget.categorySlug != null) {
        response = await _api.fetchMovieCategoryById(
          widget.categorySlug!,
          page: nextPage,
          limit: 24,
        );
      } else {
        response = await _api.fetchMovies(page: nextPage, limit: 24);
      }
      if (mounted) {
        setState(() {
          _movies.addAll(response.items);
          _currentPage = nextPage;
          _hasMore = !response.hasReachedMax;
          _isMoreLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMoreLoading = false;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to load more: $e')));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchMovies, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Center(child: Text('No movies found.'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _movies.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _movies.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return MovieListItem(
          movie: _movies[index],
          onTabRequested: widget.onTabRequested,
        );
      },
    );
  }
}
