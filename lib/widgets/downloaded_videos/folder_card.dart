import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FolderCard extends StatelessWidget {
  final Directory folder;
  final bool isSelected;
  final bool hasSelections;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ThemeData theme;

  const FolderCard({
    super.key,
    required this.folder,
    required this.isSelected,
    required this.hasSelections,
    required this.onTap,
    required this.onLongPress,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final folderName = p.basename(folder.path);

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(
                alpha: isSelected ? 0.4 : 0.2,
              ),
              theme.colorScheme.primary.withValues(
                alpha: isSelected ? 0.3 : 0.1,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/icon/icon.png'),
                      fit: BoxFit.contain,
                      opacity: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.folder_copy_rounded,
                    size: 25,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      folderName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasSelections
                          ? (isSelected ? 'Selected' : 'Tap to select')
                          : 'Tap to open',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: isSelected ? 0.8 : 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
