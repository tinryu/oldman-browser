import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/movie.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFocusChange;
  final bool isActive;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.onFocusChange,
    this.isActive = false,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  bool get _isShowFocus => _isFocused || _isHovered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scale up when focused for "pop" effect suitable for TV
    final scale = (widget.isActive || _isShowFocus) ? 1.05 : 0.95;
    final opacity = (widget.isActive || _isShowFocus) ? 1.0 : 0.8;

    return FocusableActionDetector(
      onFocusChange: (value) {
        setState(() {
          _isFocused = value;
        });
        widget.onFocusChange?.call(value);
      },
      onShowHoverHighlight: (value) {
        setState(() {
          _isHovered = value;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          child: AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: _isShowFocus
                    ? Border.all(color: Colors.white, width: 3)
                    : null, // Visual focus indicator
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPoster(),
                    _buildGradientOverlay(),
                    if (_isShowFocus) _buildPlayButton(),
                    _buildMovieInfo(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (widget.movie.posterUrl.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.movie, size: 64, color: Colors.white30),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.movie.posterUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Center(child: Icon(Icons.error_outline)),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildMovieInfo(ThemeData theme) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
