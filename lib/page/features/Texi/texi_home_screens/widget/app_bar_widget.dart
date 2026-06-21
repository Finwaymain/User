import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:finway/controller/home_osm_controller.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/constant/constant.dart';

class AppBarWidget extends StatelessWidget {
  final HomeOsmController controller;
  final bool isDarkMode;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const AppBarWidget({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFieldWidget(
          textColor: isDarkMode ? AppThemeData.grey800Dark : AppThemeData.grey800,
          isReadOnly: true,
          width: Constant.homeScreenType == 'OlaHome' ? 0 : 0.8,
          prefix: IconButton(
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
            icon: SvgPicture.asset(
              "assets/icons/ic_menu_fill.svg",
              colorFilter: ColorFilter.mode(
                isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                BlendMode.srcIn,
              ),
            ),
          ),
          hintText: 'Your current location'.tr,
          controller: controller.currentLocationController,
        ),
      ],
    );
  }
}