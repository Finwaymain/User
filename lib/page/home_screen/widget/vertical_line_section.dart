import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';
import 'vertical_line_header.dart';

class VerticalLineSection extends StatelessWidget {
  final String text;
  final double lineHeight;
  final Color? lineColor;
  final TextStyle? textStyle;
  final List<Widget> cardChildren;
  final EdgeInsetsGeometry? margin ;

  const VerticalLineSection({
    super.key,
    required this.text,
    required this.cardChildren,
    this.lineHeight = 25,
    this.lineColor,
    this.textStyle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (cardChildren.isEmpty) {
      return const SizedBox.shrink();
    }
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerticalLineHeader(
            text: text,
            lineHeight: lineHeight,
            lineColor: lineColor,
            textStyle: textStyle,
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey800 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                width: 1,
                color: isDark
                    ? AppThemeData.grey300Dark.withValues(alpha: 0.4)
                    : AppThemeData.grey300.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.1)
                      : AppThemeData.primary200.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsively calculate the number of items per row based on screen size
                const double minItemWidth = 65.0;
                const double spacing = 12.0;
                
                int maxItemsPerRow = ((constraints.maxWidth + spacing) / (minItemWidth + spacing)).floor();
                if (maxItemsPerRow < 3) maxItemsPerRow = 3;
                if (maxItemsPerRow > 5) maxItemsPerRow = 5;

                final double totalSpacing = spacing * (maxItemsPerRow - 1);
                final double itemWidth =
                    (constraints.maxWidth - totalSpacing) / maxItemsPerRow;

                final List<Widget> allChildren = [...cardChildren];

                // If last row has less than maxItemsPerRow, fill with empty boxes to align layout
                int remainder = cardChildren.length % maxItemsPerRow;
                if (remainder != 0) {
                  int fillers = maxItemsPerRow - remainder;
                  for (int i = 0; i < fillers; i++) {
                    allChildren.add(const SizedBox()); // Empty cell
                  }
                }

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: allChildren.map((child) {
                    return SizedBox(
                      width: itemWidth,
                      child: child,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
