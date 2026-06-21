import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class AnimatedFeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;

  const AnimatedFeatureCard({super.key, required this.icon, required this.title});

  @override
  State<AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<AnimatedFeatureCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? AppThemeData.grey300Dark.withValues(alpha: 0.5)
                : AppThemeData.grey300.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : AppThemeData.primary200.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppThemeData.primary200.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                size: 20,
                color: AppThemeData.primary200,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontFamily: AppThemeData.medium,
                color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
