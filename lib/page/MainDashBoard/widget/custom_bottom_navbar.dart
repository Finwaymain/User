import 'package:flutter/material.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:provider/provider.dart';

import '../../../utils/dark_theme_provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onFingerprintTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onFingerprintTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Container(
      color: Colors.transparent,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 58,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E2436)
                  : const Color(0xFFF7F8FB),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : const Color(0xFF2C5CE6).withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, 'Home', 0, isDark),
                _navItem(Icons.search_rounded, 'Search', 1, isDark),
                const SizedBox(width: 60),
                _navItem(Icons.card_travel_rounded, 'Trips', 3, isDark),
                _navItem(Icons.receipt_long_rounded, 'Activity', 4, isDark),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppThemeData.primary200,
                boxShadow: [
                  BoxShadow(
                    color: AppThemeData.primary200.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.fingerprint, color: Colors.white, size: 28),
                onPressed: onFingerprintTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, bool isDark) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? AppThemeData.primary200
                  : isDark
                      ? AppThemeData.grey500Dark
                      : AppThemeData.grey400,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontFamily: isActive ? AppThemeData.semiBold : AppThemeData.regular,
                color: isActive
                    ? AppThemeData.primary200
                    : isDark
                        ? AppThemeData.grey500Dark
                        : AppThemeData.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
