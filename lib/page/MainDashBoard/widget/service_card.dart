import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const ServiceCard({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Container(
      width: double.infinity,
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppThemeData.primary200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: AppThemeData.semiBold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 9.5,
              fontFamily: AppThemeData.regular,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
