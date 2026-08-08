import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:finway/themes/constant_colors.dart';
import 'service_category_icon.dart';
import 'service_style.dart';

class ServiceCategoryTile extends StatelessWidget {
  final String? label;
  final String? imageUrl;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDarkMode;
  final ServiceCategoryStyle? parentStyle;
  final double iconSize;

  const ServiceCategoryTile({
    super.key,
    required this.label,
    required this.onTap,
    required this.isDarkMode,
    this.imageUrl,
    this.subtitle,
    this.parentStyle,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final resolvedIconSize = hasSubtitle ? (iconSize * 0.85).clamp(44.0, iconSize) : iconSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            ServiceCategoryIcon(
              label: label,
              imageUrl: imageUrl,
              size: resolvedIconSize,
              parentStyle: parentStyle,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                cleanServiceName(label).tr,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 11,
                  height: 1.15,
                  color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                ),
              ),
            ),
            if (hasSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppThemeData.regular,
                  fontSize: 8,
                  height: 1.1,
                  color: AppThemeData.grey500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
