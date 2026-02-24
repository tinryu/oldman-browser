import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/video_item.dart';

class SelectAllButton extends StatelessWidget {
  final List<dynamic> displayItems;
  final Set<dynamic> selectedItems;
  final VoidCallback onToggleSelectAll;
  final ThemeData theme;

  const SelectAllButton({
    super.key,
    required this.displayItems,
    required this.selectedItems,
    required this.onToggleSelectAll,
    required this.theme,
  });

  bool get _isAllSelected {
    if (displayItems.isEmpty) return false;
    return displayItems.every((item) {
      if (item is VideoItem) {
        return selectedItems.any(
          (si) => si is VideoItem && si.title == item.title,
        );
      } else if (item is Directory) {
        return selectedItems.any(
          (si) => si is Directory && si.path == item.path,
        );
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (displayItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Badge(
              textColor: theme.colorScheme.onSurface,
              backgroundColor: Colors.transparent,
              label: Text(
                selectedItems.length.toString(),
                style: const TextStyle(fontSize: 15),
              ),
              offset: const Offset(12, 12),
              child: Icon(
                _isAllSelected || selectedItems.isNotEmpty
                    ? Icons.check_circle_outline_rounded
                    : Icons.circle_outlined,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            onPressed: onToggleSelectAll,
            tooltip: _isAllSelected ? 'Deselect All' : 'Select All',
          ),
        ],
      ),
    );
  }
}
