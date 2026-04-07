import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/youtube_provider.dart';
import '../../widgets/yt/video_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showApiKeyField = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch(String value) {
    if (value.isNotEmpty) {
      ref.read(searchProvider.notifier).search(value);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    // Auto-hide API Key field on successful search
    if (_showApiKeyField &&
        searchState.videos.isNotEmpty &&
        !searchState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showApiKeyField) {
          setState(() => _showApiKeyField = false);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/b/b8/YouTube_Logo_2017.svg',
          height: 20,
          errorBuilder: (context, error, stackTrace) => const Text(
            'Trial Player',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showApiKeyField ? Icons.close : Icons.vpn_key_outlined,
              size: 20,
            ),
            onPressed: () {
              setState(() => _showApiKeyField = !_showApiKeyField);
            },
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_showApiKeyField)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12.0),
              color: Colors.red.withOpacity(0.05),
              child: Column(
                children: [
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      hintText: 'Enter YouTube API Key (Optional)',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.key, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () {
                          final key = _apiKeyController.text.trim();
                          ref
                              .read(customApiKeyProvider.notifier)
                              .setKey(key.isEmpty ? null : key);
                          setState(() => _showApiKeyField = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('API Key Updated')),
                          );
                        },
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Empty will use default config key',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          // Search Bar - Only show if not entering API key
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _performSearch(_searchController.text),
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                focusColor: Colors.black38,
                hoverColor: Colors.black38,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() {}),
              onSubmitted: _performSearch,
            ),
          ),

          // Results
          Expanded(
            child: searchState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  )
                : searchState.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Search Error',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchState.error ?? 'Unknown error occurred',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(searchProvider.notifier)
                                  .search(searchState.query),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : searchState.videos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'Search for your favorite videos',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(searchProvider.notifier)
                        .search(searchState.query),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          searchState.videos.length +
                          (searchState.nextPageToken.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == searchState.videos.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.red,
                              ),
                            ),
                          );
                        }
                        return VideoCard(video: searchState.videos[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
