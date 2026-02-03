// Add to your search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:old_man_browser/screens/source_detail_screen.dart'
    show SourceDetailScreen;
import 'package:old_man_browser/widgets/categoris_movies.dart';
import 'package:old_man_browser/widgets/new_movies.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import '../../models/movie.dart';
import '../../services/api_service.dart';
import '../../widgets/movie_card.dart';

class SourceListScreen extends StatefulWidget {
  const SourceListScreen({super.key});

  @override
  State<SourceListScreen> createState() => _SourceListScreenState();
}

class _SourceListScreenState extends State<SourceListScreen> {
  final _api = ApiService();
  final _debouncer = Debouncer(milliseconds: 500);
  final _searchController = TextEditingController();
  final _recentSearches = <String>[];

  List<Movie> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    // Load recent searches from shared preferences
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.clear();
      _recentSearches.addAll(prefs.getStringList('recent_searches') ?? []);
    });
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _recentSearches.removeWhere(
        (q) => q.toLowerCase() == query.toLowerCase(),
      );
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _removeSearchQuery(String query) async {
    setState(() {
      _recentSearches.remove(query);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _api.fetchMovieSearchById(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      await _saveSearchQuery(query);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          _searchResults.isEmpty
              ? Expanded(
                  child: Column(
                    children: [
                      Expanded(flex: 1, child: NewMovies()),
                      Expanded(flex: 3, child: CategoriMovies()),
                    ],
                  ),
                )
              : _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          SearchBar(
            constraints: BoxConstraints(maxHeight: 40),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            ),
            controller: _searchController,
            hintText: 'Search movies...',
            leading: const Icon(Icons.search),
            trailing: _searchController.text.isNotEmpty
                ? [
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _error = null;
                        });
                      },
                    ),
                  ]
                : null,
            onChanged: (value) {
              _debouncer.run(() => _search(value));
            },
          ),

          if (_recentSearches.isNotEmpty && _searchController.text.isEmpty)
            _buildRecentSearches(),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 80),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final query = _recentSearches[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 4),
                minTileHeight: 20,
                title: Text(query, style: TextStyle(fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.clear, size: 14),
                  onPressed: () => _removeSearchQuery(query),
                ),
                onTap: () {
                  _searchController.text = query;
                  _search(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _search(_searchController.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Expanded(child: Center(child: Text('No results found')));
    }

    if (_searchResults.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Search for movies to see results')),
      );
    }
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900
        ? 5
        : width >= 700
        ? 4
        : width >= 520
        ? 3
        : 1;

    final childAspectRatio = width >= 900
        ? 9 / 16
        : width >= 700
        ? 9 / 16
        : width >= 520
        ? 9 / 16
        : 16 / 9;

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final movie = _searchResults[index];
          return MovieCard(
            movie: movie,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SourceDetailScreen(movieId: movie.id),
                ),
              );
              // If a tab index was returned, switch to that tab
              if (result != null && result is int) {
                // widget.onTabRequested(result);
              }
            },
          );
        },
      ),
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
