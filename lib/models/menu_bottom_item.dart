import 'package:flutter/material.dart';

class MenuBottomItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onActions;

  MenuBottomItem(this.icon, this.label, this.color, this.onActions);
}
