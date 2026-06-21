import 'package:flutter/material.dart';

class ColorUtils {
  static Color hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}