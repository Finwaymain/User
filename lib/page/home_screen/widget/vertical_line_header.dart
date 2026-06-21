import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class VerticalLineHeader extends StatelessWidget {
  final String text;
  final double lineHeight;
  final Color? lineColor;
  final TextStyle? textStyle;

   const VerticalLineHeader({
    super.key,
    required this.text,
    this.lineHeight = 25,
    this.lineColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: lineHeight,
          decoration: BoxDecoration(
            color: lineColor ?? AppThemeData.primary200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: textStyle ??
                TextStyle(
                  color:
                      isDark ? AppThemeData.grey50Dark : AppThemeData.grey900,
                  fontSize: 16,
                  fontFamily: AppThemeData.semiBold,
                  letterSpacing: -0.2,
                ),
          ),
        ),
      ],
    );
  }
}
