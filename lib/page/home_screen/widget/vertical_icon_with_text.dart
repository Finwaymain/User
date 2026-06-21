import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class VerticalIconWithText extends StatelessWidget {
  final IconData icon;
  final String text;
  final double iconSize;
  final double spacing;
  final Color? iconColor;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  const VerticalIconWithText({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 24,
    this.spacing = 6,
    this.iconColor,
    this.textStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppThemeData.primary200.withValues(alpha: isDark ? 0.15 : 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppThemeData.primary200,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            text,
            style: textStyle ??
                TextStyle(
                  fontSize: 10.5,
                  fontFamily: AppThemeData.medium,
                  color:
                  isDark ? AppThemeData.grey50Dark : AppThemeData.grey900,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
