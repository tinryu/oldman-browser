import 'package:flutter/material.dart';

class AnimatedMovieTitle extends StatefulWidget {
  final String title;
  final Duration duration;
  final Function()? onTabRequested;
  final Function()? onIconTap;
  final IconData? icon;
  const AnimatedMovieTitle({
    super.key,
    required this.title,
    required this.duration,
    this.onTabRequested,
    this.onIconTap,
    this.icon,
  });

  @override
  State<AnimatedMovieTitle> createState() => AnimatedMovieTitleState();
}

class AnimatedMovieTitleState extends State<AnimatedMovieTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: GestureDetector(
            onTap: widget.onTabRequested,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.primary,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    0.0,
                    (_controller.value - 0.25).clamp(0.0, 1.0),
                    _controller.value,
                    (_controller.value + 0.25).clamp(0.0, 1.0),
                    1.0,
                  ],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.icon != null)
                    GestureDetector(
                      onTap: () {
                        if (widget.onIconTap != null) {
                          widget.onIconTap!();
                        }
                      },
                      child: Tooltip(
                        message: 'View All',
                        child: Icon(widget.icon, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
