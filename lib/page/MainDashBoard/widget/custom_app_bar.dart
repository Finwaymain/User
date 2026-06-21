import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {

  const CustomAppBar({super.key,});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();
    return AppBar(
      elevation: 0,
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu_rounded,
              color: isDarkMode ? AppThemeData.grey50Dark : AppThemeData.grey900,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: RichText(
        text: TextSpan(
          text: 'Fiin',
          style: TextStyle(
            color: isDarkMode ? AppThemeData.grey50Dark : AppThemeData.grey900,
            fontWeight: FontWeight.bold,
            fontFamily: AppThemeData.bold,
            fontSize: 22,
          ),
          children: [
            TextSpan(
              text: 'way',
              style: TextStyle(
                color: AppThemeData.primary200,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppThemeData.primary200.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: AppThemeData.primary200,
            size: 20,
          ),
        ),
      ],
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
