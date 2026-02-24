import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../screens/source_detail_screen.dart';

class MovieListItem extends StatefulWidget {
  final Movie movie;
  final Function(int)? onTabRequested;

  const MovieListItem({super.key, required this.movie, this.onTabRequested});

  @override
  State<MovieListItem> createState() => _MovieListItemState();
}

class _MovieListItemState extends State<MovieListItem> {
  bool _isHovered = false;
  bool _isTouching = false;

  @override
  Widget build(BuildContext context) {
    final isExpanded = _isHovered || _isTouching;
    final height = isExpanded ? 150.0 : 80.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isTouching = true),
        onTapUp: (_) => setState(() => _isTouching = false),
        onTapCancel: () => setState(() => _isTouching = false),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SourceDetailScreen(movieId: widget.movie.id),
            ),
          );
          if (result != null &&
              result is int &&
              context.mounted &&
              widget.onTabRequested != null) {
            widget.onTabRequested!(result);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.grey[900],
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? Colors.white.withAlpha(20)
                    : Colors.black.withAlpha(50),
                blurRadius: isExpanded ? 8.0 : 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.movie.posterUrl,
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
                color: Colors.black.withAlpha(isExpanded ? 100 : 150),
                colorBlendMode: BlendMode.darken,
                progressIndicatorBuilder: (context, url, progress) => Center(
                  child: CircularProgressIndicator(
                    value: progress.progress,
                    strokeWidth: 2,
                    color: Colors.white24,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white24),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                widget.movie.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (widget.movie.source != null)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.movie.source!,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildBadge(
                                widget.movie.lang.toString(),
                                Colors.yellow.withAlpha(150),
                                Colors.black,
                              ),
                              const SizedBox(width: 8),
                              _buildBadge(
                                widget.movie.year.toString(),
                                Colors.white.withAlpha(30),
                                Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                widget.movie.type == "series"
                                    ? Icons.tv_rounded
                                    : Icons.movie_outlined,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
